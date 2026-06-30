import { createFileRoute } from '@tanstack/react-router';
import { motion, AnimatePresence, LayoutGroup } from 'framer-motion';
import { Star, Sparkles } from 'lucide-react';
import { useEffect } from 'react';
import { useEventsStore } from '../stores/eventsStore';
import { EventCard } from '../components/events/EventCard';
import { toast } from 'sonner';

export const Route = createFileRoute('/favorites')({
  component: FavoritesPage,
});

// === Варианты анимаций ===

const pageVariants = {
  initial: { opacity: 0, y: 24, scale: 0.98 },
  animate: {
    opacity: 1,
    y: 0,
    scale: 1,
    transition: {
      duration: 0.5,
      ease: [0.22, 1, 0.36, 1] as const,
    },
  },
  exit: {
    opacity: 0,
    y: -16,
    scale: 0.99,
    transition: { duration: 0.3, ease: [0.4, 0, 1, 1] as const },
  },
};

const headerVariants = {
  initial: { opacity: 0, x: -12 },
  animate: {
    opacity: 1,
    x: 0,
    transition: { duration: 0.4, delay: 0.05, ease: [0.22, 1, 0.36, 1] as const },
  },
};

const starVariants = {
  initial: { opacity: 0, scale: 0, rotate: -180 },
  animate: {
    opacity: 1,
    scale: 1,
    rotate: 0,
    transition: {
      type: 'spring',
      stiffness: 260,
      damping: 20,
      delay: 0.1,
    },
  },
} as const;

const emptyVariants = {
  initial: { opacity: 0, y: 20, scale: 0.95 },
  animate: {
    opacity: 1,
    y: 0,
    scale: 1,
    transition: {
      duration: 0.5,
      delay: 0.2,
      ease: [0.22, 1, 0.36, 1] as const,
    },
  },
};

const listVariants = {
  animate: {
    transition: {
      staggerChildren: 0.06,
      delayChildren: 0.15,
    },
  },
};

const cardVariants = {
  initial: { opacity: 0, y: 16, scale: 0.97 },
  animate: {
    opacity: 1,
    y: 0,
    scale: 1,
    transition: {
      duration: 0.4,
      ease: [0.22, 1, 0.36, 1] as const,
    },
  },
  exit: {
    opacity: 0,
    x: -40,
    scale: 0.9,
    transition: { duration: 0.25 },
  },
};

function FavoritesPage() {
  const { events, loading, fetchEvents, deleteEvent, toggleFavorite } =
    useEventsStore();

  useEffect(() => {
    fetchEvents();
  }, [fetchEvents]);

  const favorites = events.filter((e) => e.is_favorite);

  const handleDelete = async (id: string, title: string) => {
    if (confirm(`Удалить событие "${title}"?`)) {
      await deleteEvent(id);
      toast.success('Событие удалено');
    }
  };

  const handleToggleFavorite = async (id: string) => {
    await toggleFavorite(id);
  };

  return (
    <motion.main
      className="min-h-full overflow-y-auto"
      variants={pageVariants}
      initial="initial"
      animate="animate"
      exit="exit"
    >
      <div className="container mx-auto px-6 py-8 max-w-5xl">
        {/* Заголовок */}
        <motion.div
          className="mb-8 flex items-center gap-4"
          variants={headerVariants}
        >
          <motion.div
            className="w-12 h-12 rounded-xl bg-gradient-to-br from-yellow-500/20 to-amber-500/10 border border-yellow-500/20 flex items-center justify-center flex-shrink-0"
            variants={starVariants}
          >
            <Star className="w-6 h-6 text-yellow-400 fill-yellow-400" />
          </motion.div>
          <div>
            <motion.h1
              className="text-3xl font-bold"
              initial={{ opacity: 0, y: -8 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.4, delay: 0.15 }}
            >
              Избранное
            </motion.h1>
            <motion.p
              className="mt-1 text-muted-foreground"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ duration: 0.4, delay: 0.2 }}
            >
              {favorites.length > 0
                ? `${favorites.length} ${pluralize(favorites.length)} в избранном`
                : 'Здесь будут ваши любимые события'}
            </motion.p>
          </div>
        </motion.div>

        {/* Loading state */}
        {loading && events.length === 0 && (
          <motion.div
            className="flex items-center justify-center py-16"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
          >
            <div className="flex gap-2">
              {[0, 1, 2].map((i) => (
                <motion.div
                  key={i}
                  className="w-2.5 h-2.5 bg-yellow-400 rounded-full"
                  animate={{
                    scale: [1, 1.5, 1],
                    opacity: [0.3, 1, 0.3],
                  }}
                  transition={{
                    duration: 1,
                    repeat: Infinity,
                    delay: i * 0.2,
                  }}
                />
              ))}
            </div>
          </motion.div>
        )}

        {/* Empty state */}
        {!loading && favorites.length === 0 && (
          <motion.div
            className="flex flex-col items-center justify-center text-center py-20"
            variants={emptyVariants}
          >
            {/* Анимированная звезда */}
            <motion.div
              className="relative mb-6"
              animate={{
                rotate: [0, -5, 5, 0],
              }}
              transition={{
                duration: 4,
                repeat: Infinity,
                ease: 'easeInOut',
              }}
            >
              {/* Glow */}
              <motion.div
                className="absolute inset-0 bg-yellow-400/20 blur-3xl rounded-full"
                animate={{
                  scale: [1, 1.2, 1],
                  opacity: [0.3, 0.5, 0.3],
                }}
                transition={{
                  duration: 3,
                  repeat: Infinity,
                  ease: 'easeInOut',
                }}
              />
              <div className="relative w-24 h-24 rounded-2xl bg-gradient-to-br from-yellow-500/10 to-amber-500/5 border border-yellow-500/20 flex items-center justify-center">
                <Star className="w-12 h-12 text-yellow-400/40" strokeWidth={1.5} />
              </div>
            </motion.div>

            <motion.h2
              className="text-xl font-semibold mb-2"
              initial={{ opacity: 0, y: 8 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.3 }}
            >
              Пока пусто
            </motion.h2>
            <motion.p
              className="text-muted-foreground max-w-sm"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: 0.4 }}
            >
              Добавляйте события в избранное, чтобы они всегда были под рукой.
              Нажмите{' '}
              <Star className="inline w-4 h-4 text-yellow-400 fill-yellow-400 align-text-bottom" />{' '}
              на карточке события.
            </motion.p>

            {/* Декоративные искры */}
            <motion.div
              className="absolute pointer-events-none"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: 0.5 }}
            >
              {[...Array(5)].map((_, i) => (
                <motion.div
                  key={i}
                  className="absolute"
                  style={{
                    top: `${Math.sin((i / 5) * Math.PI * 2) * 80}px`,
                    left: `${Math.cos((i / 5) * Math.PI * 2) * 80}px`,
                  }}
                  animate={{
                    opacity: [0, 1, 0],
                    scale: [0, 1, 0],
                  }}
                  transition={{
                    duration: 2,
                    repeat: Infinity,
                    delay: i * 0.4,
                    ease: 'easeInOut',
                  }}
                >
                  <Sparkles className="w-3 h-3 text-yellow-400/60" />
                </motion.div>
              ))}
            </motion.div>
          </motion.div>
        )}

        {/* Список избранных */}
        {!loading && favorites.length > 0 && (
          <LayoutGroup>
            <motion.div
              className="grid gap-3"
              variants={listVariants}
              initial="initial"
              animate="animate"
            >
              <AnimatePresence mode="popLayout">
                {favorites.map((event) => (
                  <motion.div
                    key={event.id}
                    layout
                    variants={cardVariants}
                    initial="initial"
                    animate="animate"
                    exit="exit"
                  >
                    <EventCard
                      event={event}
                      onDelete={handleDelete}
                      onToggleFavorite={handleToggleFavorite}
                    />
                  </motion.div>
                ))}
              </AnimatePresence>
            </motion.div>
          </LayoutGroup>
        )}
      </div>
    </motion.main>
  );
}

// === Утилиты ===

function pluralize(count: number): string {
  const mod10 = count % 10;
  const mod100 = count % 100;

  if (mod10 === 1 && mod100 !== 11) return 'событие';
  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 10 || mod100 >= 20)) return 'события';
  return 'событий';
}