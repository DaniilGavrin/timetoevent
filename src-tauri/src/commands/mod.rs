use local_ip_address::local_ip;
use rusqlite::params;
use tauri::State;
use uuid::Uuid;

use crate::db::Database;
use crate::models::{Event, NewEvent};

#[tauri::command]
pub fn get_local_ip() -> Result<String, String> {
    match local_ip() {
        Ok(ip) => Ok(ip.to_string()),
        Err(e) => Err(format!("Failed to get local IP: {}", e)),
    }
}

#[tauri::command]
pub fn create_event(db: State<Database>, new_event: NewEvent) -> Result<Event, String> {
    let conn = db.get_connection();
    let now = chrono::Utc::now().timestamp();
    let id = Uuid::new_v4().to_string();
    
    let event = Event {
        id: id.clone(),
        title: new_event.title,
        description: new_event.description,
        event_date: new_event.event_date,
        event_type: new_event.event_type,
        category: new_event.category,
        color: new_event.color,
        is_favorite: false,
        is_archived: false,
        created_at: now,
        updated_at: now,
    };
    
    conn.execute(
        "INSERT INTO events (id, title, description, event_date, event_type, category, color, is_favorite, is_archived, created_at, updated_at)
         VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11)",
        params![
            event.id,
            event.title,
            event.description,
            event.event_date,
            event.event_type,
            event.category,
            event.color,
            event.is_favorite as i32,
            event.is_archived as i32,
            event.created_at,
            event.updated_at,
        ],
    ).map_err(|e| e.to_string())?;
    
    // Записываем в sync_log
    conn.execute(
        "INSERT INTO sync_log (entity_type, entity_id, action, timestamp, synced)
         VALUES ('event', ?1, 'create', ?2, 0)",
        params![event.id, now],
    ).map_err(|e| e.to_string())?;
    
    Ok(event)
}

#[tauri::command]
pub fn get_events(db: State<Database>) -> Result<Vec<Event>, String> {
    let conn = db.get_connection();
    
    let mut stmt = conn.prepare(
        "SELECT id, title, description, event_date, event_type, category, color, is_favorite, is_archived, created_at, updated_at
         FROM events
         WHERE is_archived = 0
         ORDER BY event_date ASC"
    ).map_err(|e| e.to_string())?;
    
    let events = stmt.query_map([], |row| {
        Ok(Event {
            id: row.get(0)?,
            title: row.get(1)?,
            description: row.get(2)?,
            event_date: row.get(3)?,
            event_type: row.get(4)?,
            category: row.get(5)?,
            color: row.get(6)?,
            is_favorite: row.get::<_, i32>(7)? != 0,
            is_archived: row.get::<_, i32>(8)? != 0,
            created_at: row.get(9)?,
            updated_at: row.get(10)?,
        })
    }).map_err(|e| e.to_string())?
    .collect::<Result<Vec<_>, _>>()
    .map_err(|e| e.to_string())?;
    
    Ok(events)
}