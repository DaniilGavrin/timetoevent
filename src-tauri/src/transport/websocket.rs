use futures_util::{SinkExt, StreamExt};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::sync::Arc;
use tokio::net::{TcpListener, TcpStream};
use tokio::sync::Mutex;
use tokio_tungstenite::{accept_async, client_async, tungstenite::Message, WebSocketStream};

type MessageHandler = Arc<Mutex<Option<Box<dyn Fn(String, WsMessage) + Send + Sync>>>>;

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

#[allow(dead_code)]
struct ConnectedPeer {
    peer_id: String,
    sender: WsSink,
    session_key: Option<[u8; 32]>,
    connected_at: i64,
    last_heartbeat: i64,
}

/// Цель подключения — peer, к которому мы хотим быть подключены
/// Хранится в desired_connections даже при разрыве связи
struct ConnectionTarget {
    ip: String,
    port: u16,
    public_key: String,
    retry_count: u32,
    next_retry_at: i64,  // Unix timestamp, когда следующая попытка
    is_connecting: bool, // true = прямо сейчас идёт подключение
}

pub struct WsServer {
    port: u16,
    local_key_pair: crate::crypto::ecdh::KeyPair,
    /// Активные подключённые peer'ы
    peers: Arc<Mutex<HashMap<String, ConnectedPeer>>>,
    /// Желаемые подключения (для автопереподключения)
    desired_connections: Arc<Mutex<HashMap<String, ConnectionTarget>>>,
    on_message: MessageHandler,
}

impl WsServer {
    pub fn new(port: u16) -> Self {
        Self {
            port,
            local_key_pair: crate::crypto::ecdh::KeyPair::generate(),
            peers: Arc::new(Mutex::new(HashMap::new())),
            desired_connections: Arc::new(Mutex::new(HashMap::new())),
            on_message: Arc::new(Mutex::new(None)),
        }
    }

    pub fn set_message_handler<F>(&self, handler: F)
    where
        F: Fn(String, WsMessage) + Send + Sync + 'static,
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
        let listener = TcpListener::bind(&addr)
            .await
            .map_err(|e| format!("Bind failed: {}", e))?;
        log::info!("WebSocket server listening on {}", addr);

        // Сервер для входящих соединений
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

        // Heartbeat loop
        let server = self.clone();
        tokio::spawn(async move {
            let mut interval = tokio::time::interval(tokio::time::Duration::from_secs(30));
            loop {
                interval.tick().await;
                server.send_heartbeats().await;
            }
        });

        // Автопереподключение loop
        let server = self.clone();
        tokio::spawn(async move {
            let mut interval = tokio::time::interval(tokio::time::Duration::from_secs(5));
            loop {
                interval.tick().await;
                server.reconnect_loop().await;
            }
        });

        Ok(())
    }

    async fn handle_incoming(&self, stream: TcpStream) -> Result<(), String> {
        let ws_stream = accept_async(stream)
            .await
            .map_err(|e| format!("WS handshake failed: {}", e))?;
        let (mut sender, mut receiver) = ws_stream.split();

        // Handshake — ждём публичный ключ пира
        let handshake_msg = match receiver.next().await {
            Some(Ok(Message::Text(text))) => {
                let msg: HandshakeMessage =
                    serde_json::from_str(&text).map_err(|e| format!("Invalid handshake: {}", e))?;
                if msg.msg_type != "handshake" {
                    return Err("Expected handshake".to_string());
                }
                msg
            }
            _ => return Err("No handshake received".to_string()),
        };

        let session_key = self
            .local_key_pair
            .compute_shared_secret(&handshake_msg.public_key)?;
        let peer_id = handshake_msg.peer_id.clone();
        log::info!("Peer {} completed ECDH handshake (incoming)", peer_id);

        // Отправляем свой публичный ключ
        let response = HandshakeMessage {
            msg_type: "handshake".to_string(),
            peer_id: "local".to_string(),
            public_key: self.local_public_key(),
            timestamp: chrono::Utc::now().timestamp(),
        };
        sender
            .send(Message::Text(
                serde_json::to_string(&response)
                    .map_err(|e| e.to_string())?
                    .into(),
            ))
            .await
            .map_err(|e| e.to_string())?;

        // Сохраняем пира
        {
            let mut peers = self.peers.lock().await;
            peers.insert(
                peer_id.clone(),
                ConnectedPeer {
                    peer_id: peer_id.clone(),
                    sender,
                    session_key: Some(session_key),
                    connected_at: chrono::Utc::now().timestamp(),
                    last_heartbeat: chrono::Utc::now().timestamp(),
                },
            );
        }

        // Сбрасываем retry count при успешном подключении
        {
            let mut desired = self.desired_connections.lock().await;
            if let Some(target) = desired.get_mut(&peer_id) {
                target.retry_count = 0;
                target.is_connecting = false;
            }
        }

        // Читаем ЗАШИФРОВАННЫЕ сообщения (Binary)
        while let Some(msg) = receiver.next().await {
            match msg {
                Ok(Message::Binary(data)) => {
                    let decrypted = match crate::crypto::aes::decrypt(&session_key, &data) {
                        Ok(d) => d,
                        Err(e) => {
                            log::error!("Decrypt error from {}: {}", peer_id, e);
                            continue;
                        }
                    };
                    let ws_msg: WsMessage = match serde_json::from_slice(&decrypted) {
                        Ok(m) => m,
                        Err(e) => {
                            log::error!("Parse error from {}: {}", peer_id, e);
                            continue;
                        }
                    };
                    if ws_msg.msg_type == "heartbeat" {
                        let mut peers = self.peers.lock().await;
                        if let Some(peer) = peers.get_mut(&peer_id) {
                            peer.last_heartbeat = chrono::Utc::now().timestamp();
                        }
                        continue;
                    }
                    let cb = self.on_message.lock().await;
                    if let Some(handler) = cb.as_ref() {
                        handler(peer_id.clone(), ws_msg);
                    }
                }
                Ok(Message::Close(_)) => {
                    log::info!("Peer {} disconnected", peer_id);
                    break;
                }
                Err(e) => {
                    log::error!("Error from {}: {}", peer_id, e);
                    break;
                }
                _ => {}
            }
        }

        // Удаляем из активных, но НЕ из desired — reconnect loop подхватит
        self.peers.lock().await.remove(&peer_id);
        {
            let mut desired = self.desired_connections.lock().await;
            if let Some(target) = desired.get_mut(&peer_id) {
                target.is_connecting = false;
                // Устанавливаем backoff для следующей попытки
                target.retry_count += 1;
                let backoff = std::cmp::min(30, 2i64.pow(target.retry_count));
                target.next_retry_at = chrono::Utc::now().timestamp() + backoff;
                log::info!(
                    "Peer {} disconnected, will retry in {}s (attempt #{})",
                    peer_id,
                    backoff,
                    target.retry_count
                );
            }
        }
        Ok(())
    }

    /// Подключается к peer и добавляет в desired_connections для автопереподключения
    pub async fn connect_to_peer(
        &self,
        peer_id: &str,
        ip: &str,
        port: u16,
        remote_public_key: &str,
    ) -> Result<(), String> {
        let url = format!("ws://{}:{}", ip, port);
        log::info!("Connecting to peer {} at {}", peer_id, url);

        // Добавляем в desired_connections (если ещё нет)
        {
            let mut desired = self.desired_connections.lock().await;
            if !desired.contains_key(peer_id) {
                desired.insert(
                    peer_id.to_string(),
                    ConnectionTarget {
                        ip: ip.to_string(),
                        port,
                        public_key: remote_public_key.to_string(),
                        retry_count: 0,
                        next_retry_at: chrono::Utc::now().timestamp(),
                        is_connecting: true,
                    },
                );
            } else {
                // Обновляем существующую запись
                if let Some(target) = desired.get_mut(peer_id) {
                    target.ip = ip.to_string();
                    target.port = port;
                    target.public_key = remote_public_key.to_string();
                    target.is_connecting = true;
                }
            }
        }

        // Пытаемся подключиться
        match self.do_connect(peer_id, ip, port, remote_public_key).await {
            Ok(_) => {
                // Успех — сбрасываем retry count
                let mut desired = self.desired_connections.lock().await;
                if let Some(target) = desired.get_mut(peer_id) {
                    target.retry_count = 0;
                    target.is_connecting = false;
                }
                Ok(())
            }
            Err(e) => {
                // Неудача — устанавливаем backoff
                let mut desired = self.desired_connections.lock().await;
                if let Some(target) = desired.get_mut(peer_id) {
                    target.is_connecting = false;
                    target.retry_count += 1;
                    let backoff = std::cmp::min(30, 2i64.pow(target.retry_count));
                    target.next_retry_at = chrono::Utc::now().timestamp() + backoff;
                    log::warn!(
                        "Failed to connect to peer {}: {}. Will retry in {}s (attempt #{})",
                        peer_id,
                        e,
                        backoff,
                        target.retry_count
                    );
                }
                Err(e)
            }
        }
    }

    /// Внутренняя функция подключения (без изменения desired_connections)
    async fn do_connect(
        &self,
        peer_id: &str,
        ip: &str,
        port: u16,
        remote_public_key: &str,
    ) -> Result<(), String> {
        let url = format!("ws://{}:{}", ip, port);
        let tcp_stream = TcpStream::connect(format!("{}:{}", ip, port))
            .await
            .map_err(|e| format!("TCP connect failed: {}", e))?;
        let (ws_stream, _) = client_async(&url, tcp_stream)
            .await
            .map_err(|e| format!("WS connect failed: {}", e))?;
        let (mut sender, mut receiver) = ws_stream.split();

        // Handshake
        let handshake = HandshakeMessage {
            msg_type: "handshake".to_string(),
            peer_id: "local".to_string(),
            public_key: self.local_public_key(),
            timestamp: chrono::Utc::now().timestamp(),
        };
        sender
            .send(Message::Text(
                serde_json::to_string(&handshake)
                    .map_err(|e| e.to_string())?
                    .into(),
            ))
            .await
            .map_err(|e| e.to_string())?;

        // Ждём ответный handshake
        let _response = match receiver.next().await {
            Some(Ok(Message::Text(text))) => {
                let msg: HandshakeMessage =
                    serde_json::from_str(&text).map_err(|e| format!("Invalid response: {}", e))?;
                if msg.msg_type != "handshake" {
                    return Err("Expected handshake response".to_string());
                }
                msg
            }
            _ => return Err("No handshake response".to_string()),
        };

        let session_key = self
            .local_key_pair
            .compute_shared_secret(remote_public_key)?;

        // Сохраняем пира
        {
            let mut peers = self.peers.lock().await;
            peers.insert(
                peer_id.to_string(),
                ConnectedPeer {
                    peer_id: peer_id.to_string(),
                    sender,
                    session_key: Some(session_key),
                    connected_at: chrono::Utc::now().timestamp(),
                    last_heartbeat: chrono::Utc::now().timestamp(),
                },
            );
        }

        // Фоновая задача для чтения сообщений
        let on_message = self.on_message.clone();
        let peers = self.peers.clone();
        let desired = self.desired_connections.clone();
        let pid = peer_id.to_string();
        let key = session_key;

        tokio::spawn(async move {
            while let Some(msg) = receiver.next().await {
                match msg {
                    Ok(Message::Binary(data)) => {
                        let decrypted = match crate::crypto::aes::decrypt(&key, &data) {
                            Ok(d) => d,
                            Err(e) => {
                                log::error!("Decrypt error from {}: {}", pid, e);
                                continue;
                            }
                        };
                        let ws_msg: WsMessage = match serde_json::from_slice(&decrypted) {
                            Ok(m) => m,
                            Err(e) => {
                                log::error!("Parse error from {}: {}", pid, e);
                                continue;
                            }
                        };
                        if ws_msg.msg_type == "heartbeat" {
                            let mut p = peers.lock().await;
                            if let Some(peer) = p.get_mut(&pid) {
                                peer.last_heartbeat = chrono::Utc::now().timestamp();
                            }
                            continue;
                        }
                        let cb = on_message.lock().await;
                        if let Some(handler) = cb.as_ref() {
                            handler(pid.clone(), ws_msg);
                        }
                    }
                    Ok(Message::Close(_)) => {
                        log::info!("Peer {} closed", pid);
                        break;
                    }
                    Err(e) => {
                        log::error!("Error from {}: {}", pid, e);
                        break;
                    }
                    _ => {}
                }
            }

            // При разрыве — удаляем из активных, но НЕ из desired
            peers.lock().await.remove(&pid);
            let mut d = desired.lock().await;
            if let Some(target) = d.get_mut(&pid) {
                target.is_connecting = false;
                target.retry_count += 1;
                let backoff = std::cmp::min(30, 2i64.pow(target.retry_count));
                target.next_retry_at = chrono::Utc::now().timestamp() + backoff;
                log::info!(
                    "Peer {} disconnected, will retry in {}s (attempt #{})",
                    pid,
                    backoff,
                    target.retry_count
                );
            }
        });

        Ok(())
    }

    /// Фоновый loop автопереподключения
    async fn reconnect_loop(&self) {
        let now = chrono::Utc::now().timestamp();

        // Собираем peer'ов, которых нужно переподключить
        let to_reconnect: Vec<(String, String, u16, String)> = {
            let desired = self.desired_connections.lock().await;
            let peers = self.peers.lock().await;

            desired
                .iter()
                .filter(|(peer_id, target)| {
                    // Переподключаем если:
                    // 1. Peer не в активных
                    // 2. Не идёт подключение прямо сейчас
                    // 3. Время следующей попытки наступило
                    !peers.contains_key(peer_id.as_str())
                        && !target.is_connecting
                        && target.next_retry_at <= now
                })
                .map(|(peer_id, target)| {
                    (
                        peer_id.clone(),
                        target.ip.clone(),
                        target.port,
                        target.public_key.clone(),
                    )
                })
                .collect()
        };

        // Пытаемся переподключиться
        for (peer_id, ip, port, public_key) in to_reconnect {
            log::info!("Auto-reconnecting to peer {} at {}:{}", peer_id, ip, port);

            // Помечаем как "идёт подключение"
            {
                let mut desired = self.desired_connections.lock().await;
                if let Some(target) = desired.get_mut(&peer_id) {
                    target.is_connecting = true;
                }
            }

            match self.do_connect(&peer_id, &ip, port, &public_key).await {
                Ok(_) => {
                    log::info!("Auto-reconnect to peer {} succeeded", peer_id);
                    let mut desired = self.desired_connections.lock().await;
                    if let Some(target) = desired.get_mut(&peer_id) {
                        target.retry_count = 0;
                        target.is_connecting = false;
                    }
                }
                Err(e) => {
                    log::warn!("Auto-reconnect to peer {} failed: {}", peer_id, e);
                    let mut desired = self.desired_connections.lock().await;
                    if let Some(target) = desired.get_mut(&peer_id) {
                        target.is_connecting = false;
                        target.retry_count += 1;
                        let backoff = std::cmp::min(30, 2i64.pow(target.retry_count));
                        target.next_retry_at = chrono::Utc::now().timestamp() + backoff;
                    }
                }
            }
        }
    }

    pub async fn send_message(&self, peer_id: &str, message: WsMessage) -> Result<(), String> {
        let mut peers = self.peers.lock().await;
        let peer = peers
            .get_mut(peer_id)
            .ok_or_else(|| format!("Peer {} not connected", peer_id))?;
        let session_key = peer
            .session_key
            .ok_or_else(|| format!("Peer {} has no session key", peer_id))?;
        let json = serde_json::to_vec(&message).map_err(|e| e.to_string())?;
        let encrypted = crate::crypto::aes::encrypt(&session_key, &json)?;
        peer.sender
            .send(Message::Binary(encrypted.into()))
            .await
            .map_err(|e| format!("Send failed: {}", e))?;
        Ok(())
    }

    pub async fn broadcast(&self, message: WsMessage) -> Result<usize, String> {
        let mut peers = self.peers.lock().await;
        let json = serde_json::to_vec(&message).map_err(|e| e.to_string())?;
        let mut sent = 0;
        for (_, peer) in peers.iter_mut() {
            if let Some(key) = peer.session_key {
                if let Ok(encrypted) = crate::crypto::aes::encrypt(&key, &json) {
                    if peer
                        .sender
                        .send(Message::Binary(encrypted.into()))
                        .await
                        .is_ok()
                    {
                        sent += 1;
                    }
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
            if now - peer.last_heartbeat > 90 {
                dead_peers.push(peer_id.clone());
                continue;
            }
            if let Some(key) = peer.session_key {
                let heartbeat = WsMessage {
                    msg_type: "heartbeat".to_string(),
                    payload: "ping".to_string(),
                    timestamp: now,
                    signature: None,
                };
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
            // При timeout тоже помечаем для переподключения
            let mut desired = self.desired_connections.lock().await;
            if let Some(target) = desired.get_mut(&peer_id) {
                target.is_connecting = false;
                target.retry_count += 1;
                let backoff = std::cmp::min(30, 2i64.pow(target.retry_count));
                target.next_retry_at = chrono::Utc::now().timestamp() + backoff;
            }
        }
    }

    pub async fn connected_peers(&self) -> Vec<String> {
        self.peers.lock().await.keys().cloned().collect()
    }
    
    #[allow(dead_code)]
    pub async fn is_connected(&self, peer_id: &str) -> bool {
        self.peers.lock().await.contains_key(peer_id)
    }

    /// Отключает peer И удаляет из desired_connections (не будет переподключаться)
    pub async fn disconnect_peer(&self, peer_id: &str) {
        // Удаляем из активных
        let mut peers = self.peers.lock().await;
        if let Some(mut peer) = peers.remove(peer_id) {
            let _ = peer.sender.close().await;
        }
        drop(peers);

        // Удаляем из desired — пользователь сам отключил
        let mut desired = self.desired_connections.lock().await;
        desired.remove(peer_id);
    }

    #[allow(dead_code)]
    /// Возвращает список peer'ов, к которым мы хотим быть подключены (для UI)
    pub async fn desired_connections(&self) -> Vec<String> {
        self.desired_connections
            .lock()
            .await
            .keys()
            .cloned()
            .collect()
    }
}
