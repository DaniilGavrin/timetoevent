import { dateUtils, WEEKDAYS, type CalendarProps } from './types';
import { CalendarHeader } from './CalendarHeader';

export function Calendar({
  value,
  onChange,
  minDate,
  maxDate,
  viewDate,
  onViewDateChange,
}: CalendarProps) {
  const grid = dateUtils.getCalendarGrid(viewDate);
  const currentMonth = viewDate.getMonth();

  const handlePrevMonth = () => {
    const prev = dateUtils.addMonths(viewDate, -1);
    if (minDate) {
      const prevEnd = dateUtils.endOfMonth(prev);
      if (prevEnd.getTime() < dateUtils.startOfDay(minDate).getTime()) {
        return; // нельзя
      }
    }
    onViewDateChange(prev);
  };

  const handleNextMonth = () => {
    const next = dateUtils.addMonths(viewDate, 1);
    if (maxDate) {
      const nextStart = dateUtils.startOfMonth(next);
      if (nextStart.getTime() > dateUtils.endOfDay(maxDate).getTime()) {
        return; // нельзя
      }
    }
    onViewDateChange(next);
  };
  
  const handleToday = () => {
    const today = new Date();
    onViewDateChange(today);
    if (dateUtils.isDateInRange(today, minDate, maxDate)) {
      const selected = new Date(today);
      if (value) {
        selected.setHours(value.getHours(), value.getMinutes());
      }
      onChange(selected);
    }
  };

  const handleDayClick = (day: Date) => {
    if (!dateUtils.isDateInRange(day, minDate, maxDate)) return;
    const selected = new Date(day);
    if (value) {
      selected.setHours(value.getHours(), value.getMinutes(), value.getSeconds());
    }
    onChange(selected);
  };

  return (
    <div className="space-y-2">
      <CalendarHeader
        viewDate={viewDate}
        onPrevMonth={handlePrevMonth}
        onNextMonth={handleNextMonth}
        onToday={handleToday}
      />

      {/* Дни недели */}
      <div className="grid grid-cols-7 gap-1">
        {WEEKDAYS.map((day) => (
          <div
            key={day}
            className="text-center text-xs font-medium text-muted-foreground py-1"
          >
            {day}
          </div>
        ))}
      </div>

      {/* Сетка дней */}
      <div className="grid grid-cols-7 gap-1">
        {grid.map((day, idx) => {
          const isCurrentMonth = day.getMonth() === currentMonth;
          const isSelected = value && dateUtils.isSameDay(day, value);
          const isToday = dateUtils.isToday(day);
          const isInRange = dateUtils.isDateInRange(day, minDate, maxDate);
          const isWeekend = day.getDay() === 0 || day.getDay() === 6;

          return (
            <button
              key={idx}
              type="button"
              onClick={() => handleDayClick(day)}
              disabled={!isInRange}
              className={`
                relative aspect-square rounded-md text-sm font-medium transition-all
                ${!isCurrentMonth ? 'text-muted-foreground/40' : ''}
                ${isWeekend && isCurrentMonth ? 'text-destructive/70' : ''}
                ${!isInRange ? 'opacity-30 cursor-not-allowed' : 'cursor-pointer hover:bg-secondary'}
                ${isSelected
                  ? 'text-primary-foreground'
                  : isToday && isCurrentMonth
                    ? 'text-primary'
                    : ''}
              `}
              style={
                isSelected
                  ? {
                      background: 'linear-gradient(180deg, #d4d8e0 0%, #8a8f97 100%)',
                      color: '#0a0a0c',
                      boxShadow:
                        'inset 0 1px 0 rgba(255,255,255,0.4), 0 2px 4px rgba(0,0,0,0.4)',
                    }
                  : isToday && isCurrentMonth
                    ? {
                        boxShadow: 'inset 0 0 0 1px var(--primary)',
                      }
                    : undefined
              }
            >
              {day.getDate()}
              {/* Блик для выбранного */}
              {isSelected && (
                <div
                  className="absolute inset-x-0 top-0 h-1/2 rounded-t-md pointer-events-none"
                  style={{
                    background:
                      'linear-gradient(180deg, rgba(255,255,255,0.25) 0%, transparent 100%)',
                  }}
                />
              )}
            </button>
          );
        })}
      </div>
    </div>
  );
}