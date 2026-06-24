use serde::{Deserialize, Serialize};

#[allow(dead_code)]
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Reminder {
    pub id: String,
    pub event_id: String,
    pub remind_at: i64,
    pub message: Option<String>,
    pub is_sent: bool,
    pub created_at: i64,
}

#[allow(dead_code)]
#[derive(Debug, Deserialize)]
pub struct NewReminder {
    pub event_id: String,
    pub remind_at: i64,
    pub message: Option<String>,
}