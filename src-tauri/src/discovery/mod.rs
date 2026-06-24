pub mod mdns;

pub use mdns::{
    start_advertising, start_scanning, get_discovered_peers, add_manual_peer,
    DiscoveredPeer, MdnsContext,
};