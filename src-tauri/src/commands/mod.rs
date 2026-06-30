pub mod events;
pub mod pairing;
pub mod reminders;
pub mod sync;
pub mod discovery;

use local_ip_address::local_ip;

#[tauri::command]
pub fn get_local_ip() -> Result<String, String> {
    match local_ip() {
        Ok(ip) => Ok(ip.to_string()),
        Err(e) => Err(format!("Failed to get local IP: {}", e)),
    }
}
