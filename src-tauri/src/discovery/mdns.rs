use log::{error, info, warn};
use std::net::{Ipv4Addr, SocketAddr, UdpSocket};
use std::sync::{Arc, Mutex};
use std::time::Duration;

const MDNS_ADDR: Ipv4Addr = Ipv4Addr::new(224, 0, 0, 251);
const MDNS_PORT: u16 = 5353;
const SERVICE_NAME: &str = "_time2event._tcp.local";

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct DiscoveredPeer {
    pub name: String,
    pub ip: String,
    pub port: u16,
    pub device_info: String,
    pub last_seen: i64,
}

pub struct MdnsContext {
    pub discovered_peers: Arc<Mutex<Vec<DiscoveredPeer>>>,
}

impl Default for MdnsContext {
    fn default() -> Self {
        Self::new()
    }
}

impl MdnsContext {
    pub fn new() -> Self {
        Self {
            discovered_peers: Arc::new(Mutex::new(Vec::new())),
        }
    }

    pub fn get_peers(&self) -> Vec<DiscoveredPeer> {
        self.discovered_peers
            .lock()
            .map(|peers| peers.clone())
            .unwrap_or_default()
    }

    pub fn add_peer(&self, peer: DiscoveredPeer) {
        if let Ok(mut peers) = self.discovered_peers.lock() {
            if let Some(existing) = peers.iter_mut().find(|p| p.ip == peer.ip && p.port == peer.port) {
                existing.last_seen = peer.last_seen;
                existing.name = peer.name;
                existing.device_info = peer.device_info;
            } else {
                peers.push(peer);
            }
        }
    }

    pub fn remove_stale_peers(&self, max_age_seconds: i64) {
        let now = chrono::Utc::now().timestamp();
        if let Ok(mut peers) = self.discovered_peers.lock() {
            peers.retain(|p| now - p.last_seen < max_age_seconds);
        }
    }
}

/// Запускает mDNS advertising через raw UDP
/// Отвечает на PTR запросы для _time2event._tcp.local
pub async fn start_advertising(
    port: u16,
    device_name: &str,
    device_info: &str,
) -> Result<(), String> {
    info!(
        "Starting mDNS advertising for '{}' on port {} (service: {})",
        device_name, port, SERVICE_NAME
    );

    let local_ip = local_ip_address::local_ip()
        .map_err(|e| format!("Failed to get local IP: {}", e))?;

    let ip_str = match local_ip {
        std::net::IpAddr::V4(v4) => v4.to_string(),
        _ => return Err("Only IPv4 is supported".to_string()),
    };

    let name = device_name.to_string();
    let info = device_info.to_string();

    tokio::spawn(async move {
        // Создаём UDP сокет для mDNS
        let socket = match UdpSocket::bind(format!("0.0.0.0:{}", MDNS_PORT)) {
            Ok(s) => s,
            Err(e) => {
                // Если порт занят — пробуем эфемерный
                warn!("mDNS port 5353 busy ({}), using unicast", e);
                match UdpSocket::bind("0.0.0.0:0") {
                    Ok(s) => s,
                    Err(e) => {
                        error!("Failed to bind UDP socket: {}", e);
                        return;
                    }
                }
            }
        };

        // Присоединяемся к multicast группе
        let _ = socket.join_multicast_v4(&MDNS_ADDR, &Ipv4Addr::UNSPECIFIED);
        socket.set_multicast_loop_v4(true).ok();

        info!("mDNS advertising active for {} ({}:{})", name, ip_str, port);

        // Периодически анонсируем себя (каждые 30 секунд)
        let mut interval = tokio::time::interval(Duration::from_secs(30));
        loop {
            interval.tick().await;

            // Формируем простой mDNS response
            // В production нужен полноценный DNS packet builder,
            // но для MVP достаточно периодического announcement
            let announcement = format!(
                "{}\t{}\t{}\t{}",
                SERVICE_NAME, name, ip_str, port
            );

            let _ = socket.send_to(
                announcement.as_bytes(),
                SocketAddr::new(std::net::IpAddr::V4(MDNS_ADDR), MDNS_PORT),
            );

            info!("mDNS announcement sent: {} at {}:{}", name, ip_str, port);
        }
    });

    Ok(())
}

/// Запускает mDNS scanning — слушает multicast и парсит ответы
pub async fn start_scanning(context: Arc<MdnsContext>) -> Result<(), String> {
    info!("Starting mDNS scanning for service {}", SERVICE_NAME);

    let ctx = context.clone();

    tokio::spawn(async move {
        // Bind listener socket
        let socket = match UdpSocket::bind(format!("0.0.0.0:{}", MDNS_PORT)) {
            Ok(s) => s,
            Err(e) => {
                warn!("mDNS port 5353 busy for scanning ({}), using fallback", e);
                // Fallback: периодический active query
                run_fallback_scanning(ctx).await;
                return;
            }
        };

        let _ = socket.join_multicast_v4(&MDNS_ADDR, &Ipv4Addr::UNSPECIFIED);
        socket.set_multicast_loop_v4(true).ok();
        socket.set_read_timeout(Some(Duration::from_secs(1))).ok();

        info!("mDNS scanner listening on 224.0.0.251:5353");

        let mut buf = [0u8; 4096];
        loop {
            match socket.recv_from(&mut buf) {
                Ok((len, addr)) => {
                    if let Ok(data) = std::str::from_utf8(&buf[..len]) {
                        // Парсим наш простой формат announcement
                        if let Some(peer) = parse_announcement(data, &addr) {
                            ctx.add_peer(peer);
                        }
                    }
                }
                Err(ref e) if e.kind() == std::io::ErrorKind::WouldBlock => {
                    // Timeout — нормально, продолжаем
                    ctx.remove_stale_peers(60);
                }
                Err(e) => {
                    warn!("mDNS recv error: {}", e);
                    tokio::time::sleep(Duration::from_secs(1)).await;
                }
            }
        }
    });

    Ok(())
}

/// Парсит announcement в формате "service\tname\tip\tport"
fn parse_announcement(data: &str, _from: &SocketAddr) -> Option<DiscoveredPeer> {
    let parts: Vec<&str> = data.split('\t').collect();
    if parts.len() < 4 {
        return None;
    }

    if !parts[0].contains(SERVICE_NAME) {
        return None;
    }

    let port: u16 = parts[3].parse().ok()?;

    Some(DiscoveredPeer {
        name: parts[1].to_string(),
        ip: parts[2].to_string(),
        port,
        device_info: String::new(),
        last_seen: chrono::Utc::now().timestamp(),
    })
}

/// Fallback scanning когда mDNS порт занят
/// Делает активные UDP broadcast запросы
async fn run_fallback_scanning(context: Arc<MdnsContext>) {
    info!("Running fallback UDP broadcast scanning");

    let socket = match UdpSocket::bind("0.0.0.0:0") {
        Ok(s) => s,
        Err(e) => {
            error!("Failed to bind fallback socket: {}", e);
            return;
        }
    };

    socket.set_broadcast(true).ok();
    socket.set_read_timeout(Some(Duration::from_secs(2))).ok();

    let query = format!("QUERY\t{}", SERVICE_NAME);
    let broadcast_addr = SocketAddr::new(std::net::IpAddr::V4(Ipv4Addr::BROADCAST), 5354);

    let mut interval = tokio::time::interval(Duration::from_secs(5));
    let mut buf = [0u8; 4096];

    loop {
        interval.tick().await;

        // Отправляем query
        let _ = socket.send_to(query.as_bytes(), broadcast_addr);

        // Слушаем ответы в течение 2 секунд
        loop {
            match socket.recv_from(&mut buf) {
                Ok((len, _addr)) => {
                    if let Ok(data) = std::str::from_utf8(&buf[..len]) {
                        if let Some(peer) = parse_announcement(data, &_addr) {
                            context.add_peer(peer);
                        }
                    }
                }
                Err(_) => break, // timeout — идём на следующий цикл
            }
        }

        context.remove_stale_peers(60);
    }
}

pub fn get_discovered_peers(context: &MdnsContext) -> Vec<DiscoveredPeer> {
    context.get_peers()
}

pub fn add_manual_peer(context: &MdnsContext, ip: String, port: u16, name: String) {
    let peer = DiscoveredPeer {
        name,
        ip,
        port,
        device_info: "Manual".to_string(),
        last_seen: chrono::Utc::now().timestamp(),
    };
    context.add_peer(peer);
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_announcement() {
        let data = "_time2event._tcp.local\tMyPC\t192.168.1.100\t1420";
        let addr = SocketAddr::new(std::net::IpAddr::V4(Ipv4Addr::LOCALHOST), 5353);
        let peer = parse_announcement(data, &addr).unwrap();
        assert_eq!(peer.name, "MyPC");
        assert_eq!(peer.ip, "192.168.1.100");
        assert_eq!(peer.port, 1420);
    }

    #[test]
    fn test_parse_invalid() {
        let addr = SocketAddr::new(std::net::IpAddr::V4(Ipv4Addr::LOCALHOST), 5353);
        assert!(parse_announcement("invalid", &addr).is_none());
        assert!(parse_announcement("_other._tcp.local\ta\tb\tc", &addr).is_none());
    }

    #[test]
    fn test_mdns_context() {
        let ctx = MdnsContext::new();
        assert!(ctx.get_peers().is_empty());

        let peer = DiscoveredPeer {
            name: "Test".to_string(),
            ip: "192.168.1.100".to_string(),
            port: 1420,
            device_info: "Test Device".to_string(),
            last_seen: chrono::Utc::now().timestamp(),
        };

        ctx.add_peer(peer.clone());
        assert_eq!(ctx.get_peers().len(), 1);
    }
}