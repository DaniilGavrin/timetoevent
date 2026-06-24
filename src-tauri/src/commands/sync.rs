use rusqlite::{params, Connection};
use serde::{Deserialize, Serialize};
use tauri::State;
use crate::db::Database;
use crate::models::{Event, Reminder};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SyncChange {
    pub entity_type: String,
    pub entity_id: String,
    pub action: String,
    pub timestamp: i64,
    pub data: Option<serde_json::Value>,
}

#[derive(Debug, Serialize)]
pub struct SyncStatus {
    pub pending_changes: i64,
    pub last_sync: Option<i64>,
    pub total_synced: i64,
    pub total_conflicts: i64,
}

#[derive(Debug, Serialize)]
pub struct DeltaResponse {
    pub changes: Vec<SyncChange>,
    pub generated_at: i64,
    pub device_id: String,
}

#[derive(Debug, Serialize)]
pub struct ApplyResult {
    pub status: String,
    pub entity_id: String,
    pub message: Option<String>,
}

#[derive(Debug, Serialize)]
pub struct BatchApplyResult {
    pub applied: i64,
    pub skipped: i64,
    pub errors: i64,
    pub results: Vec<ApplyResult>,
}

#[tauri::command]
pub async fn get_sync_status(db: State<'_, Database>) -> Result<SyncStatus, String> {
    db.run(|conn| {
        let pending: i64 = conn.query_row("SELECT COUNT(*) FROM sync_log WHERE synced = 0", [], |row| row.get(0)).map_err(|e| e.to_string())?;
        let last_sync: Option<i64> = conn.query_row("SELECT MAX(timestamp) FROM sync_log WHERE synced = 1", [], |row| row.get(0)).unwrap_or(None);
        let total_synced: i64 = conn.query_row("SELECT COUNT(*) FROM sync_log WHERE synced = 1", [], |row| row.get(0)).map_err(|e| e.to_string())?;
        let total_conflicts: i64 = conn.query_row("SELECT COUNT(*) FROM sync_log WHERE action = 'conflict'", [], |row| row.get(0)).unwrap_or(0);
        Ok(SyncStatus { pending_changes: pending, last_sync, total_synced, total_conflicts })
    }).await
}

#[tauri::command]
pub async fn get_pending_changes(db: State<'_, Database>) -> Result<DeltaResponse, String> {
    // Получаем стабильный device_id из БД (не hostname!)
    let device_id = db.get_or_create_device_id().await?;
    
    let (changes, generated_at) = db.run(|conn| {
        let now = chrono::Utc::now().timestamp();
        let mut stmt = conn.prepare(
            "SELECT entity_type, entity_id, action, timestamp FROM sync_log WHERE synced = 0 ORDER BY timestamp ASC",
        ).map_err(|e| e.to_string())?;
        let mut changes = Vec::new();
        let rows = stmt.query_map([], |row| {
            Ok((row.get::<_, String>(0)?, row.get::<_, String>(1)?, row.get::<_, String>(2)?, row.get::<_, i64>(3)?))
        }).map_err(|e| e.to_string())?;
        for row in rows {
            let (entity_type, entity_id, action, timestamp) = row.map_err(|e| e.to_string())?;
            let data = if action != "delete" {
                match entity_type.as_str() {
                    "event" => get_event_json(conn, &entity_id)?,
                    "reminder" => get_reminder_json(conn, &entity_id)?,
                    _ => None,
                }
            } else { None };
            changes.push(SyncChange { entity_type, entity_id: entity_id.to_string(), action, timestamp, data });
        }
        Ok((changes, now))
    }).await?;
    
    Ok(DeltaResponse { changes, generated_at, device_id })
}

#[tauri::command]
pub async fn mark_as_synced(db: State<'_, Database>, timestamp: i64) -> Result<i64, String> {
    db.run(move |conn| {
        let updated = conn.execute("UPDATE sync_log SET synced = 1 WHERE timestamp <= ?1 AND synced = 0", params![timestamp]).map_err(|e| e.to_string())?;
        Ok(updated as i64)
    }).await
}

#[tauri::command]
pub async fn apply_remote_change(db: State<'_, Database>, change: SyncChange) -> Result<ApplyResult, String> {
    db.run(move |conn| apply_change_internal(conn, change)).await
}

#[tauri::command]
pub async fn apply_remote_batch(db: State<'_, Database>, changes: Vec<SyncChange>) -> Result<BatchApplyResult, String> {
    db.run(move |conn| {
        let mut applied = 0i64;
        let mut skipped = 0i64;
        let mut errors = 0i64;
        let mut results = Vec::new();
        conn.execute_batch("BEGIN TRANSACTION").map_err(|e| e.to_string())?;
        for change in changes {
            let entity_id = change.entity_id.clone();
            match apply_change_internal(conn, change) {
                Ok(result) => {
                    match result.status.as_str() {
                        "applied" => applied += 1,
                        "skipped_conflict" => skipped += 1,
                        _ => errors += 1,
                    }
                    results.push(result);
                }
                Err(e) => {
                    errors += 1;
                    results.push(ApplyResult { status: "error".to_string(), entity_id, message: Some(e) });
                }
            }
        }
        conn.execute_batch("COMMIT").map_err(|e| e.to_string())?;
        Ok(BatchApplyResult { applied, skipped, errors, results })
    }).await
}

#[tauri::command]
pub async fn cleanup_old_sync_logs(db: State<'_, Database>, days: i64) -> Result<i64, String> {
    db.run(move |conn| {
        let cutoff = chrono::Utc::now().timestamp() - (days * 86400);
        let deleted = conn.execute("DELETE FROM sync_log WHERE timestamp < ?1 AND synced = 1", params![cutoff]).map_err(|e| e.to_string())?;
        Ok(deleted as i64)
    }).await
}

#[tauri::command]
pub async fn force_sync_all(db: State<'_, Database>) -> Result<(), String> {
    db.run(|conn| {
        conn.execute("UPDATE sync_log SET synced = 0 WHERE synced = 1", []).map_err(|e| e.to_string())?;
        Ok(())
    }).await
}

fn apply_change_internal(conn: &Connection, change: SyncChange) -> Result<ApplyResult, String> {
    let now = chrono::Utc::now().timestamp();
    let local_timestamp: Option<i64> = conn.query_row(
        "SELECT MAX(timestamp) FROM sync_log WHERE entity_type = ?1 AND entity_id = ?2 AND action != 'conflict'",
        params![change.entity_type, change.entity_id], |row| row.get(0),
    ).unwrap_or(None);

    if let Some(local_ts) = local_timestamp {
        if local_ts > change.timestamp {
            conn.execute(
                "INSERT INTO sync_log (entity_type, entity_id, action, timestamp, synced) VALUES (?1, ?2, 'conflict', ?3, 0)",
                params![change.entity_type, change.entity_id, now],
            ).map_err(|e| e.to_string())?;
            return Ok(ApplyResult {
                status: "skipped_conflict".to_string(),
                entity_id: change.entity_id,
                message: Some(format!("Local version is newer ({} vs {})", local_ts, change.timestamp)),
            });
        }
    }

    match change.entity_type.as_str() {
        "event" => apply_event_change(conn, &change)?,
        "reminder" => apply_reminder_change(conn, &change)?,
        other => return Err(format!("Unknown entity type: {}", other)),
    }

    conn.execute(
        "INSERT INTO sync_log (entity_type, entity_id, action, timestamp, synced) VALUES (?1, ?2, ?3, ?4, 1)",
        params![change.entity_type, change.entity_id, change.action, change.timestamp],
    ).map_err(|e| e.to_string())?;

    Ok(ApplyResult { status: "applied".to_string(), entity_id: change.entity_id, message: None })
}

fn apply_event_change(conn: &Connection, change: &SyncChange) -> Result<(), String> {
    match change.action.as_str() {
        "create" | "update" => {
            let data = change.data.as_ref().ok_or_else(|| "Missing data".to_string())?;
            let event: Event = serde_json::from_value(data.clone()).map_err(|e| e.to_string())?;
            conn.execute(
                "INSERT OR REPLACE INTO events (id, title, description, event_date, event_type, category, color, is_favorite, is_archived, created_at, updated_at)
                 VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11)",
                params![event.id, event.title, event.description, event.event_date, event.event_type, event.category, event.color, event.is_favorite as i32, event.is_archived as i32, event.created_at, event.updated_at],
            ).map_err(|e| e.to_string())?;
        }
        "delete" => {
            conn.execute("DELETE FROM events WHERE id = ?1", params![change.entity_id]).map_err(|e| e.to_string())?;
        }
        other => return Err(format!("Unknown action: {}", other)),
    }
    Ok(())
}

fn apply_reminder_change(conn: &Connection, change: &SyncChange) -> Result<(), String> {
    match change.action.as_str() {
        "create" | "update" => {
            let data = change.data.as_ref().ok_or_else(|| "Missing data".to_string())?;
            let reminder: Reminder = serde_json::from_value(data.clone()).map_err(|e| e.to_string())?;
            conn.execute(
                "INSERT OR REPLACE INTO reminders (id, event_id, remind_at, message, is_sent, created_at) VALUES (?1, ?2, ?3, ?4, ?5, ?6)",
                params![reminder.id, reminder.event_id, reminder.remind_at, reminder.message, reminder.is_sent as i32, reminder.created_at],
            ).map_err(|e| e.to_string())?;
        }
        "delete" => {
            conn.execute("DELETE FROM reminders WHERE id = ?1", params![change.entity_id]).map_err(|e| e.to_string())?;
        }
        other => return Err(format!("Unknown action: {}", other)),
    }
    Ok(())
}

fn get_event_json(conn: &Connection, event_id: &str) -> Result<Option<serde_json::Value>, String> {
    let result = conn.query_row(
        "SELECT id, title, description, event_date, event_type, category, color, is_favorite, is_archived, created_at, updated_at FROM events WHERE id = ?1",
        params![event_id],
        |row| Ok(Event {
            id: row.get(0)?, title: row.get(1)?, description: row.get(2)?, event_date: row.get(3)?,
            event_type: row.get(4)?, category: row.get(5)?, color: row.get(6)?,
            is_favorite: row.get::<_, i32>(7)? != 0, is_archived: row.get::<_, i32>(8)? != 0,
            created_at: row.get(9)?, updated_at: row.get(10)?,
        }),
    );
    match result {
        Ok(event) => Ok(Some(serde_json::to_value(&event).map_err(|e| e.to_string())?)),
        Err(rusqlite::Error::QueryReturnedNoRows) => Ok(None),
        Err(e) => Err(e.to_string()),
    }
}

fn get_reminder_json(conn: &Connection, reminder_id: &str) -> Result<Option<serde_json::Value>, String> {
    let result = conn.query_row(
        "SELECT id, event_id, remind_at, message, is_sent, created_at FROM reminders WHERE id = ?1",
        params![reminder_id],
        |row| Ok(Reminder {
            id: row.get(0)?, event_id: row.get(1)?, remind_at: row.get(2)?,
            message: row.get(3)?, is_sent: row.get::<_, i32>(4)? != 0, created_at: row.get(5)?,
        }),
    );
    match result {
        Ok(reminder) => Ok(Some(serde_json::to_value(&reminder).map_err(|e| e.to_string())?)),
        Err(rusqlite::Error::QueryReturnedNoRows) => Ok(None),
        Err(e) => Err(e.to_string()),
    }
}

/// Подключается к peer через WebSocket
#[tauri::command]
pub async fn connect_to_peer(
    ws: State<'_, crate::transport::WsServer>,
    peer_id: String,
    ip: String,
    port: u16,
    public_key: String,
) -> Result<(), String> {
    ws.connect_to_peer(&peer_id, &ip, port, &public_key).await
}

/// Отправляет зашифрованное сообщение peer
#[tauri::command]
pub async fn send_ws_message(
    ws: State<'_, crate::transport::WsServer>,
    peer_id: String,
    message: crate::transport::WsMessage,
) -> Result<(), String> {
    ws.send_message(&peer_id, message).await
}

#[tauri::command]
pub async fn get_ws_connected_peers(ws: State<'_, crate::transport::WsServer>) -> Result<Vec<String>, String> {
    Ok(ws.connected_peers().await)
}

#[tauri::command]
pub async fn disconnect_ws_peer(ws: State<'_, crate::transport::WsServer>, peer_id: String) -> Result<(), String> {
    ws.disconnect_peer(&peer_id).await;
    Ok(())
}

/// Синхронизирует данные с конкретным peer через WebSocket
pub async fn sync_with_peer(
    db: &Database,
    ws: &crate::transport::WsServer,
    peer_id: &str,
) -> Result<(), String> {
    // 1. Получаем свои pending changes
    let my_changes = db.run(|conn| {
        let mut stmt = conn.prepare(
            "SELECT entity_type, entity_id, action, timestamp FROM sync_log WHERE synced = 0 ORDER BY timestamp ASC",
        ).map_err(|e| e.to_string())?;
        
        let mut changes = Vec::new();
        let rows = stmt.query_map([], |row| {
            Ok((row.get::<_, String>(0)?, row.get::<_, String>(1)?, row.get::<_, String>(2)?, row.get::<_, i64>(3)?))
        }).map_err(|e| e.to_string())?;
        
        for row in rows {
            let (entity_type, entity_id, action, timestamp) = row.map_err(|e| e.to_string())?;
            let data = if action != "delete" {
                match entity_type.as_str() {
                    "event" => get_event_json(conn, &entity_id)?,
                    "reminder" => get_reminder_json(conn, &entity_id)?,
                    _ => None,
                }
            } else { None };
            changes.push(SyncChange { entity_type, entity_id: entity_id.to_string(), action, timestamp, data });
        }
        Ok(changes)
    }).await?;

    // 2. Отправляем свои изменения peer
    if !my_changes.is_empty() {
        let sync_msg = crate::transport::WsMessage {
            msg_type: "sync_changes".to_string(),
            payload: serde_json::to_string(&my_changes).map_err(|e| e.to_string())?,
            timestamp: chrono::Utc::now().timestamp(),
            signature: None,
        };
        ws.send_message(peer_id, sync_msg).await?;
        log::info!("Sent {} changes to peer {}", my_changes.len(), peer_id);
    }

    // 3. Запрашиваем изменения у peer
    let request_msg = crate::transport::WsMessage {
        msg_type: "request_sync".to_string(),
        payload: "{}".to_string(),
        timestamp: chrono::Utc::now().timestamp(),
        signature: None,
    };
    ws.send_message(peer_id, request_msg).await?;

    Ok(())
}

/// Применяет изменения от remote peer и отправляет ответ
pub async fn handle_sync_message(
    db: &Database,
    ws: &crate::transport::WsServer,
    peer_id: &str,
    message: crate::transport::WsMessage,
) -> Result<(), String> {
    match message.msg_type.as_str() {
        "sync_changes" => {
            // Получили изменения от peer — применяем
            let changes: Vec<SyncChange> = serde_json::from_str(&message.payload)
                .map_err(|e| format!("Failed to parse sync changes: {}", e))?;
            
            let result = apply_remote_batch_internal(db, changes).await?;
            log::info!("Applied {} changes from peer {} (skipped: {}, errors: {})", 
                      result.applied, peer_id, result.skipped, result.errors);
            
            // Отправляем подтверждение
            let ack_msg = crate::transport::WsMessage {
                msg_type: "sync_ack".to_string(),
                payload: serde_json::to_string(&result).map_err(|e| e.to_string())?,
                timestamp: chrono::Utc::now().timestamp(),
                signature: None,
            };
            ws.send_message(peer_id, ack_msg).await?;
        }
        "request_sync" => {
            // Peer запросил наши изменения — отправляем
            let my_changes = db.run(|conn| {
                let mut stmt = conn.prepare(
                    "SELECT entity_type, entity_id, action, timestamp FROM sync_log WHERE synced = 0 ORDER BY timestamp ASC",
                ).map_err(|e| e.to_string())?;
                
                let mut changes = Vec::new();
                let rows = stmt.query_map([], |row| {
                    Ok((row.get::<_, String>(0)?, row.get::<_, String>(1)?, row.get::<_, String>(2)?, row.get::<_, i64>(3)?))
                }).map_err(|e| e.to_string())?;
                
                for row in rows {
                    let (entity_type, entity_id, action, timestamp) = row.map_err(|e| e.to_string())?;
                    let data = if action != "delete" {
                        match entity_type.as_str() {
                            "event" => get_event_json(conn, &entity_id)?,
                            "reminder" => get_reminder_json(conn, &entity_id)?,
                            _ => None,
                        }
                    } else { None };
                    changes.push(SyncChange { entity_type, entity_id: entity_id.to_string(), action, timestamp, data });
                }
                Ok(changes)
            }).await?;

            let sync_msg = crate::transport::WsMessage {
                msg_type: "sync_changes".to_string(),
                payload: serde_json::to_string(&my_changes).map_err(|e| e.to_string())?,
                timestamp: chrono::Utc::now().timestamp(),
                signature: None,
            };
            ws.send_message(peer_id, sync_msg).await?;
            log::info!("Sent {} changes to peer {} (requested)", my_changes.len(), peer_id);
        }
        "sync_ack" => {
            // Peer подтвердил применение наших изменений
            log::info!("Peer {} acknowledged sync", peer_id);
        }
        _ => {
            log::warn!("Unknown message type from peer {}: {}", peer_id, message.msg_type);
        }
    }
    Ok(())
}

/// Внутренняя функция для применения batch изменений
async fn apply_remote_batch_internal(db: &Database, changes: Vec<SyncChange>) -> Result<BatchApplyResult, String> {
    db.run(move |conn| {
        let mut applied = 0i64;
        let mut skipped = 0i64;
        let mut errors = 0i64;
        let mut results = Vec::new();

        conn.execute_batch("BEGIN TRANSACTION").map_err(|e| e.to_string())?;

        for change in changes {
            let entity_id = change.entity_id.clone();
            match apply_change_internal(conn, change) {
                Ok(result) => {
                    match result.status.as_str() {
                        "applied" => applied += 1,
                        "skipped_conflict" => skipped += 1,
                        _ => errors += 1,
                    }
                    results.push(result);
                }
                Err(e) => {
                    errors += 1;
                    results.push(ApplyResult { status: "error".to_string(), entity_id, message: Some(e) });
                }
            }
        }

        conn.execute_batch("COMMIT").map_err(|e| e.to_string())?;
        Ok(BatchApplyResult { applied, skipped, errors, results })
    }).await
}

/// Broadcast локальных изменений всем подключенным peer
pub async fn broadcast_local_changes(
    db: &Database,
    ws: &crate::transport::WsServer,
    entity_type: String,
    entity_id: String,
    action: String,
) -> Result<(), String> {
    // Получаем данные изменения
    let et = entity_type.clone();
    let eid = entity_id.clone();
    let act = action.clone();
    let change = db.run(move |conn| {
        let now = chrono::Utc::now().timestamp();
        let data = if act != "delete" {
            match et.as_str() {
                "event" => get_event_json(conn, &eid)?,
                "reminder" => get_reminder_json(conn, &eid)?,
                _ => None,
            }
        } else { None };
        
        Ok(SyncChange {
            entity_type: et,
            entity_id: eid,
            action: act,
            timestamp: now,
            data,
        })
    }).await?;

    // Отправляем всем подключенным peer
    let sync_msg = crate::transport::WsMessage {
        msg_type: "sync_changes".to_string(),
        payload: serde_json::to_string(&vec![change]).map_err(|e| e.to_string())?,
        timestamp: chrono::Utc::now().timestamp(),
        signature: None,
    };
    
    let sent = ws.broadcast(sync_msg).await?;
    log::info!("Broadcast {} change to {} peers", action, sent);
    
    Ok(())
}