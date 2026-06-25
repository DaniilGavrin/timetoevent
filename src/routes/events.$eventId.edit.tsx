import { createFileRoute, useNavigate } from '@tanstack/react-router';
import { useEffect, useState } from 'react';
import { useEventsStore } from '../stores/eventsStore';
import { ArrowLeft } from 'lucide-react';

export const Route = createFileRoute('/events/$eventId/edit')({
  component: EditEvent,
});

function EditEvent() {
  const { eventId } = Route.useParams();
  const navigate = useNavigate();
  const { events, updateEvent } = useEventsStore();
  const event = events.find((e) => e.id === eventId);

  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [eventType, setEventType] = useState<'countdown' | 'countup'>('countdown');
  const [eventDate, setEventDate] = useState('');
  const [category, setCategory] = useState('');
  const [color, setColor] = useState('');
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (!event) {
      navigate({ to: '/' });
      return;
    }
    setTitle(event.title);
    setDescription(event.description || '');
    setEventType(event.event_type);
    setEventDate(
      new Date(event.event_date * 1000).toISOString().slice(0, 16),
    );
    setCategory(event.category || '');
    setColor(event.color || '');
  }, [event, navigate]);

  if (!event) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title || !eventDate) return;

    setLoading(true);
    try {
      await updateEvent({
        ...event,
        title,
        description: description || null,
        event_type: eventType,
        event_date: Math.floor(new Date(eventDate).getTime() / 1000),
        category: category || null,
        color: color || null,
        updated_at: Math.floor(Date.now() / 1000),
      });
      navigate({ to: '/events/$eventId', params: { eventId } });
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <main className="min-h-screen p-4 sm:p-8">
      <div className="max-w-2xl mx-auto">
        <button
          onClick={() => navigate({ to: '/events/$eventId', params: { eventId } })}
          className="flex items-center gap-2 text-muted-foreground hover:text-foreground mb-6"
        >
          <ArrowLeft className="w-4 h-4" />
          Назад
        </button>

        <h1 className="text-3xl font-bold mb-8">Редактировать событие</h1>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-sm font-medium mb-1">Название *</label>
            <input
              type="text"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              className="w-full px-3 py-2 bg-secondary rounded-lg border border-border"
              required
            />
          </div>

          <div>
            <label className="block text-sm font-medium mb-1">Описание</label>
            <textarea
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              className="w-full px-3 py-2 bg-secondary rounded-lg border border-border"
              rows={3}
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium mb-1">Тип</label>
              <select
                value={eventType}
                onChange={(e) => setEventType(e.target.value as 'countdown' | 'countup')}
                className="w-full px-3 py-2 bg-secondary rounded-lg border border-border"
              >
                <option value="countdown">До события</option>
                <option value="countup">С события</option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium mb-1">Дата и время *</label>
              <input
                type="datetime-local"
                value={eventDate}
                onChange={(e) => setEventDate(e.target.value)}
                className="w-full px-3 py-2 bg-secondary rounded-lg border border-border"
                required
              />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium mb-1">Категория</label>
              <input
                type="text"
                value={category}
                onChange={(e) => setCategory(e.target.value)}
                className="w-full px-3 py-2 bg-secondary rounded-lg border border-border"
              />
            </div>
            <div>
              <label className="block text-sm font-medium mb-1">Цвет</label>
              <input
                type="color"
                value={color}
                onChange={(e) => setColor(e.target.value)}
                className="w-full h-10 bg-secondary rounded-lg border border-border"
              />
            </div>
          </div>

          <div className="flex gap-3 pt-4">
            <button type="submit" disabled={loading} className="btn-primary flex-1">
              {loading ? 'Сохранение...' : 'Сохранить'}
            </button>
            <button
              type="button"
              onClick={() => navigate({ to: '/events/$eventId', params: { eventId } })}
              className="btn-secondary"
            >
              Отмена
            </button>
          </div>
        </form>
      </div>
    </main>
  );
}