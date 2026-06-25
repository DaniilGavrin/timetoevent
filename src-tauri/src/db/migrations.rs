use rusqlite::{Connection, Result};

pub fn run_migrations(conn: &Connection) -> Result<()> {
    conn.execute_batch(
        "CREATE TABLE IF NOT EXISTS schema_version (
            version INTEGER PRIMARY KEY,
            applied_at INTEGER NOT NULL
        );",
    )?;

    let current_version: i64 = conn
        .query_row(
            "SELECT COALESCE(MAX(version), 0) FROM schema_version",
            [],
            |row| row.get(0),
        )
        .unwrap_or(0);

    // Миграция 1: Основные таблицы
    if current_version < 1 {
        conn.execute_batch(
            "
            CREATE TABLE IF NOT EXISTS events (
                id TEXT PRIMARY KEY,
                title TEXT NOT NULL,
                description TEXT,
                event_date INTEGER NOT NULL,
                event_type TEXT NOT NULL CHECK(event_type IN ('countdown', 'countup')),
                category TEXT,
                color TEXT,
                is_favorite INTEGER DEFAULT 0,
                is_archived INTEGER DEFAULT 0,
                created_at INTEGER NOT NULL,
                updated_at INTEGER NOT NULL
            );

            CREATE TABLE IF NOT EXISTS reminders (
                id TEXT PRIMARY KEY,
                event_id TEXT NOT NULL,
                remind_at INTEGER NOT NULL,
                message TEXT,
                is_sent INTEGER DEFAULT 0,
                created_at INTEGER NOT NULL,
                FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE
            );

            CREATE TABLE IF NOT EXISTS peers (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                public_key TEXT NOT NULL,
                last_seen INTEGER,
                is_trusted INTEGER DEFAULT 1,
                created_at INTEGER NOT NULL
            );

            CREATE TABLE IF NOT EXISTS sync_log (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                entity_type TEXT NOT NULL,
                entity_id TEXT NOT NULL,
                action TEXT NOT NULL,
                timestamp INTEGER NOT NULL,
                synced INTEGER DEFAULT 0
            );

            CREATE INDEX IF NOT EXISTS idx_events_event_date ON events(event_date);
            CREATE INDEX IF NOT EXISTS idx_events_category ON events(category);
            CREATE INDEX IF NOT EXISTS idx_events_is_favorite ON events(is_favorite);
            CREATE INDEX IF NOT EXISTS idx_reminders_event_id ON reminders(event_id);
            CREATE INDEX IF NOT EXISTS idx_reminders_remind_at ON reminders(remind_at);
            CREATE INDEX IF NOT EXISTS idx_sync_log_entity ON sync_log(entity_type, entity_id);

            INSERT INTO schema_version (version, applied_at) VALUES (1, strftime('%s', 'now'));
            ",
        )?;
    }

    // Миграция 2: Таблица настроек (для device_id и других ключей)
    if current_version < 2 {
        conn.execute_batch(
            "
            CREATE TABLE IF NOT EXISTS settings (
                key TEXT PRIMARY KEY,
                value TEXT NOT NULL,
                updated_at INTEGER NOT NULL
            );

            INSERT INTO schema_version (version, applied_at) VALUES (2, strftime('%s', 'now'));
            ",
        )?;
    }

    Ok(())
}
