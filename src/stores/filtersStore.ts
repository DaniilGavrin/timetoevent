import { create } from 'zustand';
import type { Event } from '../lib/tauri';

export type EventTypeFilter = 'all' | 'countdown' | 'countup';
export type StatusFilter = 'all' | 'favorite';
export type SortBy = 'date_asc' | 'date_desc' | 'title' | 'created';

interface FiltersState {
  search: string;
  eventType: EventTypeFilter;
  status: StatusFilter;
  category: string | null;
  sortBy: SortBy;

  setSearch: (value: string) => void;
  setEventType: (value: EventTypeFilter) => void;
  setStatus: (value: StatusFilter) => void;
  setCategory: (value: string | null) => void;
  setSortBy: (value: SortBy) => void;
  reset: () => void;

  applyFilters: (events: Event[]) => Event[];
}

const initialState = {
  search: '',
  eventType: 'all' as EventTypeFilter,
  status: 'all' as StatusFilter,
  category: null as string | null,
  sortBy: 'date_asc' as SortBy,
};

export const useFiltersStore = create<FiltersState>((set, get) => ({
  ...initialState,

  setSearch: (search) => set({ search }),
  setEventType: (eventType) => set({ eventType }),
  setStatus: (status) => set({ status }),
  setCategory: (category) => set({ category }),
  setSortBy: (sortBy) => set({ sortBy }),

  reset: () => set(initialState),

  applyFilters: (events) => {
    const { search, eventType, status, category, sortBy } = get();
    const query = search.trim().toLowerCase();

    let result = events.filter((e) => {
      if (query) {
        const inTitle = e.title.toLowerCase().includes(query);
        const inDesc = e.description?.toLowerCase().includes(query) ?? false;
        const inCat = e.category?.toLowerCase().includes(query) ?? false;
        if (!inTitle && !inDesc && !inCat) return false;
      }
      if (eventType !== 'all' && e.event_type !== eventType) return false;
      if (status === 'favorite' && !e.is_favorite) return false;
      if (category && e.category !== category) return false;
      return true;
    });

    result = [...result].sort((a, b) => {
      switch (sortBy) {
        case 'date_asc':
          return a.event_date - b.event_date;
        case 'date_desc':
          return b.event_date - a.event_date;
        case 'title':
          return a.title.localeCompare(b.title, 'ru');
        case 'created':
          return b.created_at - a.created_at;
        default:
          return 0;
      }
    });

    return result;
  },
}));