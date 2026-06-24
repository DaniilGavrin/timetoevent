import { invoke } from '@tauri-apps/api/core';

// ========================= Types =========================

export interface Event {
  id: string;
  title: string;
  description: string | null;
  event_date: number;
  event_type: 'countdown' | 'countup';
  category: string | null;
  color: string | null;
  is_favorite: boolean;
  is_archived: boolean;
  created_at: number;
  updated_at: number;
}

export interface NewEvent {
  title: string;
  description?: string;
  event_date: number;
  event_type: 'countdown' | 'countup';
  category?: string;
  color?: string;
}

export interface Reminder {
  id: string;
  event_id: string;
  remind_at: number;
  message: string | null;
  is_sent: boolean;
  created_at: number;
}

export interface NewReminder {
  event_id: string;
  remind_at: number;
  message?: string;
}

export interface Peer {
  id: string;
  name: string;
  public_key: string;
  last_seen: number | null;
  is_trusted: boolean;
  created_at: number;
}

export interface DiscoveredPeer {
  name: string;
  ip: string;
  port: number;
  device_info: string;
  last_seen: number;
}

export interface PairingRequest {
  peer_name: string;
  public_key: string;
  device_info?: string;
}

export interface PairingResponse {
  peer_id: string;
  code: string;
  local_public_key: string;
}

export interface PairingStatus {
  peer_id: string;
  peer_name: string;
  is_verified: boolean;
  attempts: number;
  blocked_for_seconds: number | null;
}

export interface SyncStatus {
  pending_changes: number;
  last_sync: number | null;
  total_synced: number;
  total_conflicts: number;
}

export interface SyncChange {
  entity_type: string;
  entity_id: string;
  action: string;
  timestamp: number;
  data?: unknown;
}

export interface DeltaResponse {
  changes: SyncChange[];
  generated_at: number;
  device_id: string;
}

// ========================= API =========================

export const api = {
  // System
  getLocalIp: () => invoke<string>('get_local_ip'),

  // Events
  getEvents: () => invoke<Event[]>('get_events'),
  createEvent: (event: NewEvent) => invoke<Event>('create_event', { newEvent: event }),
  updateEvent: (event: Event) => invoke<void>('update_event', { event }),
  deleteEvent: (eventId: string) => invoke<void>('delete_event', { eventId }),
  toggleFavorite: (eventId: string) => invoke<boolean>('toggle_favorite', { eventId }),

  // Reminders
  getReminders: (eventId: string) => invoke<Reminder[]>('get_reminders', { eventId }),
  createReminder: (reminder: NewReminder) => invoke<Reminder>('create_reminder', { newReminder: reminder }),
  deleteReminder: (reminderId: string) => invoke<void>('delete_reminder', { reminderId }),
  getPendingReminders: () => invoke<Reminder[]>('get_pending_reminders'),

  // Pairing
  startPairing: (request: PairingRequest) => invoke<PairingResponse>('start_pairing', { request }),
  verifyPairingCode: (peerId: string, code: string) => invoke<boolean>('verify_pairing_code', { peerId, code }),
  cancelPairing: (peerId: string) => invoke<void>('cancel_pairing', { peerId }),
  getPairingStatus: () => invoke<PairingStatus[]>('get_pairing_status'),
  getPairedDevices: () => invoke<Peer[]>('get_paired_devices'),
  removePeer: (peerId: string) => invoke<void>('remove_peer', { peerId }),
  updatePeerLastSeen: (peerId: string) => invoke<void>('update_peer_last_seen', { peerId }),
  isPeerConnected: (peerId: string) => invoke<boolean>('is_peer_connected', { peerId }),
  disconnectPeer: (peerId: string) => invoke<void>('disconnect_peer', { peerId }),

  // Sync
  getSyncStatus: () => invoke<SyncStatus>('get_sync_status'),
  getPendingChanges: () => invoke<DeltaResponse>('get_pending_changes'),
  markAsSynced: (timestamp: number) => invoke<number>('mark_as_synced', { timestamp }),
  applyRemoteChange: (change: SyncChange) => invoke<void>('apply_remote_change', { change }),
  applyRemoteBatch: (changes: SyncChange[]) => invoke<void>('apply_remote_batch', { changes }),
  cleanupOldSyncLogs: (days: number) => invoke<number>('cleanup_old_sync_logs', { days }),
  forceSyncAll: () => invoke<void>('force_sync_all'),
};