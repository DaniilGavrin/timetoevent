import { createFileRoute } from '@tanstack/react-router';
import { EventList } from '../components/events/EventList';

export const Route = createFileRoute('/')({
  component: Index,
});

function Index() {
  return <EventList />;
}