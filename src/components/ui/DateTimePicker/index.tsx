import { useState } from 'react';
import { Calendar as CalendarIcon } from 'lucide-react';
import { Calendar } from './Calendar';
import { TimeSelector } from './TimeSelector';
import { dateUtils, type DateTimePickerProps } from './types';

export function DateTimePicker({
  value,
  onChange,
  label,
  error,
  disabled,
  minDate,
  maxDate,
  placeholder = 'Выберите дату и время',
}: DateTimePickerProps) {
  const [isOpen, setIsOpen] = useState(false);
  const [viewDate, setViewDate] = useState(value || new Date());

  const handleDateChange = (date: Date) => {
    onChange(date);
    // Не закрываем сразу — пусть пользователь выберет время
  };

  const handleClear = () => {
    onChange(new Date());
    setIsOpen(false);
  };

  return (
    <div className={`space-y-2 ${disabled ? 'opacity-50 pointer-events-none' : ''}`}>
      {label && (
        <label className="text-sm font-medium text-foreground">{label}</label>
      )}

      {/* Trigger — кнопка открытия */}
      <button
        type="button"
        onClick={() => setIsOpen(!isOpen)}
        disabled={disabled}
        className={`
          w-full flex items-center justify-between gap-2 px-3 py-2
          bg-secondary rounded-lg border transition-colors
          ${error ? 'border-destructive' : 'border-border hover:border-primary/50'}
          ${isOpen ? 'border-primary ring-1 ring-primary/30' : ''}
        `}
        style={{
          boxShadow: isOpen
            ? 'inset 0 1px 0 rgba(255,255,255,0.04), 0 2px 8px rgba(0,0,0,0.3)'
            : 'inset 0 1px 0 rgba(255,255,255,0.04)',
        }}
      >
        <div className="flex items-center gap-2 flex-1 min-w-0">
          <CalendarIcon className="w-4 h-4 text-muted-foreground flex-shrink-0" />
          <span className={`text-sm truncate ${value ? 'text-foreground' : 'text-muted-foreground'}`}>
            {value ? dateUtils.formatDisplay(value) : placeholder}
          </span>
        </div>
        {value && (
          <span
            onClick={(e) => {
              e.stopPropagation();
              handleClear();
            }}
            className="text-xs text-muted-foreground hover:text-destructive cursor-pointer px-1"
            title="Очистить"
          >
            ✕
          </span>
        )}
      </button>

      {/* Dropdown */}
      {isOpen && (
        <div
          className="rounded-lg border border-border p-3 space-y-3 mt-1"
          style={{
            backgroundColor: 'var(--card)',
            boxShadow:
              'inset 0 1px 0 rgba(255,255,255,0.04), 0 8px 24px rgba(0,0,0,0.5)',
          }}
        >
          <Calendar
            value={value}
            onChange={handleDateChange}
            minDate={minDate}
            maxDate={maxDate}
            viewDate={viewDate}
            onViewDateChange={setViewDate}
          />

          <div className="border-t border-border/50 pt-3">
            <TimeSelector value={value} onChange={handleDateChange} />
          </div>

          {/* Превью выбранной даты */}
          {value && (
            <div className="text-center pt-2 border-t border-border/50">
              <span className="text-xs text-muted-foreground">Выбрано: </span>
              <span className="text-sm font-medium text-foreground">
                {dateUtils.formatDisplay(value)}
              </span>
            </div>
          )}
        </div>
      )}

      {error && (
        <p className="text-xs text-destructive">{error}</p>
      )}
    </div>
  );
}