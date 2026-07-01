use log::{error, info, warn};
use socket2::{Domain, Protocol, Socket, Type};
use std::net::{Ipv4Addr, SocketAddr, UdpSocket};
use std::sync::{Arc, Mutex};
use std::time::Duration;

const MDNS_ADDR: Ipv4Addr = Ipv4Addr::new(224, 0, 0, 251);
const DISCOVERY_PORT: u16 = 5354;
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
    pub on_peer_discovered: DiscoveryCallback,
    pub self_ip: Arc<Mutex<Option<String>>>,
    pub self_port: Arc<Mutex<Option<u16>>>,
}

impl Default for MdnsContext {
    fn default() -> Self {
        Self::new()
    }
}

#[allow(dead_code)]
pub type DiscoveryCallback = Arc<Mutex<Option<Box<dyn Fn(DiscoveredPeer) + Send + Sync>>>>;

impl MdnsContext {
    pub fn new() -> Self {
        Self {
            discovered_peers: Arc::new(Mutex::new(Vec::new())),
            on_peer_discovered: Arc::new(Mutex::new(None)),
            self_ip: Arc::new(Mutex::new(None)),
            self_port: Arc::new(Mutex::new(None)),
        }
    }

    pub fn set_self(&self, ip: String, port: u16) {
        if let Ok(mut s) = self.self_ip.lock() {
            *s = Some(ip);
        }
        if let Ok(mut s) = self.self_port.lock() {
            *s = Some(port);
        }
    }

    pub fn set_discovery_callback<F>(&self, callback: F)
    where
        F: Fn(DiscoveredPeer) + Send + Sync + 'static,
    {
        if let Ok(mut cb) = self.on_peer_discovered.try_lock() {
            *cb = Some(Box::new(callback));
        }
    }

    #[allow(dead_code)]
    pub fn get_peers(&self) -> Vec<DiscoveredPeer> {
        self.discovered_peers
            .lock()
            .map(|p| p.clone())
            .unwrap_or_default()
    }

    pub fn add_peer(&self, peer: DiscoveredPeer) {
        let is_self = {
            let self_ip = self.self_ip.lock().ok().and_then(|s| s.clone());
            let self_port = self.self_port.lock().ok().and_then(|p| *p);
            match (self_ip, self_port) {
                (Some(ip), Some(port)) => peer.ip == ip && peer.port == port,
                _ => false,
            }
        };
        
        if is_self {
            log::debug!("Skipping self-discovery ({}:{})", peer.ip, peer.port);
            return;
        }
        
        if let Ok(mut peers) = self.discovered_peers.lock() {
            let is_new = !peers.iter().any(|p| p.ip == peer.ip && p.port == peer.port);
            
            if let Some(existing) = peers.iter_mut().find(|p| p.ip == peer.ip && p.port == peer.port) {
                existing.last_seen = peer.last_seen;
                existing.name = peer.name.clone();
                existing.device_info = peer.device_info.clone();
                log::debug!("Updated existing peer: {} at {}:{}", peer.name, peer.ip, peer.port);
            } else {
                peers.push(peer.clone());
                log::info!("✅ Added new peer to list: {} at {}:{} (total: {})", 
                    peer.name, peer.ip, peer.port, peers.len());
            }
            
            if is_new {
                drop(peers);
                if let Ok(cb) = self.on_peer_discovered.lock() {
                    if let Some(callback) = cb.as_ref() {
                        callback(peer);
                    }
                }
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

/// Создаёт UDP сокет с SO_REUSEADDR
fn create_mdns_socket(port: u16) -> Result<UdpSocket, String> {
    let socket = Socket::new(Domain::IPV4, Type::DGRAM, Some(Protocol::UDP))
        .map_err(|e| format!("Failed to create socket: {}", e))?;

    socket
        .set_reuse_address(true)
        .map_err(|e| format!("Failed to set SO_REUSEADDR: {}", e))?;

    let addr: SocketAddr = format!("0.0.0.0:{}", port)
        .parse()
        .map_err(|e| format!("Invalid address: {}", e))?;
    socket
        .bind(&addr.into())
        .map_err(|e| format!("Failed to bind to port {}: {}", port, e))?;

    socket
        .join_multicast_v4(&MDNS_ADDR, &Ipv4Addr::UNSPECIFIED)
        .map_err(|e| format!("Failed to join multicast: {}", e))?;

    socket.set_multicast_loop_v4(true).ok();

    Ok(socket.into())
}

pub async fn start_advertising(
    port: u16,
    device_name: &str,
    _device_info: &str,
) -> Result<(), String> {
    info!(
        "Starting discovery advertising for '{}' on port {}",
        device_name, port
    );

    let local_ip =
        local_ip_address::local_ip().map_err(|e| format!("Failed to get local IP: {}", e))?;

    let ip_str = match local_ip {
        std::net::IpAddr::V4(v4) => v4.to_string(),
        _ => return Err("Only IPv4 is supported".to_string()),
    };

    let name = device_name.to_string();

    tokio::spawn(async move {
        let socket = match create_mdns_socket(DISCOVERY_PORT) {
            Ok(s) => s,
            Err(e) => {
                error!("Failed to create discovery socket for advertising: {}", e);
                return;
            }
        };

        info!(
            "Discovery advertising active for {} ({}:{}) on port {}",
            name, ip_str, port, DISCOVERY_PORT
        );

        let mut interval = tokio::time::interval(Duration::from_secs(30));
        loop {
            interval.tick().await;
            let announcement = format!("{}\t{}\t{}\t{}", SERVICE_NAME, name, ip_str, port);
            let _ = socket.send_to(
                announcement.as_bytes(),
                SocketAddr::new(std::net::IpAddr::V4(MDNS_ADDR), DISCOVERY_PORT),
            );
        }
    });

    Ok(())
}

pub async fn start_scanning(context: Arc<MdnsContext>) -> Result<(), String> {
    info!("Starting discovery scanning for service {}", SERVICE_NAME);

    let ctx = context.clone();

    tokio::spawn(async move {
        let socket = match create_mdns_socket(DISCOVERY_PORT) {
            Ok(s) => s,
            Err(e) => {
                error!("Failed to create discovery socket for scanning: {}", e);
                return;
            }
        };

        socket.set_read_timeout(Some(Duration::from_secs(1))).ok();

        info!(
            "Discovery scanner listening on 224.0.0.251:{}",
            DISCOVERY_PORT
        );

        let mut buf = [0u8; 4096];
        let mut last_log_time = std::time::Instant::now();

        loop {
            match socket.recv_from(&mut buf) {
                Ok((len, addr)) => {
                    if let Ok(data) = std::str::from_utf8(&buf[..len]) {
                        if let Some(peer) = parse_announcement(data, &addr) {
                            info!(
                                "Discovered peer: {} at {}:{}",
                                peer.name, peer.ip, peer.port
                            );
                            ctx.add_peer(peer);
                        }
                    }
                }
                Err(ref e)
                    if e.kind() == std::io::ErrorKind::WouldBlock
                        || e.kind() == std::io::ErrorKind::TimedOut =>
                {
                    ctx.remove_stale_peers(60);
                }
                Err(e) => {
                    if last_log_time.elapsed() > Duration::from_secs(60) {
                        warn!("Discovery recv error: {}", e);
                        last_log_time = std::time::Instant::now();
                    }
                    tokio::time::sleep(Duration::from_secs(1)).await;
                }
            }
        }
    });

    Ok(())
}

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

#[allow(dead_code)]
pub fn get_discovered_peers(context: &MdnsContext) -> Vec<DiscoveredPeer> {
    context.get_peers()
}

#[allow(dead_code)]
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
        let addr = SocketAddr::new(std::net::IpAddr::V4(Ipv4Addr::LOCALHOST), 5354);
        let peer = parse_announcement(data, &addr).unwrap();
        assert_eq!(peer.name, "MyPC");
        assert_eq!(peer.ip, "192.168.1.100");
        assert_eq!(peer.port, 1420);
    }

    #[test]
    fn test_parse_invalid() {
        let addr = SocketAddr::new(std::net::IpAddr::V4(Ipv4Addr::LOCALHOST), 5354);
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