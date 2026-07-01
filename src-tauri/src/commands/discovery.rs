use crate::discovery::MdnsContext;
use std::sync::Arc;
use tauri::State;

#[tauri::command]
pub async fn get_discovered_peers(
    mdns: State<'_, Arc<MdnsContext>>,  // ← ИСПРАВЛЕНО
) -> Result<Vec<crate::discovery::DiscoveredPeer>, String> {
    let peers = mdns.get_peers();
    log::info!("🔍 get_discovered_peers called, returning {} peers", peers.len());
    Ok(peers)
}