use crate::db::Database;
use crate::models::{NewReminder, Reminder};
use rusqlite::params;
use tauri::State;
use uuid::Uuid;

#[tauri::command]
pub async fn create_reminder(
    app: tauri::AppHandle,
    db: State<'_, Database>,
    new_reminder: NewReminder,
) -> Result<Reminder, String> {
    let reminder = db
        .run(move |conn| {
            let now = chrono::Utc::now().timestamp();
            let id = Uuid::new_v4().to_string();
            let reminder = Reminder {
                id: id.clone(),
                event_id: new_reminder.event_id,
                remind_at: new_reminder.remind_at,
                message: new_reminder.message,
                is_sent: false,
                created_at: now,
            };
            conn.execute(
                "INSERT INTO reminders (id, event_id, remind_at, message, is_sent, created_at)
                 VALUES (?1, ?2, ?3, ?4, ?5, ?6)",
                params![
                    reminder.id,
                    reminder.event_id,
                    reminder.remind_at,
                    reminder.message,
                    reminder.is_sent as i32,
                    reminder.created_at,
                ],
            )
            .map_err(|e| e.to_string())?;
            Ok(reminder)
        })
        .await?;

    let db_clone = db.inner().clone();
    schedule_notification(&app, &db_clone, &reminder)?;
    Ok(reminder)
}

#[tauri::command]
pub async fn get_reminders(
    db: State<'_, Database>,
    event_id: String,
) -> Result<Vec<Reminder>, String> {
    db.run(move |conn| {
        let mut stmt = conn
            .prepare(
                "SELECT id, event_id, remind_at, message, is_sent, created_at
                 FROM reminders WHERE event_id = ?1 ORDER BY remind_at ASC",
            )
            .map_err(|e| e.to_string())?;
        let reminders = stmt
            .query_map(params![event_id], |row| {
                Ok(Reminder {
                    id: row.get(0)?,
                    event_id: row.get(1)?,
                    remind_at: row.get(2)?,
                    message: row.get(3)?,
                    is_sent: row.get::<_, i32>(4)? != 0,
                    created_at: row.get(5)?,
                })
            })
            .map_err(|e| e.to_string())?
            .collect::<Result<Vec<_>, _>>()
            .map_err(|e| e.to_string())?;
        Ok(reminders)
    })
    .await
}

#[tauri::command]
pub async fn delete_reminder(db: State<'_, Database>, reminder_id: String) -> Result<(), String> {
    db.run(move |conn| {
        conn.execute("DELETE FROM reminders WHERE id = ?1", params![reminder_id])
            .map_err(|e| e.to_string())?;
        Ok(())
    })
    .await
}

#[tauri::command]
pub async fn get_pending_reminders(db: State<'_, Database>) -> Result<Vec<Reminder>, String> {
    db.run(|conn| {
        let now = chrono::Utc::now().timestamp();
        let mut stmt = conn
            .prepare(
                "SELECT id, event_id, remind_at, message, is_sent, created_at
                 FROM reminders WHERE is_sent = 0 AND remind_at <= ?1 ORDER BY remind_at ASC",
            )
            .map_err(|e| e.to_string())?;
        let reminders = stmt
            .query_map(params![now], |row| {
                Ok(Reminder {
                    id: row.get(0)?,
                    event_id: row.get(1)?,
                    remind_at: row.get(2)?,
                    message: row.get(3)?,
                    is_sent: row.get::<_, i32>(4)? != 0,
                    created_at: row.get(5)?,
                })
            })
            .map_err(|e| e.to_string())?
            .collect::<Result<Vec<_>, _>>()
            .map_err(|e| e.to_string())?;
        Ok(reminders)
    })
    .await
}

/// Планирует уведомление через tokio::spawn
/// Работает пока приложение запущено. Пропущенные — ловит check_missed_reminders при старте.
fn schedule_notification(
    app: &tauri::AppHandle,
    db: &Database,
    reminder: &Reminder,
) -> Result<(), String> {
    use tauri_plugin_notification::NotificationExt;
    let now = chrono::Utc::now().timestamp();
    let delay_seconds = reminder.remind_at - now;
    let body = reminder
        .message
        .clone()
        .unwrap_or_else(|| "Напоминание о событии".to_string());

    if delay_seconds <= 0 {
        app.notification()
            .builder()
            .title("TimeToEvent")
            .body(&body)
            .show()
            .map_err(|e| format!("Failed to show notification: {}", e))?;

        let db_clone = db.clone();
        let reminder_id = reminder.id.clone();
        tauri::async_runtime::spawn(async move {
            let _ = db_clone
                .run(move |conn| {
                    conn.execute(
                        "UPDATE reminders SET is_sent = 1 WHERE id = ?1",
                        params![reminder_id],
                    )
                    .map_err(|e| e.to_string())
                })
                .await;
        });
    } else {
        let app_handle = app.clone();
        let db_clone = db.clone();
        let reminder_body = body;
        let reminder_id = reminder.id.clone();

        tokio::spawn(async move {
            tokio::time::sleep(tokio::time::Duration::from_secs(delay_seconds as u64)).await;

            let _ = app_handle
                .notification()
                .builder()
                .title("TimeToEvent")
                .body(&reminder_body)
                .show();

            log::info!("Notification fired for reminder {}", reminder_id);

            let _ = db_clone
                .run(move |conn| {
                    conn.execute(
                        "UPDATE reminders SET is_sent = 1 WHERE id = ?1",
                        params![reminder_id],
                    )
                    .map_err(|e| e.to_string())
                })
                .await;
        });
    }
    Ok(())
}

/// Проверяет пропущенные напоминания при старте.
/// Вызывается ОДИН РАЗ в lib.rs::setup() синхронно.
pub fn check_missed_reminders(app: &tauri::AppHandle, db: &Database) -> Result<(), String> {
    use tauri_plugin_notification::NotificationExt;

    let conn = db
        .conn
        .lock()
        .map_err(|e| format!("Mutex poisoned: {}", e))?;

    let now = chrono::Utc::now().timestamp();
    let mut stmt = conn
        .prepare(
            "SELECT id, event_id, remind_at, message, is_sent, created_at
             FROM reminders WHERE is_sent = 0 AND remind_at <= ?1",
        )
        .map_err(|e| e.to_string())?;

    let missed: Vec<Reminder> = stmt
        .query_map(params![now], |row| {
            Ok(Reminder {
                id: row.get(0)?,
                event_id: row.get(1)?,
                remind_at: row.get(2)?,
                message: row.get(3)?,
                is_sent: row.get::<_, i32>(4)? != 0,
                created_at: row.get(5)?,
            })
        })
        .map_err(|e| e.to_string())?
        .collect::<Result<Vec<_>, _>>()
        .map_err(|e| e.to_string())?;

    if missed.is_empty() {
        return Ok(());
    }

    log::info!(
        "Found {} missed reminders, showing notifications",
        missed.len()
    );

    for reminder in &missed {
        let body = reminder
            .message
            .clone()
            .unwrap_or_else(|| "Напоминание о событии".to_string());

        let _ = app
            .notification()
            .builder()
            .title("TimeToEvent (пропущено)")
            .body(&body)
            .show();

        let _ = conn.execute(
            "UPDATE reminders SET is_sent = 1 WHERE id = ?1",
            params![reminder.id],
        );
    }

    Ok(())
}
