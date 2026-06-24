use rusqlite::{Connection, Result};
use std::path::PathBuf;
use std::sync::Mutex;

use super::migrations;

pub struct Database {
    conn: Mutex<Connection>,
}

impl Database {
    pub fn new(db_path: PathBuf) -> Result<Self> {
        let conn = Connection::open(db_path)?;
        
        // Включаем foreign keys
        conn.execute_batch("PRAGMA foreign_keys = ON;")?;
        
        let db = Database {
            conn: Mutex::new(conn),
        };
        
        // Запускаем миграции
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
}