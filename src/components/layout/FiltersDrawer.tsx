import { motion, AnimatePresence } from 'framer-motion';
import { X, RotateCcw } from 'lucide-react';
import { useEventsStore } from '../../stores/eventsStore';
import { useFiltersStore } from '../../stores/filtersStore';
import { SearchInput } from '../filters/SearchInput';
import { FilterGroup } from '../filters/FilterGroup';
import { FilterChip } from '../filters/FilterChip';
import { SortSelector } from '../filters/SortSelector';
import { useMemo } from 'react';

interface FiltersDrawerProps {
  isOpen: boolean;
  onClose: () => void;
}

export function FiltersDrawer({ isOpen, onClose }: FiltersDrawerProps) {
  const events = useEventsStore((s) => s.events);
  const {
    search, setSearch,
    eventType, setEventType,
    status, setStatus,
    category, setCategory,
    sortBy, setSortBy,
    reset,
  } = useFiltersStore();

  const categories = useMemo(() => {
    const map = new Map<string, number>();
    for (const e of events) {
      if (e.category) {
        map.set(e.category, (map.get(e.category) ?? 0) + 1);
      }
    }
    return Array.from(map.entries())
      .sort((a, b) => b[1] - a[1])
      .map(([name, count]) => ({ name, count }));
  }, [events]);

  const hasActiveFilters =
    search !== '' ||
    eventType !== 'all' ||
    status !== 'all' ||
    category !== null ||
    sortBy !== 'date_asc';

  return (
    <AnimatePresence>
      {isOpen && (
        <>
          {/* Backdrop */}
          <motion.div
            className="fixed inset-0 bg-black/60 backdrop-blur-sm z-50 md:hidden"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={onClose}
          />

          {/* Drawer */}
          <motion.aside
            className="fixed top-0 right-0 bottom-0 w-[85%] max-w-sm z-50 md:hidden bg-card border-l border-border flex flex-col shadow-2xl"
            initial={{ x: '100%' }}
            animate={{ x: 0 }}
            exit={{ x: '100%' }}
            transition={{ type: 'spring', stiffness: 300, damping: 35 }}
          >
            {/* Header */}
            <div className="p-4 border-b border-border flex items-center justify-between flex-shrink-0">
              <h2 className="text-lg font-semibold">Фильтры</h2>
              <div className="flex items-center gap-2">
                {hasActiveFilters && (
                  <button
                    onClick={reset}
                    className="flex items-center gap-1 text-xs text-muted-foreground hover:text-foreground transition-colors px-2 py-1 rounded"
                  >
                    <RotateCcw className="w-3 h-3" />
                    Сбросить
                  </button>
                )}
                <button
                  onClick={onClose}
                  className="p-2 hover:bg-secondary rounded-lg transition-colors"
                >
                  <X className="w-5 h-5" />
                </button>
              </div>
            </div>

            {/* Content */}
            <div className="flex-1 overflow-y-auto p-4 space-y-5">
              <SearchInput value={search} onChange={setSearch} />

              <FilterGroup title="Тип">
                <FilterChip
                  label="Все"
                  active={eventType === 'all'}
                  count={events.length}
                  onClick={() => setEventType('all')}
                />
                <FilterChip
                  label="До события"
                  active={eventType === 'countdown'}
                  count={events.filter((e) => e.event_type === 'countdown').length}
                  onClick={() => setEventType('countdown')}
                />
                <FilterChip
                  label="С события"
                  active={eventType === 'countup'}
                  count={events.filter((e) => e.event_type === 'countup').length}
                  onClick={() => setEventType('countup')}
                />
              </FilterGroup>

              <FilterGroup title="Статус">
                <FilterChip
                  label="Все"
                  active={status === 'all'}
                  onClick={() => setStatus('all')}
                />
                <FilterChip
                  label="Избранные"
                  active={status === 'favorite'}
                  count={events.filter((e) => e.is_favorite).length}
                  onClick={() => setStatus('favorite')}
                />
              </FilterGroup>

              {categories.length > 0 && (
                <FilterGroup title="Категория">
                  <FilterChip
                    label="Все"
                    active={category === null}
                    onClick={() => setCategory(null)}
                  />
                  {categories.map(({ name, count }) => (
                    <FilterChip
                      key={name}
                      label={name}
                      active={category === name}
                      count={count}
                      onClick={() => setCategory(category === name ? null : name)}
                    />
                  ))}
                </FilterGroup>
              )}

              <SortSelector value={sortBy} onChange={setSortBy} />
            </div>
          </motion.aside>
        </>
      )}
    </AnimatePresence>
  );
}