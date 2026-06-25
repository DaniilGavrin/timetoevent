import { create } from 'zustand';
import { api, Event, NewEvent } from '../lib/tauri';

interface EventsState {
  events: Event[];
  loading: boolean;
  error: string | null;
  fetchEvents: () => Promise<void>;
  createEvent: (event: NewEvent) => Promise<Event>;
  updateEvent: (event: Event) => Promise<void>;
  deleteEvent: (eventId: string) => Promise<void>;
  toggleFavorite: (eventId: string) => Promise<void>;
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
        loading: false,
        error: null,
      }));
      return event;
    } catch (error) {
      set({ error: String(error), loading: false });
      throw error;
    }
  },

  updateEvent: async (event: Event) => {
    try {
      await api.updateEvent(event);
      set((state) => ({
        events: state.events.map((e) => (e.id === event.id ? event : e)),
      }));
    } catch (error) {
      set({ error: String(error) });
      throw error;
    }
  },

  deleteEvent: async (eventId: string) => {
    try {
      await api.deleteEvent(eventId);
      set((state) => ({
        events: state.events.filter((e) => e.id !== eventId),
      }));
    } catch (error) {
      set({ error: String(error) });
      throw error;
    }
  },

  toggleFavorite: async (eventId: string) => {
    try {
      const isFavorite = await api.toggleFavorite(eventId);
      set((state) => ({
        events: state.events.map((e) =>
          e.id === eventId ? { ...e, is_favorite: isFavorite } : e,
        ),
      }));
    } catch (error) {
      set({ error: String(error) });
      throw error;
    }
  },
}));