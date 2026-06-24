use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::sync::Arc;
use tokio::net::{TcpListener, TcpStream};
use tokio::sync::Mutex;
use tokio_tungstenite::{accept_async, client_async, tungstenite::Message, WebSocketStream};
use futures_util::{SinkExt, StreamExt};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WsMessage {
    pub msg_type: String,
    pub payload: String,
    pub timestamp: i64,
    pub signature: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct HandshakeMessage {
    pub msg_type: String,
    pub peer_id: String,
    pub public_key: String,
    pub timestamp: i64,
}

type WsSink = futures_util::stream::SplitSink<WebSocketStream<TcpStream>, Message>;

struct ConnectedPeer {
    peer_id: String,
    sender: WsSink,
    session_key: Option<[u8; 32]>,
    connected_at: i64,
    last_heartbeat: i64,
}

pub struct WsServer {
    port: u16,
    local_key_pair: crate::crypto::ecdh::KeyPair,
    peers: Arc<Mutex<HashMap<String, ConnectedPeer>>>,
    on_message: Arc<Mutex<Option<Box<dyn Fn(String, WsMessage) + Send + Sync>>>>,
}

impl WsServer {
    pub fn new(port: u16) -> Self {
        Self {
            port,
            local_key_pair: crate::crypto::ecdh::KeyPair::generate(),
            peers: Arc::new(Mutex::new(HashMap::new())),
            on_message: Arc::new(Mutex::new(None)),
        }
    }

    pub fn set_message_handler<F>(&self, handler: F)
    where F: Fn(String, WsMessage) + Send + Sync + 'static,
    {
        if let Ok(mut cb) = self.on_message.try_lock() {
            *cb = Some(Box::new(handler));
        }
    }

    pub fn local_public_key(&self) -> String {
        self.local_key_pair.public_key_base64()
    }

    pub async fn start(self: Arc<Self>) -> Result<(), String> {
        let addr = format!("0.0.0.0:{}", self.port);
        let listener = TcpListener::bind(&addr).await.map_err(|e| format!("Bind failed: {}", e))?;
        log::info!("WebSocket server listening on {}", addr);

        let server = self.clone();
        tokio::spawn(async move {
            loop {
                match listener.accept().await {
                    Ok((stream, addr)) => {
                        log::info!("New WebSocket connection from: {}", addr);
                        let srv = server.clone();
                        tokio::spawn(async move {
                            if let Err(e) = srv.handle_incoming(stream).await {
                                log::error!("WebSocket error: {}", e);
                            }
                        });
                    }
                    Err(e) => log::error!("Accept error: {}", e),
                }
            }
        });

        let server = self.clone();
        tokio::spawn(async move {
            let mut interval = tokio::time::interval(tokio::time::Duration::from_secs(30));
            loop {
                interval.tick().await;
                server.send_heartbeats().await;
            }
        });

        Ok(())
    }

    async fn handle_incoming(&self, stream: TcpStream) -> Result<(), String> {
        let ws_stream = accept_async(stream).await.map_err(|e| format!("WS handshake failed: {}", e))?;
        let (mut sender, mut receiver) = ws_stream.split();

        // Handshake — ждём публичный ключ пира (открытым текстом)
        let handshake_msg = match receiver.next().await {
            Some(Ok(Message::Text(text))) => {
                let msg: HandshakeMessage = serde_json::from_str(&text).map_err(|e| format!("Invalid handshake: {}", e))?;
                if msg.msg_type != "handshake" { return Err("Expected handshake".to_string()); }
                msg
            }
            _ => return Err("No handshake received".to_string()),
        };

        // Вычисляем session key через ECDH
        let session_key = self.local_key_pair.compute_shared_secret(&handshake_msg.public_key)?;
        let peer_id = handshake_msg.peer_id.clone();
        log::info!("Peer {} completed ECDH handshake", peer_id);

        // Отправляем свой публичный ключ
        let response = HandshakeMessage {
            msg_type: "handshake".to_string(),
            peer_id: "local".to_string(),
            public_key: self.local_public_key(),
            timestamp: chrono::Utc::now().timestamp(),
        };
        sender.send(Message::Text(serde_json::to_string(&response).map_err(|e| e.to_string())?.into())).await.map_err(|e| e.to_string())?;

        // Сохраняем пира
        {
            let mut peers = self.peers.lock().await;
            peers.insert(peer_id.clone(), ConnectedPeer {
                peer_id: peer_id.clone(),
                sender,
                session_key: Some(session_key),
                connected_at: chrono::Utc::now().timestamp(),
                last_heartbeat: chrono::Utc::now().timestamp(),
            });
        }

        // Читаем ЗАШИФРОВАННЫЕ сообщения (Binary)
        while let Some(msg) = receiver.next().await {
            match msg {
                Ok(Message::Binary(data)) => {
                    let decrypted = match crate::crypto::aes::decrypt(&session_key, &data) {
                        Ok(d) => d,
                        Err(e) => { log::error!("Decrypt error from {}: {}", peer_id, e); continue; }
                    };
                    let ws_msg: WsMessage = match serde_json::from_slice(&decrypted) {
                        Ok(m) => m,
                        Err(e) => { log::error!("Parse error from {}: {}", peer_id, e); continue; }
                    };
                    if ws_msg.msg_type == "heartbeat" {
                        let mut peers = self.peers.lock().await;
                        if let Some(peer) = peers.get_mut(&peer_id) { peer.last_heartbeat = chrono::Utc::now().timestamp(); }
                        continue;
                    }
                    let cb = self.on_message.lock().await;
                    if let Some(handler) = cb.as_ref() { handler(peer_id.clone(), ws_msg); }
                }
                Ok(Message::Close(_)) => { log::info!("Peer {} disconnected", peer_id); break; }
                Err(e) => { log::error!("Error from {}: {}", peer_id, e); break; }
                _ => {}
            }
        }

        self.peers.lock().await.remove(&peer_id);
        Ok(())
    }

    pub async fn connect_to_peer(&self, peer_id: &str, ip: &str, port: u16, remote_public_key: &str) -> Result<(), String> {
        let url = format!("ws://{}:{}", ip, port);
        log::info!("Connecting to peer {} at {}", peer_id, url);

        // ВАЖНО: используем client_async с TcpStream (не connect_async!)
        // чтобы получить WebSocketStream<TcpStream>, а не WebSocketStream<MaybeTlsStream<TcpStream>>
        let tcp_stream = TcpStream::connect(format!("{}:{}", ip, port)).await.map_err(|e| format!("TCP connect failed: {}", e))?;
        let (ws_stream, _) = client_async(&url, tcp_stream).await.map_err(|e| format!("WS connect failed: {}", e))?;
        let (mut sender, mut receiver) = ws_stream.split();

        // Отправляем handshake
        let handshake = HandshakeMessage {
            msg_type: "handshake".to_string(),
            peer_id: "local".to_string(),
            public_key: self.local_public_key(),
            timestamp: chrono::Utc::now().timestamp(),
        };
        sender.send(Message::Text(serde_json::to_string(&handshake).map_err(|e| e.to_string())?.into())).await.map_err(|e| e.to_string())?;

        // Ждём ответный handshake
        let _response = match receiver.next().await {
            Some(Ok(Message::Text(text))) => {
                let msg: HandshakeMessage = serde_json::from_str(&text).map_err(|e| format!("Invalid response: {}", e))?;
                if msg.msg_type != "handshake" { return Err("Expected handshake response".to_string()); }
                msg
            }
            _ => return Err("No handshake response".to_string()),
        };

        let session_key = self.local_key_pair.compute_shared_secret(remote_public_key)?;

        {
            let mut peers = self.peers.lock().await;
            peers.insert(peer_id.to_string(), ConnectedPeer {
                peer_id: peer_id.to_string(),
                sender,
                session_key: Some(session_key),
                connected_at: chrono::Utc::now().timestamp(),
                last_heartbeat: chrono::Utc::now().timestamp(),
            });
        }

        // Читаем зашифрованные сообщения в фоне
        let on_message = self.on_message.clone();
        let peers = self.peers.clone();
        let pid = peer_id.to_string();
        let key = session_key;

        tokio::spawn(async move {
            while let Some(msg) = receiver.next().await {
                match msg {
                    Ok(Message::Binary(data)) => {
                        let decrypted = match crate::crypto::aes::decrypt(&key, &data) {
                            Ok(d) => d,
                            Err(e) => { log::error!("Decrypt error from {}: {}", pid, e); continue; }
                        };
                        let ws_msg: WsMessage = match serde_json::from_slice(&decrypted) {
                            Ok(m) => m,
                            Err(e) => { log::error!("Parse error from {}: {}", pid, e); continue; }
                        };
                        if ws_msg.msg_type == "heartbeat" {
                            let mut p = peers.lock().await;
                            if let Some(peer) = p.get_mut(&pid) { peer.last_heartbeat = chrono::Utc::now().timestamp(); }
                            continue;
                        }
                        let cb = on_message.lock().await;
                        if let Some(handler) = cb.as_ref() { handler(pid.clone(), ws_msg); }
                    }
                    Ok(Message::Close(_)) => { log::info!("Peer {} closed", pid); break; }
                    Err(e) => { log::error!("Error from {}: {}", pid, e); break; }
                    _ => {}
                }
            }
            peers.lock().await.remove(&pid);
        });

        Ok(())
    }

    pub async fn send_message(&self, peer_id: &str, message: WsMessage) -> Result<(), String> {
        let mut peers = self.peers.lock().await;
        let peer = peers.get_mut(peer_id).ok_or_else(|| format!("Peer {} not connected", peer_id))?;
        let session_key = peer.session_key.ok_or_else(|| format!("Peer {} has no session key", peer_id))?;

        let json = serde_json::to_vec(&message).map_err(|e| e.to_string())?;
        let encrypted = crate::crypto::aes::encrypt(&session_key, &json)?;
        peer.sender.send(Message::Binary(encrypted.into())).await.map_err(|e| format!("Send failed: {}", e))?;
        Ok(())
    }

    pub async fn broadcast(&self, message: WsMessage) -> Result<usize, String> {
        let mut peers = self.peers.lock().await;
        let json = serde_json::to_vec(&message).map_err(|e| e.to_string())?;
        let mut sent = 0;
        for (_, peer) in peers.iter_mut() {
            if let Some(key) = peer.session_key {
                if let Ok(encrypted) = crate::crypto::aes::encrypt(&key, &json) {
                    if peer.sender.send(Message::Binary(encrypted.into())).await.is_ok() { sent += 1; }
                }
            }
        }
        Ok(sent)
    }

    async fn send_heartbeats(&self) {
        let mut peers = self.peers.lock().await;
        let now = chrono::Utc::now().timestamp();
        let mut dead_peers = Vec::new();
        for (peer_id, peer) in peers.iter_mut() {
            if now - peer.last_heartbeat > 90 { dead_peers.push(peer_id.clone()); continue; }
            if let Some(key) = peer.session_key {
                let heartbeat = WsMessage { msg_type: "heartbeat".to_string(), payload: "ping".to_string(), timestamp: now, signature: None };
                if let Ok(json) = serde_json::to_vec(&heartbeat) {
                    if let Ok(encrypted) = crate::crypto::aes::encrypt(&key, &json) {
                        let _ = peer.sender.send(Message::Binary(encrypted.into())).await;
                    }
                }
            }
        }
        for peer_id in dead_peers {
            log::warn!("Peer {} timed out", peer_id);
            peers.remove(&peer_id);
        }
    }

    pub async fn connected_peers(&self) -> Vec<String> { self.peers.lock().await.keys().cloned().collect() }
    pub async fn is_connected(&self, peer_id: &str) -> bool { self.peers.lock().await.contains_key(peer_id) }
    pub async fn disconnect_peer(&self, peer_id: &str) {
        let mut peers = self.peers.lock().await;
        if let Some(mut peer) = peers.remove(peer_id) { let _ = peer.sender.close().await; }
    }
}