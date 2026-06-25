use crate::db::Database;
use crate::models::{Event, NewEvent};
use rusqlite::params;
use tauri::State;
use uuid::Uuid;

#[tauri::command]
pub async fn create_event(
    db: State<'_, Database>,
    ws: State<'_, crate::transport::WsServer>,
    new_event: NewEvent,
) -> Result<Event, String> {
    let event = db.run(move |conn| {
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
                event.id, event.title, event.description, event.event_date,
                event.event_type, event.category, event.color,
                event.is_favorite as i32, event.is_archived as i32,
                event.created_at, event.updated_at,
            ],
        )
        .map_err(|e| e.to_string())?;
        conn.execute(
            "INSERT INTO sync_log (entity_type, entity_id, action, timestamp, synced)
             VALUES ('event', ?1, 'create', ?2, 0)",
            params![event.id, now],
        )
        .map_err(|e| e.to_string())?;
        Ok(event)
    })
    .await?;

    // Автоматически broadcast всем peer
    let _ = crate::commands::sync::broadcast_local_changes(
        &db,
        &ws,
        "event".to_string(),
        event.id.clone(),
        "create".to_string(),
    )
    .await;

    Ok(event)
}

#[tauri::command]
pub async fn get_events(db: State<'_, Database>) -> Result<Vec<Event>, String> {
    db.run(|conn| {
        let mut stmt = conn
            .prepare(
                "SELECT id, title, description, event_date, event_type, category, color,
                        is_favorite, is_archived, created_at, updated_at
                 FROM events WHERE is_archived = 0 ORDER BY event_date ASC",
            )
            .map_err(|e| e.to_string())?;
        let events = stmt
            .query_map([], |row| {
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
            })
            .map_err(|e| e.to_string())?
            .collect::<Result<Vec<_>, _>>()
            .map_err(|e| e.to_string())?;
        Ok(events)
    })
    .await
}

#[tauri::command]
pub async fn update_event(
    db: State<'_, Database>,
    ws: State<'_, crate::transport::WsServer>,
    event: Event,
) -> Result<(), String> {
    let event_id_for_db = event.id.clone();
    let event_id_for_ws = event.id.clone();

    db.run(move |conn| {
        let now = chrono::Utc::now().timestamp();
        conn.execute(
            "UPDATE events SET
                title = ?1, description = ?2, event_date = ?3, event_type = ?4,
                category = ?5, color = ?6, is_favorite = ?7, is_archived = ?8,
                updated_at = ?9
             WHERE id = ?10",
            params![
                event.title,
                event.description,
                event.event_date,
                event.event_type,
                event.category,
                event.color,
                event.is_favorite as i32,
                event.is_archived as i32,
                now,
                event.id,
            ],
        )
        .map_err(|e| e.to_string())?;
        conn.execute(
            "INSERT INTO sync_log (entity_type, entity_id, action, timestamp, synced)
             VALUES ('event', ?1, 'update', ?2, 0)",
            params![event_id_for_db, now],
        )
        .map_err(|e| e.to_string())?;
        Ok(())
    })
    .await?;

    // Broadcast после завершения БД
    let _ = crate::commands::sync::broadcast_local_changes(
        &db,
        &ws,
        "event".to_string(),
        event_id_for_ws,
        "update".to_string(),
    )
    .await;

    Ok(())
}

#[tauri::command]
pub async fn delete_event(
    db: State<'_, Database>,
    ws: State<'_, crate::transport::WsServer>,
    event_id: String,
) -> Result<(), String> {
    let event_id_for_db = event_id.clone();
    let event_id_for_ws = event_id.clone();

    db.run(move |conn| {
        let now = chrono::Utc::now().timestamp();
        conn.execute("DELETE FROM events WHERE id = ?1", params![event_id])
            .map_err(|e| e.to_string())?;
        conn.execute(
            "INSERT INTO sync_log (entity_type, entity_id, action, timestamp, synced)
             VALUES ('event', ?1, 'delete', ?2, 0)",
            params![event_id_for_db, now],
        )
        .map_err(|e| e.to_string())?;
        Ok(())
    })
    .await?;

    let _ = crate::commands::sync::broadcast_local_changes(
        &db,
        &ws,
        "event".to_string(),
        event_id_for_ws,
        "delete".to_string(),
    )
    .await;

    Ok(())
}

#[tauri::command]
pub async fn toggle_favorite(
    db: State<'_, Database>,
    ws: State<'_, crate::transport::WsServer>,
    event_id: String,
) -> Result<bool, String> {
    let event_id_for_db = event_id.clone();
    let event_id_for_ws = event_id.clone();

    let new_value = db
        .run(move |conn| {
            let now = chrono::Utc::now().timestamp();
            let current: i32 = conn
                .query_row(
                    "SELECT is_favorite FROM events WHERE id = ?1",
                    params![event_id_for_db],
                    |row| row.get(0),
                )
                .map_err(|e| e.to_string())?;

            let new_value = if current == 0 { 1 } else { 0 };

            conn.execute(
                "UPDATE events SET is_favorite = ?1, updated_at = ?2 WHERE id = ?3",
                params![new_value, now, event_id_for_db],
            )
            .map_err(|e| e.to_string())?;

            // ← Добавляем запись в sync_log
            conn.execute(
                "INSERT INTO sync_log (entity_type, entity_id, action, timestamp, synced)
             VALUES ('event', ?1, 'update', ?2, 0)",
                params![event_id_for_db, now],
            )
            .map_err(|e| e.to_string())?;

            Ok(new_value != 0)
        })
        .await?;

    // ← Broadcast всем peer
    let _ = crate::commands::sync::broadcast_local_changes(
        &db,
        &ws,
        "event".to_string(),
        event_id_for_ws,
        "update".to_string(),
    )
    .await;

    Ok(new_value)
}
