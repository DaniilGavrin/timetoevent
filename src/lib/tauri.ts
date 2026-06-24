import { invoke } from '@tauri-apps/api/core';

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

export const api = {
  getLocalIp: () => invoke<string>('get_local_ip'),
  
  getEvents: () => invoke<Event[]>('get_events'),
  
  createEvent: (event: NewEvent) => invoke<Event>('create_event', { newEvent: event }),
};