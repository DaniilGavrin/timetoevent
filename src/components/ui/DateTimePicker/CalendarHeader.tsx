import { ChevronLeft, ChevronRight, CalendarDays } from 'lucide-react';
import { MONTHS, type CalendarHeaderProps } from './types';

export function CalendarHeader({
  viewDate,
  onPrevMonth,
  onNextMonth,
  onToday,
  onViewDateChange,
  canGoPrev = true,
  canGoNext = true,
}: CalendarHeaderProps) {
  const monthName = MONTHS[viewDate.getMonth()];
  const year = viewDate.getFullYear();

  // Диапазон 1900–2100 — покрывает 99% сценариев
  const years = Array.from({ length: 201 }, (_, i) => 1900 + i);

  const handleYearChange = (newYear: number) => {
    const newDate = new Date(viewDate);
    newDate.setFullYear(newYear);
    // Если в новом году текущий месяц/день выходит за min/max —
    // Calendar сам это обработает через isDateInRange
    onViewDateChange(newDate);
  };

  return (
    <div className="flex items-center justify-between px-1 pb-2 border-b border-border/50">
      <button
        type="button"
        onClick={onPrevMonth}
        disabled={!canGoPrev}
        className={`p-1.5 rounded-md transition-colors ${
          canGoPrev
            ? 'hover:bg-secondary text-muted-foreground hover:text-foreground'
            : 'opacity-30 cursor-not-allowed text-muted-foreground'
        }`}
        title="Предыдущий месяц"
      >
        <ChevronLeft className="w-4 h-4" />
      </button>

      <div className="flex items-center gap-2">
        <button
          type="button"
          onClick={onToday}
          className="flex items-center gap-1.5 px-2 py-1 rounded-md hover:bg-secondary transition-colors group"
          title="Перейти к сегодня"
        >
          <CalendarDays className="w-3.5 h-3.5 text-muted-foreground group-hover:text-primary transition-colors" />
          <span className="text-sm font-medium">{monthName}</span>
        </button>

        {/* 🔥 Выбор года — мгновенный прыжок без листания */}
        <select
          value={year}
          onChange={(e) => handleYearChange(Number(e.target.value))}
          className="px-2 py-1 text-sm font-medium bg-secondary rounded-md border border-border hover:border-primary/50 focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary/30 transition-colors cursor-pointer"
          title="Выберите год"
        >
          {years.map((y) => (
            <option key={y} value={y}>
              {y}
            </option>
          ))}
        </select>
      </div>

      <button
        type="button"
        onClick={onNextMonth}
        disabled={!canGoNext}
        className={`p-1.5 rounded-md transition-colors ${
          canGoNext
            ? 'hover:bg-secondary text-muted-foreground hover:text-foreground'
            : 'opacity-30 cursor-not-allowed text-muted-foreground'
        }`}
        title="Следующий месяц"
      >
        <ChevronRight className="w-4 h-4" />
      </button>
    </div>
  );
}