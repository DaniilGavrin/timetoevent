import { createFileRoute, useNavigate, Link } from '@tanstack/react-router';
import { useEffect } from 'react';
import { useEventsStore } from '../stores/eventsStore';
import { useTimer } from '../hooks/useTimer';
import { ArrowLeft, Star, Trash2, Edit, Calendar } from 'lucide-react';

export const Route = createFileRoute('/events/$eventId')({
  component: EventDetail,
});

function EventDetail() {
  const { eventId } = Route.useParams();
  const navigate = useNavigate();
  const { events, deleteEvent, toggleFavorite } = useEventsStore();
  const event = events.find((e) => e.id === eventId);

  useEffect(() => {
    if (!event) {
      navigate({ to: '/' });
    }
  }, [event, navigate]);

  if (!event) return null;

  const timer = useTimer(event.event_date, event.event_type);

  const handleDelete = async () => {
    if (confirm(`Удалить событие "${event.title}"?`)) {
      await deleteEvent(event.id);
      navigate({ to: '/' });
    }
  };

  return (
    <main className="min-h-screen p-4 sm:p-8">
      <div className="max-w-2xl mx-auto">
        <button
          onClick={() => navigate({ to: '/' })}
          className="flex items-center gap-2 text-muted-foreground hover:text-foreground mb-6"
        >
          <ArrowLeft className="w-4 h-4" />
          Назад
        </button>

        <div className="card">
          <div className="flex justify-between items-start mb-4">
            <div className="flex items-center gap-2">
              <h1 className="text-3xl font-bold">{event.title}</h1>
              {event.is_favorite && (
                <Star className="w-6 h-6 fill-yellow-400 text-yellow-400" />
              )}
            </div>
            <div className="flex gap-2">
              <button
                onClick={() => toggleFavorite(event.id)}
                className="p-2 hover:bg-secondary rounded-lg transition-colors"
                title={event.is_favorite ? 'Убрать из избранного' : 'В избранное'}
              >
                <Star
                  className={`w-5 h-5 ${
                    event.is_favorite ? 'fill-yellow-400 text-yellow-400' : ''
                  }`}
                />
              </button>
              <Link
                to="/events/$eventId/edit"
                params={{ eventId: event.id }}
                className="p-2 hover:bg-secondary rounded-lg transition-colors"
                title="Редактировать"
              >
                <Edit className="w-5 h-5" />
              </Link>
              <button
                onClick={handleDelete}
                className="p-2 hover:bg-destructive/10 text-destructive rounded-lg transition-colors"
                title="Удалить"
              >
                <Trash2 className="w-5 h-5" />
              </button>
            </div>
          </div>

          {event.description && (
            <p className="text-muted-foreground mb-6">{event.description}</p>
          )}

          <div className="text-center py-8">
            <div className="text-sm text-muted-foreground mb-2">
              {event.event_type === 'countdown' ? 'До события:' : 'Прошло:'}
            </div>
            <div
              className={`text-5xl font-mono font-bold ${
                timer.isPast ? 'text-destructive' : 'text-primary'
              }`}
            >
              {timer.formatted}
            </div>
          </div>

          <div className="flex items-center gap-4 flex-wrap text-sm text-muted-foreground border-t border-border pt-4">
            <div className="flex items-center gap-1">
              <Calendar className="w-4 h-4" />
              {new Date(event.event_date * 1000).toLocaleString('ru-RU')}
            </div>
            {event.category && (
              <span className="px-2 py-1 bg-secondary rounded text-xs">
                {event.category}
              </span>
            )}
          </div>
        </div>
      </div>
    </main>
  );
}