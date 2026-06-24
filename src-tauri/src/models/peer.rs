use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Peer {
    pub id: String,
    pub name: String,
    pub public_key: String,
    pub last_seen: Option<i64>,
    pub is_trusted: bool,
    pub created_at: i64,
}