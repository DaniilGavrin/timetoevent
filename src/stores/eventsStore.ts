import { create } from 'zustand';
import { api, Event, NewEvent } from '../lib/tauri';

interface EventsState {
  events: Event[];
  loading: boolean;
  error: string | null;
  
  fetchEvents: () => Promise<void>;
  createEvent: (event: NewEvent) => Promise<void>;
}

export const useEventsStore = create<EventsState>((set) => ({
  events: [],
  loading: false,
  error: null,
  
  fetchEvents: async () => {
    set({ loading: true, error: null });
    try {
      const events = await api.getEvents();
      set({ events, loading: false });
    } catch (error) {
      set({ error: String(error), loading: false });
    }
  },
  
  createEvent: async (newEvent: NewEvent) => {
    set({ loading: true, error: null });
    try {
      const event = await api.createEvent(newEvent);
      set((state) => ({ 
        events: [...state.events, event],
        loading: false 
      }));
    } catch (error) {
      set({ error: String(error), loading: false });
    }
  },
}));