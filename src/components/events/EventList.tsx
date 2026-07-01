import { useEffect } from 'react';
import { useEventsStore } from '../../stores/eventsStore';
import { useFiltersStore } from '../../stores/filtersStore';
import { EventCard } from './EventCard';
import { Calendar, Search } from 'lucide-react';
import { useShallow } from 'zustand/react/shallow';

export function EventList() {
  const { events, loading, error, fetchEvents, deleteEvent, toggleFavorite } =
    useEventsStore();
  const { applyFilters } = useFiltersStore(
    useShallow((s) => ({
      search: s.search,
      eventType: s.eventType,
      status: s.status,
      category: s.category,
      sortBy: s.sortBy,
      applyFilters: s.applyFilters,
    }))
  );

  useEffect(() => {
    fetchEvents();
  }, [fetchEvents]);

  const handleDelete = async (id: string, title: string) => {
    if (confirm(`Удалить событие "${title}"?`)) {
      await deleteEvent(id);
    }
  };

  // Применяем фильтры
  const filteredEvents = applyFilters(events);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-full">
        <p className="text-muted-foreground">Загрузка...</p>
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex items-center justify-center h-full">
        <p className="text-destructive">Ошибка: {error}</p>
      </div>
    );
  }

  // Empty state — разный для "нет событий вообще" и "ничего не найдено"
  if (events.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center h-full text-center py-16">
        <Calendar className="w-16 h-16 text-muted-foreground mb-4 opacity-50" />
        <p className="text-muted-foreground text-lg">Нет событий</p>
        <p className="text-muted-foreground text-sm mt-2">
          Создайте первое событие, чтобы начать
        </p>
      </div>
    );
  }

  if (filteredEvents.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center h-full text-center py-16">
        <Search className="w-16 h-16 text-muted-foreground mb-4 opacity-50" />
        <p className="text-muted-foreground text-lg">Ничего не найдено</p>
        <p className="text-muted-foreground text-sm mt-2">
          Попробуйте изменить фильтры
        </p>
      </div>
    );
  }

  return (
    <div className="p-3 md:p-6 pb-safe-bottom overflow-y-auto">
      <div className="grid gap-3">
        {filteredEvents.map((event) => (
          <EventCard
            key={event.id}
            event={event}
            onDelete={handleDelete}
            onToggleFavorite={toggleFavorite}
          />
        ))}
      </div>
    </div>
  );
}