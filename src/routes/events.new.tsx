import { createFileRoute, useNavigate } from '@tanstack/react-router';
import { useState } from 'react';
import { useEventsStore } from '../stores/eventsStore';
import { ArrowLeft } from 'lucide-react';
import { toast } from 'sonner';

export const Route = createFileRoute('/events/new')({
  component: NewEvent,
});

function NewEvent() {
  const navigate = useNavigate();
  const { createEvent, fetchEvents } = useEventsStore();
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [eventType, setEventType] = useState<'countdown' | 'countup'>('countdown');
  const [eventDate, setEventDate] = useState('');
  const [category, setCategory] = useState('');
  const [color, setColor] = useState('');
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    // Валидация
    if (!title.trim()) {
      toast.error('Название обязательно');
      return;
    }
    if (!eventDate) {
      toast.error('Дата и время обязательны');
      return;
    }

    // Парсим дату
    const dateObj = new Date(eventDate);
    if (isNaN(dateObj.getTime())) {
      toast.error('Неправильный формат даты');
      return;
    }

    const eventTimestamp = Math.floor(dateObj.getTime() / 1000);

    setLoading(true);
    try {
      await createEvent({
        title: title.trim(),
        description: description.trim() || undefined,
        event_type: eventType,
        event_date: eventTimestamp,
        category: category.trim() || undefined,
        color: color || undefined,
      });
      
      toast.success('Событие создано');
      
      // Обновляем список и переходим на главную
      await fetchEvents();
      navigate({ to: '/' });
    } catch (err) {
      toast.error(`Ошибка: ${String(err)}`);
    } finally {
      setLoading(false);
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

        <h1 className="text-3xl font-bold mb-8">Новое событие</h1>

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
                placeholder="Работа, Личное..."
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
            <button 
              type="submit" 
              disabled={loading} 
              className="btn-primary flex-1 disabled:opacity-50"
            >
              {loading ? 'Сохранение...' : 'Сохранить'}
            </button>
            <button
              type="button"
              onClick={() => navigate({ to: '/' })}
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