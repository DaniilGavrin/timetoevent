import { create } from 'zustand';
import { api, type Peer, type DiscoveredPeer } from '../lib/tauri';

interface DevicesState {
  discoveredPeers: DiscoveredPeer[];
  pairedDevices: Peer[];
  connectedPeerIds: string[];

  loading: boolean;
  error: string | null;

  pairingPeerId: string | null;
  pairingCode: string | null;
  pairingLocalPublicKey: string | null;
  pairingError: string | null;
  pairingLoading: boolean;

  fetchDiscoveredPeers: () => Promise<void>;
  fetchPairedDevices: () => Promise<void>;
  fetchConnectedPeers: () => Promise<void>;
  fetchAll: () => Promise<void>;

  startPairing: (peerName: string, publicKey: string, deviceInfo?: string) => Promise<void>;
  verifyPairingCode: (code: string) => Promise<boolean>;
  cancelPairing: () => Promise<void>;

  removePeer: (peerId: string) => Promise<void>;
  disconnectPeer: (peerId: string) => Promise<void>;
}

export const useDevicesStore = create<DevicesState>((set, get) => ({
  discoveredPeers: [],
  pairedDevices: [],
  connectedPeerIds: [],
  loading: false,
  error: null,

  pairingPeerId: null,
  pairingCode: null,
  pairingLocalPublicKey: null,
  pairingError: null,
  pairingLoading: false,

  fetchDiscoveredPeers: async () => {
    try {
      const peers = await api.getDiscoveredPeers();
      set({ discoveredPeers: peers });
    } catch (error) {
      console.error('Failed to fetch discovered peers:', error);
    }
  },

  fetchPairedDevices: async () => {
    try {
      const devices = await api.getPairedDevices();
      set({ pairedDevices: devices });
    } catch (error) {
      console.error('Failed to fetch paired devices:', error);
    }
  },

  fetchConnectedPeers: async () => {
    try {
      const ids = await api.getWsConnectedPeers();
      set({ connectedPeerIds: ids });
    } catch (error) {
      console.error('Failed to fetch connected peers:', error);
    }
  },

  fetchAll: async () => {
    set({ loading: true, error: null });
    try {
      await Promise.all([
        get().fetchDiscoveredPeers(),
        get().fetchPairedDevices(),
        get().fetchConnectedPeers(),
      ]);
    } catch (error) {
      set({ error: String(error) });
    } finally {
      set({ loading: false });
    }
  },

  startPairing: async (peerName, publicKey, deviceInfo) => {
    set({ pairingLoading: true, pairingError: null });
    try {
      const response = await api.startPairing({
        peer_name: peerName,
        public_key: publicKey,
        device_info: deviceInfo,
      });
      set({
        pairingPeerId: response.peer_id,
        pairingCode: response.code,
        pairingLocalPublicKey: response.local_public_key,
        pairingLoading: false,
      });
    } catch (error) {
      set({ pairingError: String(error), pairingLoading: false });
    }
  },

  verifyPairingCode: async (code) => {
    const { pairingPeerId } = get();
    if (!pairingPeerId) {
      set({ pairingError: 'No active pairing session' });
      return false;
    }

    set({ pairingLoading: true, pairingError: null });
    try {
      const success = await api.verifyPairingCode(pairingPeerId, code);
      if (success) {
        set({
          pairingPeerId: null,
          pairingCode: null,
          pairingLocalPublicKey: null,
          pairingLoading: false,
        });
        await get().fetchPairedDevices();
        await get().fetchConnectedPeers();
        return true;
      } else {
        set({ pairingError: 'Invalid code', pairingLoading: false });
        return false;
      }
    } catch (error) {
      set({ pairingError: String(error), pairingLoading: false });
      return false;
    }
  },

  cancelPairing: async () => {
    const { pairingPeerId } = get();
    if (pairingPeerId) {
      try {
        await api.cancelPairing(pairingPeerId);
      } catch (error) {
        console.error('Failed to cancel pairing:', error);
      }
    }
    set({
      pairingPeerId: null,
      pairingCode: null,
      pairingLocalPublicKey: null,
      pairingError: null,
      pairingLoading: false,
    });
  },

  removePeer: async (peerId) => {
    try {
      await api.removePeer(peerId);
      await get().fetchPairedDevices();
    } catch (error) {
      console.error('Failed to remove peer:', error);
      throw error;
    }
  },

  disconnectPeer: async (peerId) => {
    try {
      await api.disconnectPeer(peerId);
      await get().fetchConnectedPeers();
    } catch (error) {
      console.error('Failed to disconnect peer:', error);
      throw error;
    }
  },
}));