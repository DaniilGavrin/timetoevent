import { createFileRoute, useNavigate } from '@tanstack/react-router';
import { useEventsStore } from '../stores/eventsStore';
import { EventForm } from '../components/events/EventForm';
import { toast } from 'sonner';
import type { Event, NewEvent } from '../lib/tauri';

export const Route = createFileRoute('/events/new')({
  component: NewEventPage,
});

function NewEventPage() {
  const navigate = useNavigate();
  const { createEvent, fetchEvents } = useEventsStore();

  const handleSubmit = async (data: Event | NewEvent) => {
    const newEventData: NewEvent = {
      title: data.title,
      description: data.description ?? undefined,
      event_date: data.event_date,
      event_type: data.event_type as 'countdown' | 'countup',
      category: data.category ?? undefined,
      color: data.color ?? undefined,
    };

    await createEvent(newEventData);
    toast.success('Событие создано');
    await fetchEvents();
    navigate({ to: '/' });
  };

  return (
    <EventForm
      onSubmit={handleSubmit}
      onCancel={() => navigate({ to: '/' })}
      submitLabel="Создать событие"
      title="Новое событие"
    />
  );
}