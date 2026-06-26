import { ChevronLeft, ChevronRight, CalendarDays } from 'lucide-react';
import { MONTHS, type CalendarHeaderProps } from './types';

export function CalendarHeader({
  viewDate,
  onPrevMonth,
  onNextMonth,
  onToday,
}: CalendarHeaderProps) {
  const monthName = MONTHS[viewDate.getMonth()];
  const year = viewDate.getFullYear();

  return (
    <div className="flex items-center justify-between px-1 pb-2 border-b border-border/50">
      <button
        type="button"
        onClick={onPrevMonth}
        className="p-1.5 rounded-md hover:bg-secondary transition-colors text-muted-foreground hover:text-foreground"
        title="Предыдущий месяц"
      >
        <ChevronLeft className="w-4 h-4" />
      </button>

      <button
        type="button"
        onClick={onToday}
        className="flex items-center gap-1.5 px-2 py-1 rounded-md hover:bg-secondary transition-colors group"
        title="Перейти к сегодня"
      >
        <CalendarDays className="w-3.5 h-3.5 text-muted-foreground group-hover:text-primary transition-colors" />
        <span className="text-sm font-medium">
          {monthName} <span className="text-muted-foreground">{year}</span>
        </span>
      </button>

      <button
        type="button"
        onClick={onNextMonth}
        className="p-1.5 rounded-md hover:bg-secondary transition-colors text-muted-foreground hover:text-foreground"
        title="Следующий месяц"
      >
        <ChevronRight className="w-4 h-4" />
      </button>
    </div>
  );
}