import { RotateCcw } from 'lucide-react';
import { useEventsStore } from '../../stores/eventsStore';
import { useFiltersStore } from '../../stores/filtersStore';
import { SearchInput } from '../filters/SearchInput';
import { FilterGroup } from '../filters/FilterGroup';
import { FilterChip } from '../filters/FilterChip';
import { SortSelector } from '../filters/SortSelector';
import { useMemo } from 'react';

export function RightPanel() {
  const events = useEventsStore((s) => s.events);
  const {
    search, setSearch,
    eventType, setEventType,
    status, setStatus,
    category, setCategory,
    sortBy, setSortBy,
    reset,
  } = useFiltersStore();

  // Считаем количество для каждой категории (динамически из событий)
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

  // Активны ли какие-то фильтры (для кнопки "Сбросить")
  const hasActiveFilters =
    search !== '' ||
    eventType !== 'all' ||
    status !== 'all' ||
    category !== null ||
    sortBy !== 'date_asc';

  return (
    <aside className="w-80 flex-shrink-0 border-l border-border bg-card flex flex-col">
      {/* Заголовок */}
      <div className="p-4 border-b border-border flex items-center justify-between">
        <h2 className="text-sm font-semibold uppercase tracking-wider text-foreground">
          Фильтры
        </h2>
        {hasActiveFilters && (
          <button
            onClick={reset}
            className="flex items-center gap-1 text-xs text-muted-foreground hover:text-foreground transition-colors"
            title="Сбросить все фильтры"
          >
            <RotateCcw className="w-3 h-3" />
            Сбросить
          </button>
        )}
      </div>

      {/* Контент */}
      <div className="flex-1 overflow-y-auto p-4 space-y-5">
        {/* Поиск */}
        <SearchInput value={search} onChange={setSearch} />

        {/* Тип события */}
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

        {/* Статус */}
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

        {/* Категории (только если есть) */}
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

        {/* Сортировка */}
        <SortSelector value={sortBy} onChange={setSortBy} />
      </div>
    </aside>
  );
}