import { createFileRoute } from '@tanstack/react-router';
import { useEffect } from 'react';
import { useEventsStore } from '../stores/eventsStore';
import { formatDistanceToNow } from 'date-fns';
import { ru } from 'date-fns/locale';

export const Route = createFileRoute('/')({
  component: Index,
});

function Index() {
  const { events, loading, error, fetchEvents } = useEventsStore();
  
  useEffect(() => {
    fetchEvents();
  }, [fetchEvents]);
  
  return (
    <main className="min-h-screen p-8">
      <div className="max-w-4xl mx-auto">
        <h1 className="text-4xl font-bold mb-8">TimeToEvent</h1>
        
        {loading && <p>Загрузка...</p>}
        {error && <p className="text-destructive">Ошибка: {error}</p>}
        
        {events.length === 0 && !loading && (
          <p className="text-muted-foreground">Нет событий. Создайте первое событие!</p>
        )}
        
        <div className="grid gap-4">
          {events.map((event) => (
            <div key={event.id} className="card">
              <h2 className="text-xl font-semibold mb-2">{event.title}</h2>
              {event.description && (
                <p className="text-muted-foreground mb-2">{event.description}</p>
              )}
              <div className="flex justify-between items-center">
                <span className="text-sm text-muted-foreground">
                  {event.event_type === 'countdown' ? 'До события:' : 'Прошло:'}
                </span>
                <span className="text-lg font-mono font-bold text-primary">
                  {formatDistanceToNow(new Date(event.event_date * 1000), { 
                    addSuffix: event.event_type === 'countup',
                    locale: ru 
                  })}
                </span>
              </div>
              {event.category && (
                <span className="inline-block mt-2 px-2 py-1 text-xs bg-secondary rounded">
                  {event.category}
                </span>
              )}
            </div>
          ))}
        </div>
      </div>
    </main>
  );
}