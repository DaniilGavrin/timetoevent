import { createFileRoute, useNavigate } from '@tanstack/react-router';
import { useEffect } from 'react';
import { motion } from 'framer-motion';
import { useEventsStore } from '../stores/eventsStore';
import { useTimer } from '../hooks/useTimer';
import { Calendar, X } from 'lucide-react';

export const Route = createFileRoute('/events/$eventId')({
  component: EventDetail,
});

function EventDetail() {
  const { eventId } = Route.useParams();
  const navigate = useNavigate();
  const { events, deleteEvent } = useEventsStore();
  const event = events.find((e) => e.id === eventId);

  useEffect(() => {
    if (!event) {
      navigate({ to: '/' });
    }
  }, [event, navigate]);

  if (!event) return null;

  const timer = useTimer(event.event_date, event.event_type, event.created_at);

  return (
    <motion.main
      className="h-full flex flex-col p-4 sm:p-8"
      initial={{ opacity: 0, y: 24, scale: 0.98 }}
      animate={{ opacity: 1, y: 0, scale: 1 }}
      exit={{ opacity: 0, y: 16, scale: 0.99 }}
      transition={{
        duration: 0.45,
        ease: [0.22, 1, 0.36, 1], // плавный easeOut-quint
      }}
    >
      {/* Карточка на весь экран */}
      <motion.div
        className="card flex-1 flex flex-col overflow-hidden"
        initial={{ opacity: 0, y: 12 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5, delay: 0.08, ease: [0.22, 1, 0.36, 1] }}
      >
        {/* Верхняя часть: заголовок по центру + крестик справа */}
        <div className="flex items-center justify-between px-6 py-4 border-b border-border">
          <div className="w-10"></div>

          <motion.h1
            className="text-4xl font-bold truncate text-center flex-1"
            initial={{ opacity: 0, y: -8 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.4, delay: 0.15 }}
          >
            {event.title}
          </motion.h1>

          <motion.button
            onClick={() => navigate({ to: '/' })}
            className="p-2 hover:bg-secondary rounded-lg transition-colors flex-shrink-0"
            title="Закрыть"
            initial={{ opacity: 0, scale: 0.8 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ duration: 0.3, delay: 0.25 }}
            whileHover={{ scale: 1.08 }}
            whileTap={{ scale: 0.95 }}
          >
            <X className="w-6 h-6" />
          </motion.button>
        </div>

        {/* Центр: таймер + progress bar */}
        <div className="flex-1 flex flex-col items-center justify-center px-6 py-8 overflow-y-auto">
          {event.description && (
            <motion.p
              className="text-muted-foreground mb-8 text-center text-xl max-w-3xl"
              initial={{ opacity: 0, y: 8 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.4, delay: 0.2 }}
            >
              {event.description}
            </motion.p>
          )}

          {/* Таймер */}
          <motion.div
            className="text-center"
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ duration: 0.5, delay: 0.25, ease: [0.22, 1, 0.36, 1] }}
          >
            <div className="text-lg text-muted-foreground mb-4 uppercase tracking-wider font-medium">
              {timer.isPast && event.event_type === 'countdown'
                ? 'Прошло событие'
                : event.event_type === 'countdown'
                ? 'До события'
                : 'Прошло'}
            </div>
            <div
              className={`text-7xl sm:text-8xl lg:text-9xl font-mono font-bold tracking-wide ${
                timer.isPast
                  ? 'text-destructive drop-shadow-[0_0_20px_rgba(239,68,68,0.6)]'
                  : 'text-foreground'
              }`}
            >
              {timer.formatted}
            </div>
          </motion.div>

          {/* Progress bar — только для countdown */}
          {event.event_type === 'countdown' && (
            <motion.div
              className="mt-10 w-full max-w-4xl space-y-3"
              initial={{ opacity: 0, y: 12 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5, delay: 0.35 }}
            >
              <div className="relative h-4 bg-secondary rounded-full overflow-hidden">
                <motion.div
                  className="absolute inset-y-0 left-0 rounded-full"
                  initial={{ width: 0 }}
                  animate={{ width: `${timer.progress}%` }}
                  transition={{
                    duration: 0.8,
                    delay: 0.5,
                    ease: [0.22, 1, 0.36, 1],
                  }}
                  style={{
                    background: timer.isPast
                      ? 'linear-gradient(90deg, #ef4444 0%, #dc2626 100%)'
                      : `linear-gradient(90deg, ${event.color || '#3b82f6'} 0%, ${event.color || '#3b82f6'}cc 100%)`,
                    boxShadow: timer.isPast
                      ? '0 0 16px rgba(239, 68, 68, 0.6)'
                      : `0 0 16px ${event.color || '#3b82f6'}88`,
                  }}
                />
                <div
                  className="absolute inset-x-0 top-0 h-1/2 rounded-full pointer-events-none"
                  style={{
                    background:
                      'linear-gradient(180deg, rgba(255,255,255,0.25) 0%, transparent 100%)',
                  }}
                />
              </div>
              <div className="flex justify-between text-lg">
                <span className="text-muted-foreground font-medium">Прогресс</span>
                <span className="font-mono font-bold text-foreground text-xl">
                  {timer.progress.toFixed(1)}%
                </span>
              </div>
            </motion.div>
          )}
        </div>

        {/* Нижняя часть: мета-инфа */}
        <motion.div
          className="flex items-center justify-center gap-4 flex-wrap text-base text-muted-foreground border-t border-border px-6 py-4"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ duration: 0.4, delay: 0.4 }}
        >
          <div className="flex items-center gap-2">
            <Calendar className="w-5 h-5" />
            {new Date(event.event_date * 1000).toLocaleString('ru-RU')}
          </div>
          {event.category && (
            <span className="px-3 py-1.5 bg-secondary rounded text-sm font-medium">
              {event.category}
            </span>
          )}
        </motion.div>
      </motion.div>
    </motion.main>
  );
}