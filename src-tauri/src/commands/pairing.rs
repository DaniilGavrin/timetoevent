use rusqlite::params;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::sync::Mutex;
use tauri::State;
use uuid::Uuid;
use crate::crypto::{aes, codes, ecdh};
use crate::db::Database;
use crate::models::Peer;

pub struct PairingManager {
    pub sessions: Mutex<HashMap<String, PairingSession>>,
}

impl Default for PairingManager {
    fn default() -> Self { Self::new() }
}

impl PairingManager {
    pub fn new() -> Self {
        Self { sessions: Mutex::new(HashMap::new()) }
    }
}

pub struct ActiveConnections {
    connections: Mutex<HashMap<String, ConnectionInfo>>,
}

impl Default for ActiveConnections {
    fn default() -> Self { Self::new() }
}

impl ActiveConnections {
    pub fn new() -> Self {
        Self { connections: Mutex::new(HashMap::new()) }
    }
    pub fn get_session_key(&self, peer_id: &str) -> Option<[u8; 32]> {
        self.connections.lock().ok().and_then(|c| c.get(peer_id).map(|c| c.session_key))
    }
    pub fn is_connected(&self, peer_id: &str) -> bool {
        self.connections.lock().map(|c| c.contains_key(peer_id)).unwrap_or(false)
    }
    pub fn remove(&self, peer_id: &str) {
        if let Ok(mut c) = self.connections.lock() { c.remove(peer_id); }
    }
    pub fn insert(&self, peer_id: String, session_key: [u8; 32]) {
        if let Ok(mut c) = self.connections.lock() {
            c.insert(peer_id, ConnectionInfo { session_key, connected_at: chrono::Utc::now().timestamp() });
        }
    }
}

struct PairingSession {
    peer_id: String,
    session_key: [u8; 32],
    expected_hmac: String,
    attempts: i32,
    blocked_until: Option<i64>,
}

struct ConnectionInfo {
    session_key: [u8; 32],
    connected_at: i64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PairingRequest {
    pub peer_name: String,
    pub public_key: String,
    pub device_info: Option<String>,
}

#[derive(Debug, Serialize)]
pub struct PairingResponse {
    pub peer_id: String,
    pub code: String,
    pub local_public_key: String,
}

#[derive(Debug, Serialize)]
pub struct PairingStatus {
    pub peer_id: String,
    pub peer_name: String,
    pub is_verified: bool,
    pub attempts: i32,
    pub blocked_for_seconds: Option<i64>,
}

#[tauri::command]
pub async fn start_pairing(
    db: State<'_, Database>,
    manager: State<'_, PairingManager>,
    request: PairingRequest,
) -> Result<PairingResponse, String> {
    let now = chrono::Utc::now().timestamp();
    let peer_id = Uuid::new_v4().to_string();
    let key_pair = ecdh::KeyPair::generate();
    let local_public_key = key_pair.public_key_base64();
    let shared_secret = key_pair.compute_shared_secret(&request.public_key)?;
    let info = format!("timetoevent-pairing-v1-{}", peer_id);
    let session_key = aes::derive_key(&shared_secret, info.as_bytes());
    let code = codes::generate_code();
    let expected_hmac = codes::compute_hmac(&session_key, &code);

    let peer_id_clone = peer_id.clone();
    let req_clone = request.clone();
    db.run(move |conn| {
        conn.execute(
            "INSERT INTO peers (id, name, public_key, last_seen, is_trusted, created_at)
             VALUES (?1, ?2, ?3, NULL, 0, ?4)",
            params![peer_id_clone, req_clone.peer_name, req_clone.public_key, now],
        )
        .map_err(|e| format!("Failed to insert peer: {}", e))
    })
    .await?;

    let session = PairingSession {
        peer_id: peer_id.clone(),
        session_key,
        expected_hmac,
        attempts: 0,
        blocked_until: None,
    };
    manager
        .sessions
        .lock()
        .map_err(|_| "Failed to lock sessions")?
        .insert(peer_id.clone(), session);

    log::info!("Pairing started for peer: {}", peer_id);
    Ok(PairingResponse { peer_id, code, local_public_key })
}

#[tauri::command]
pub async fn verify_pairing_code(
    db: State<'_, Database>,
    manager: State<'_, PairingManager>,
    connections: State<'_, ActiveConnections>,
    peer_id: String,
    code: String,
) -> Result<bool, String> {
    let now = chrono::Utc::now().timestamp();
    
    // Сначала проверяем сессию БЕЗ await
    let (session_key, peer_id_clone, _should_block) = {
        let mut sessions = manager.sessions.lock().map_err(|_| "Failed to lock sessions")?;
        let session = sessions
            .get_mut(&peer_id)
            .ok_or_else(|| "Pairing session not found.".to_string())?;

        // Проверяем блокировку
        if let Some(blocked_until) = session.blocked_until {
            if now < blocked_until {
                return Err(format!(
                    "Too many attempts. Try again in {} seconds",
                    blocked_until - now
                ));
            } else {
                session.attempts = 0;
                session.blocked_until = None;
            }
        }

        // Проверяем формат кода
        if !codes::is_valid_code(&code) {
            return Err("Invalid code format. Must be 6 digits.".to_string());
        }

        // Вычисляем HMAC и сравниваем
        if codes::verify_hmac(&session.session_key, &code, &session.expected_hmac) {
            // УСПЕХ
            let session_key = session.session_key;
            let peer_id_clone = session.peer_id.clone();
            sessions.remove(&peer_id);
            (session_key, peer_id_clone, false)
        } else {
            // НЕУДАЧА
            session.attempts += 1;
            if session.attempts >= 3 {
                session.blocked_until = Some(now + 30);
                return Err("Too many failed attempts. Blocked for 30 seconds".to_string());
            } else {
                return Err(format!(
                    "Invalid code. {} attempts remaining",
                    3 - session.attempts
                ));
            }
        }
    }; // MutexGuard освобождается здесь, ПЕРЕД await

    // Теперь можем делать await
    let peer_id_for_db = peer_id_clone.clone();
    db.run(move |conn| {
        conn.execute(
            "UPDATE peers SET is_trusted = 1, last_seen = ?1 WHERE id = ?2",
            params![now, peer_id_for_db],
        )
        .map_err(|e| format!("Failed to update peer: {}", e))
        .map(|_| ())
    })
    .await?;

    connections.insert(peer_id_clone.clone(), session_key);
    log::info!("Pairing verified successfully for peer: {}", peer_id_clone);
    Ok(true)
}

#[tauri::command]
pub async fn cancel_pairing(
    db: State<'_, Database>,
    manager: State<'_, PairingManager>,
    peer_id: String,
) -> Result<(), String> {
    if let Ok(mut sessions) = manager.sessions.lock() {
        sessions.remove(&peer_id);
    }
    db.run(move |conn| {
    conn.execute("DELETE FROM peers WHERE id = ?1 AND is_trusted = 0", params![peer_id])
        .map_err(|e| e.to_string())
        .map(|_| ())
    })
    .await
}

#[tauri::command]
pub async fn get_pairing_status(
    db: State<'_, Database>,
    manager: State<'_, PairingManager>,
) -> Result<Vec<PairingStatus>, String> {
    // Сначала собираем данные из sessions БЕЗ await
    let session_data: Vec<(String, i32, Option<i64>)> = {
        let sessions = manager
            .sessions
            .lock()
            .map_err(|_| "Failed to lock sessions")?;
        
        let now = chrono::Utc::now().timestamp();
        sessions
            .values()
            .map(|s| {
                let blocked_for = s.blocked_until.map(|t| (t - now).max(0));
                (s.peer_id.clone(), s.attempts, blocked_for)
            })
            .collect()
    }; // MutexGuard освобождается здесь, ПЕРЕД await

    // Теперь можем делать await
    let mut statuses = Vec::new();
    for (peer_id, attempts, blocked_for) in session_data {
        let pid = peer_id.clone();
        let peer_name = db
            .run(move |conn| {
                Ok(conn.query_row(
                    "SELECT name FROM peers WHERE id = ?1",
                    rusqlite::params![pid],
                    |row| row.get::<_, String>(0),
                )
                .unwrap_or_else(|_| String::from("Unknown")))
            })
            .await
            .unwrap_or_else(|_| String::from("Unknown"));

        statuses.push(PairingStatus {
            peer_id,
            peer_name,
            is_verified: false,
            attempts,
            blocked_for_seconds: blocked_for,
        });
    }
    Ok(statuses)
}

#[tauri::command]
pub async fn get_paired_devices(db: State<'_, Database>) -> Result<Vec<Peer>, String> {
    db.run(|conn| {
        let mut stmt = conn
            .prepare(
                "SELECT id, name, public_key, last_seen, is_trusted, created_at
                 FROM peers WHERE is_trusted = 1 ORDER BY last_seen DESC",
            )
            .map_err(|e| e.to_string())?;
        let peers = stmt
            .query_map([], |row| {
                Ok(Peer {
                    id: row.get(0)?,
                    name: row.get(1)?,
                    public_key: row.get(2)?,
                    last_seen: row.get(3)?,
                    is_trusted: row.get::<_, i32>(4)? != 0,
                    created_at: row.get(5)?,
                })
            })
            .map_err(|e| e.to_string())?
            .collect::<Result<Vec<_>, _>>()
            .map_err(|e| e.to_string())?;
        Ok(peers)
    })
    .await
}

#[tauri::command]
pub async fn remove_peer(
    db: State<'_, Database>,
    connections: State<'_, ActiveConnections>,
    peer_id: String,
) -> Result<(), String> {
    connections.remove(&peer_id);
    db.run(move |conn| {
        conn.execute("DELETE FROM peers WHERE id = ?1", params![peer_id])
            .map_err(|e| e.to_string())
            .map(|_| ())
    })
    .await
}

#[tauri::command]
pub async fn update_peer_last_seen(db: State<'_, Database>, peer_id: String) -> Result<(), String> {
    db.run(move |conn| {
        let now = chrono::Utc::now().timestamp();
        conn.execute("UPDATE peers SET last_seen = ?1 WHERE id = ?2", params![now, peer_id])
            .map_err(|e| e.to_string())
            .map(|_| ())
    })
    .await
}

#[tauri::command]
pub fn is_peer_connected(connections: State<'_, ActiveConnections>, peer_id: String) -> bool {
    connections.is_connected(&peer_id)
}

#[tauri::command]
pub fn disconnect_peer(connections: State<'_, ActiveConnections>, peer_id: String) {
    connections.remove(&peer_id);
}