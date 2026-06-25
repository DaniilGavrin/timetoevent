use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Event {
    pub id: String,
    pub title: String,
    pub description: Option<String>,
    pub event_date: i64,    // Unix timestamp
    pub event_type: String, // "countdown" или "countup"
    pub category: Option<String>,
    pub color: Option<String>,
    pub is_favorite: bool,
    pub is_archived: bool,
    pub created_at: i64,
    pub updated_at: i64,
}

#[derive(Debug, Deserialize)]
pub struct NewEvent {
    pub title: String,
    pub description: Option<String>,
    pub event_date: i64,
    pub event_type: String,
    pub category: Option<String>,
    pub color: Option<String>,
}
