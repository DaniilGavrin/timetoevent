use rusqlite::{Connection, Result};
use std::path::PathBuf;
use std::sync::{Arc, Mutex};
use super::migrations;

pub struct Database {
    pub(crate) conn: Arc<Mutex<Connection>>,
}

impl Clone for Database {
    fn clone(&self) -> Self {
        Self {
            conn: Arc::clone(&self.conn),
        }
    }
}

impl Database {
    pub async fn get_or_create_device_id(&self) -> Result<String, String> {
        self.run(|conn| {
            // Пытаемся прочитать существующий device_id
            let result: Result<String, _> = conn.query_row(
                "SELECT value FROM settings WHERE key = 'device_id'",
                [],
                |row| row.get(0),
            );

            match result {
                Ok(id) => Ok(id),
                Err(rusqlite::Error::QueryReturnedNoRows) => {
                    // Первый запуск — генерируем новый UUID
                    let id = uuid::Uuid::new_v4().to_string();
                    let now = chrono::Utc::now().timestamp();
                    conn.execute(
                        "INSERT INTO settings (key, value, updated_at) VALUES ('device_id', ?1, ?2)",
                        rusqlite::params![id, now],
                    )
                    .map_err(|e| e.to_string())?;
                    log::info!("Generated new device_id: {}", id);
                    Ok(id)
                }
                Err(e) => Err(e.to_string()),
            }
        })
        .await
    }

    pub fn new(db_path: PathBuf) -> Result<Self> {
        let conn = Connection::open(db_path)?;
        conn.execute_batch("PRAGMA foreign_keys = ON;")?;
        let db = Database {
            conn: Arc::new(Mutex::new(conn)),
        };
        db.run_migrations()?;
        Ok(db)
    }

    fn run_migrations(&self) -> Result<()> {
        let conn = self.conn.lock().unwrap();
        migrations::run_migrations(&conn)
    }

    pub fn get_connection(&self) -> std::sync::MutexGuard<'_, Connection> {
        self.conn.lock().unwrap()
    }

    /// Async wrapper — выполняет closure в blocking thread, не блокируя tokio runtime
    pub async fn run<F, R>(&self, f: F) -> Result<R, String>
    where
        F: FnOnce(&Connection) -> Result<R, String> + Send + 'static,
        R: Send + 'static,
    {
        let conn = Arc::clone(&self.conn);
        tokio::task::spawn_blocking(move || {
            let conn_guard = conn.lock().map_err(|e| format!("Mutex poisoned: {}", e))?;
            f(&conn_guard)
        })
        .await
        .map_err(|e| format!("Task join error: {}", e))?
    }
}