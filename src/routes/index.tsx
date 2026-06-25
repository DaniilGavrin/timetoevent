import { createFileRoute, Link } from '@tanstack/react-router';
import { useEffect } from 'react';
import { useEventsStore } from '../stores/eventsStore';
import { useTimer } from '../hooks/useTimer';
import { Star, Trash2, Edit, Calendar } from 'lucide-react';

export const Route = createFileRoute('/')({
  component: Index,
});

function Index() {
  const { events, loading, error, fetchEvents, deleteEvent, toggleFavorite } =
    useEventsStore();

  useEffect(() => {
    fetchEvents();
  }, [fetchEvents]);

  const handleDelete = async (id: string, title: string) => {
    if (confirm(`Удалить событие "${title}"?`)) {
      await deleteEvent(id);
    }
  };

  return (
    <main className="min-h-screen p-4 sm:p-8">
      <div className="max-w-4xl mx-auto">
        <div className="flex justify-between items-center mb-8">
          <h1 className="text-3xl sm:text-4xl font-bold">TimeToEvent</h1>
          <Link to="/events/new" className="btn-primary">
            + Создать
          </Link>
        </div>

        {loading && <p className="text-muted-foreground">Загрузка...</p>}
        {error && <p className="text-destructive">Ошибка: {error}</p>}

        {events.length === 0 && !loading && (
          <div className="text-center py-16">
            <Calendar className="w-16 h-16 mx-auto text-muted-foreground mb-4" />
            <p className="text-muted-foreground text-lg">Нет событий</p>
            <p className="text-muted-foreground text-sm mt-2">
              Создайте первое событие, чтобы начать
            </p>
          </div>
        )}

        <div className="grid gap-3">
          {events.map((event) => (
            <EventCard
              key={event.id}
              event={event}
              onDelete={handleDelete}
              onToggleFavorite={toggleFavorite}
            />
          ))}
        </div>
      </div>
    </main>
  );
}

interface EventCardProps {
  event: import('../lib/tauri').Event;
  onDelete: (id: string, title: string) => void;
  onToggleFavorite: (id: string) => void;
}

function EventCard({ event, onDelete, onToggleFavorite }: EventCardProps) {
  const timer = useTimer(event.event_date, event.event_type);

  return (
    <div className="card group hover:border-primary/50 transition-colors">
      <div className="flex justify-between items-start gap-4">
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2 mb-1">
            <Link
              to="/events/$eventId"
              params={{ eventId: event.id }}
              className="text-lg font-semibold hover:text-primary transition-colors truncate"
            >
              {event.title}
            </Link>
            {event.is_favorite && (
              <Star className="w-4 h-4 fill-yellow-400 text-yellow-400 flex-shrink-0" />
            )}
          </div>

          {event.description && (
            <p className="text-muted-foreground text-sm mb-2 line-clamp-2">
              {event.description}
            </p>
          )}

          <div className="flex items-center gap-3 flex-wrap">
            <span className="text-sm text-muted-foreground">
              {event.event_type === 'countdown' ? 'До события:' : 'Прошло:'}
            </span>
            <span
              className={`text-xl font-mono font-bold ${
                timer.isPast ? 'text-destructive' : 'text-primary'
              }`}
            >
              {timer.formatted}
            </span>
          </div>

          <div className="flex items-center gap-2 mt-3 flex-wrap">
            {event.category && (
              <span className="inline-flex items-center px-2 py-0.5 text-xs bg-secondary rounded">
                {event.category}
              </span>
            )}
            <span className="text-xs text-muted-foreground">
              {new Date(event.event_date * 1000).toLocaleDateString('ru-RU')}
            </span>
          </div>
        </div>

        <div className="flex flex-col gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
          <button
            onClick={() => onToggleFavorite(event.id)}
            className="p-1.5 hover:bg-secondary rounded transition-colors"
            title={event.is_favorite ? 'Убрать из избранного' : 'В избранное'}
          >
            <Star
              className={`w-4 h-4 ${
                event.is_favorite ? 'fill-yellow-400 text-yellow-400' : ''
              }`}
            />
          </button>
          <Link
            to="/events/$eventId/edit"
            params={{ eventId: event.id }}
            className="p-1.5 hover:bg-secondary rounded transition-colors"
            title="Редактировать"
          >
            <Edit className="w-4 h-4" />
          </Link>
          <button
            onClick={() => onDelete(event.id, event.title)}
            className="p-1.5 hover:bg-destructive/10 text-destructive rounded transition-colors"
            title="Удалить"
          >
            <Trash2 className="w-4 h-4" />
          </button>
        </div>
      </div>
    </div>
  );
}