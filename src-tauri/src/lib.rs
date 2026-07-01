mod commands;
mod crypto;
mod db;
mod discovery;
mod models;
mod transport;

use commands::pairing::{ActiveConnections, PairingManager};
use discovery::MdnsContext;
use tauri::Manager;

#[cfg(desktop)]
use tauri_plugin_autostart::MacosLauncher;

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    #[allow(unused_mut)]
    let mut builder = tauri::Builder::default()
        .plugin(tauri_plugin_opener::init())
        .plugin(tauri_plugin_notification::init())
        .plugin(tauri_plugin_fs::init())
        .plugin(tauri_plugin_dialog::init())
        .plugin(tauri_plugin_shell::init())
        .plugin(tauri_plugin_clipboard_manager::init())
        .plugin(tauri_plugin_os::init())
        .plugin(tauri_plugin_log::Builder::new().build())
        .plugin(tauri_plugin_updater::Builder::new().build())
        .plugin(tauri_plugin_process::init());

    #[cfg(desktop)]
    {
        builder = builder.plugin(tauri_plugin_autostart::init(
            MacosLauncher::LaunchAgent,
            Some(vec!["--minimized"]),
        ));
    }

    builder
        .setup(|app| {
            let app_dir = app
                .path()
                .app_data_dir()
                .expect("failed to get app data dir");
            std::fs::create_dir_all(&app_dir).expect("failed to create app data dir");

            let db_path = app_dir.join("timetoevent.db");
            let database = db::Database::new(db_path).expect("failed to initialize database");

            // WebSocket сервер
            let ws_server = std::sync::Arc::new(transport::WsServer::new(8080));

            // 🔥 mDNS контекст — создаём ПЕРВЫМ
            let mdns_context = std::sync::Arc::new(MdnsContext::new());

            // 🔥 Теперь устанавливаем self_ip ПОСЛЕ создания mdns_context
            if let Ok(my_ip) = local_ip_address::local_ip() {
                mdns_context.set_self(my_ip.to_string(), 8080);
            }

            // Callback при обнаружении нового устройства
            let ws_clone = ws_server.clone();
            let db_clone = database.clone();
            let my_ip = local_ip_address::local_ip()
                .map(|ip| ip.to_string())
                .unwrap_or_default();
            let my_port = 8080u16;

            mdns_context.set_discovery_callback(move |peer| {
                // 🔥 Фильтруем самих себя
                if peer.ip == my_ip && peer.port == my_port {
                    log::info!("Skipping self-discovery ({}:{})", peer.ip, peer.port);
                    return;
                }

                let ws = ws_clone.clone();
                let db = db_clone.clone();
                let peer_id = format!("{}:{}", peer.ip, peer.port);
                log::info!(
                    "New peer discovered: {} at {}:{}",
                    peer.name,
                    peer.ip,
                    peer.port
                );
                tauri::async_runtime::spawn(async move {
                    // 🔥 Используем НАШ публичный ключ, а не генерируем новый
                    let public_key = ws.local_public_key();
                    
                    match ws
                        .connect_to_peer(&peer_id, &peer.ip, peer.port, &public_key)
                        .await
                    {
                        Ok(_) => {
                            log::info!("Connected to peer {} via WebSocket", peer_id);
                            if let Err(e) = commands::sync::sync_with_peer(&db, &ws, &peer_id).await
                            {
                                log::error!("Sync failed with peer {}: {}", peer_id, e);
                            }
                        }
                        Err(e) => {
                            log::error!("Failed to connect to peer {}: {}", peer_id, e);
                        }
                    }
                });
            });

            // Handler для входящих WS сообщений
            let ws_clone2 = ws_server.clone();
            let db_clone2 = database.clone();
            ws_server.set_message_handler(move |peer_id, message| {
                let ws = ws_clone2.clone();
                let db = db_clone2.clone();
                tauri::async_runtime::spawn(async move {
                    if let Err(e) =
                        commands::sync::handle_sync_message(&db, &ws, &peer_id, message).await
                    {
                        log::error!("Failed to handle sync message from {}: {}", peer_id, e);
                    }
                });
            });

            // Запускаем mDNS
            let ctx1 = mdns_context.clone();
            tauri::async_runtime::spawn(async move {
                if let Err(e) = discovery::start_scanning(ctx1).await {
                    log::error!("mDNS scan failed: {}", e);
                }
            });

            let _ctx2 = mdns_context.clone();
            tauri::async_runtime::spawn(async move {
                if let Err(e) = discovery::start_advertising(8080, "TimeToEvent", "Desktop").await {
                    log::error!("mDNS adv failed: {}", e);
                }
            });

            // Запускаем WS сервер
            let ws_clone3 = ws_server.clone();
            tauri::async_runtime::spawn(async move {
                if let Err(e) = ws_clone3.start().await {
                    log::error!("Failed to start WebSocket server: {}", e);
                }
            });

            // Проверяем пропущенные напоминания
            if let Err(e) = commands::reminders::check_missed_reminders(app.handle(), &database) {
                log::error!("Failed to check missed reminders: {}", e);
            }

            app.manage(mdns_context);
            app.manage(database);
            app.manage(PairingManager::new());
            app.manage(ActiveConnections::new());
            app.manage(ws_server);

            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            commands::get_local_ip,
            commands::events::create_event,
            commands::events::get_events,
            commands::events::update_event,
            commands::events::delete_event,
            commands::events::toggle_favorite,
            commands::reminders::create_reminder,
            commands::reminders::get_reminders,
            commands::reminders::delete_reminder,
            commands::reminders::get_pending_reminders,
            commands::pairing::start_pairing,
            commands::pairing::verify_pairing_code,
            commands::pairing::cancel_pairing,
            commands::pairing::get_pairing_status,
            commands::pairing::get_paired_devices,
            commands::pairing::remove_peer,
            commands::pairing::update_peer_last_seen,
            commands::pairing::is_peer_connected,
            commands::pairing::disconnect_peer,
            commands::sync::get_sync_status,
            commands::sync::get_pending_changes,
            commands::sync::mark_as_synced,
            commands::sync::apply_remote_change,
            commands::sync::apply_remote_batch,
            commands::sync::cleanup_old_sync_logs,
            commands::sync::force_sync_all,
            commands::sync::connect_to_peer,
            commands::sync::send_ws_message,
            commands::sync::get_ws_connected_peers,
            commands::sync::disconnect_ws_peer,
            commands::discovery::get_discovered_peers,
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}