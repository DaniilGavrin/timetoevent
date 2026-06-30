use crate::discovery::MdnsContext;
use tauri::State;

/// Получить список обнаруженных устройств через mDNS
#[tauri::command]
pub async fn get_discovered_peers(
    mdns: State<'_, MdnsContext>,
) -> Result<Vec<crate::discovery::DiscoveredPeer>, String> {
    Ok(mdns.get_peers())
}