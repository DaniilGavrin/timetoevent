import { createFileRoute, useNavigate } from '@tanstack/react-router';
import { useEffect } from 'react';
import { motion } from 'framer-motion';
import { useEventsStore } from '../stores/eventsStore';
import { EventForm } from '../components/events/EventForm';
import { toast } from 'sonner';
import { Edit } from 'lucide-react';
import type { Event, NewEvent } from '../lib/tauri';

export const Route = createFileRoute('/events/$eventId/edit')({
  component: EditEvent,
});

function EditEvent() {
  const { eventId } = Route.useParams();
  const navigate = useNavigate();
  const { events, updateEvent, fetchEvents } = useEventsStore();

  const event = events.find((e) => e.id === eventId);

  // Если событие не найдено — редирект на главную
  useEffect(() => {
    if (!event && events.length > 0) {
      toast.error('Событие не найдено');
      navigate({ to: '/' });
    }
  }, [event, events.length, navigate]);

  // Если ещё грузим — показываем skeleton
  if (!event) {
    return (
      <motion.main
        className="min-h-full flex items-center justify-center"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0 }}
      >
        <div className="flex flex-col items-center gap-4">
          <motion.div
            className="w-12 h-12 rounded-xl bg-secondary flex items-center justify-center"
            animate={{
              scale: [1, 1.1, 1],
              opacity: [0.5, 1, 0.5],
            }}
            transition={{ duration: 1.5, repeat: Infinity }}
          >
            <Edit className="w-6 h-6 text-muted-foreground" />
          </motion.div>
          <p className="text-muted-foreground">Загрузка события...</p>
        </div>
      </motion.main>
    );
  }

  const handleSubmit = async (data: Event | NewEvent) => {
    await updateEvent(data as Event);
    toast.success('Событие обновлено');
    await fetchEvents();
    navigate({ to: '/', params: { eventId: event.id } });
  };

  return (
    <EventForm
      initialData={event}
      onSubmit={handleSubmit}
      onCancel={() => navigate({ to: '/', params: { eventId: event.id } })}
      submitLabel="Сохранить изменения"
      title="Редактирование события"
    />
  );
}