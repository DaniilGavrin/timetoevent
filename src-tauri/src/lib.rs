mod commands;
mod crypto;
mod db;
mod discovery;
mod models;
mod transport;

use tauri::Manager;
use tauri_plugin_autostart::MacosLauncher;
use commands::pairing::{PairingManager, ActiveConnections};
use discovery::MdnsContext;
use std::sync::Arc;

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_opener::init())
        .plugin(tauri_plugin_notification::init())
        .plugin(tauri_plugin_fs::init())
        .plugin(tauri_plugin_dialog::init())
        .plugin(tauri_plugin_shell::init())
        .plugin(tauri_plugin_autostart::init(MacosLauncher::LaunchAgent, Some(vec!["--minimized"])))
        .plugin(tauri_plugin_clipboard_manager::init())
        .plugin(tauri_plugin_os::init())
        .plugin(tauri_plugin_log::Builder::new().build())
        .plugin(tauri_plugin_updater::Builder::new().build())
        .plugin(tauri_plugin_process::init())
        .setup(|app| {
            let app_dir = app.path().app_data_dir().expect("failed to get app data dir");
            std::fs::create_dir_all(&app_dir).expect("failed to create app data dir");
            let db_path = app_dir.join("timetoevent.db");
            let database = db::Database::new(db_path).expect("failed to initialize database");

            let mdns_context = Arc::new(MdnsContext::new());
            let ctx1 = mdns_context.clone();
            tauri::async_runtime::spawn(async move {
                if let Err(e) = discovery::start_scanning(ctx1).await { log::error!("mDNS scan failed: {}", e); }
            });
            let ctx2 = mdns_context.clone();
            tauri::async_runtime::spawn(async move {
                if let Err(e) = discovery::start_advertising(1420, "TimeToEvent", "Desktop").await { log::error!("mDNS adv failed: {}", e); }
            });

            if let Err(e) = commands::reminders::check_missed_reminders(app.handle(), &database) {
                log::error!("Failed to check missed reminders: {}", e);
            }

            app.manage(mdns_context);
            app.manage(database);
            app.manage(PairingManager::new());
            app.manage(ActiveConnections::new());
            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            // IP
            commands::get_local_ip,
            // Events
            commands::events::create_event,
            commands::events::get_events,
            commands::events::update_event,
            commands::events::delete_event,
            commands::events::toggle_favorite,
            // Reminders
            commands::reminders::create_reminder,
            commands::reminders::get_reminders,
            commands::reminders::delete_reminder,
            commands::reminders::get_pending_reminders,
            // Pairing
            commands::pairing::start_pairing,
            commands::pairing::verify_pairing_code,
            commands::pairing::cancel_pairing,
            commands::pairing::get_pairing_status,
            commands::pairing::get_paired_devices,
            commands::pairing::remove_peer,
            commands::pairing::update_peer_last_seen,
            commands::pairing::is_peer_connected,
            commands::pairing::disconnect_peer,
            // Sync
            commands::sync::get_sync_status,
            commands::sync::get_pending_changes,
            commands::sync::mark_as_synced,
            commands::sync::apply_remote_change,
            commands::sync::apply_remote_batch,
            commands::sync::cleanup_old_sync_logs,
            commands::sync::force_sync_all,
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}