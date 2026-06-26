import { useState, useRef, useEffect } from 'react';
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
  const triggerRef = useRef<HTMLButtonElement>(null);
  const dropdownRef = useRef<HTMLDivElement>(null);

  // Закрытие по клику вне
  useEffect(() => {
    if (!isOpen) return;
    const handleClickOutside = (e: MouseEvent) => {
      if (
        dropdownRef.current &&
        !dropdownRef.current.contains(e.target as Node) &&
        triggerRef.current &&
        !triggerRef.current.contains(e.target as Node)
      ) {
        setIsOpen(false);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, [isOpen]);

  // Блокируем скролл body когда dropdown открыт
  useEffect(() => {
    if (!isOpen) return;
    const originalOverflow = document.body.style.overflow;
    document.body.style.overflow = 'hidden';
    return () => {
      document.body.style.overflow = originalOverflow;
    };
  }, [isOpen]);

  const handleDateChange = (date: Date | null) => {
    if (date) {
      //  Защита: не даём выбрать вне [minDate, maxDate]
      if (minDate) {
        const minTs = minDate.getTime();
        if (date.getTime() < minTs) {
          // Сдвигаем к minDate, сохраняя время
          const adjusted = new Date(minDate);
          adjusted.setHours(date.getHours(), date.getMinutes(), date.getSeconds());
          onChange(adjusted);
          return;
        }
      }
      if (maxDate) {
        const maxTs = maxDate.getTime();
        if (date.getTime() > maxTs) {
          const adjusted = new Date(maxDate);
          adjusted.setHours(date.getHours(), date.getMinutes(), date.getSeconds());
          onChange(adjusted);
          return;
        }
      }
    }
    onChange(date);
  };

  const handleClear = (e: React.MouseEvent) => {
    e.stopPropagation();
    onChange(null);
    setIsOpen(false);
  };

  //  КЛЮЧЕВОЕ ИСПРАВЛЕНИЕ: умное позиционирование с ограничением высоты
  const getDropdownStyle = (): React.CSSProperties => {
    if (!triggerRef.current) return {};
    const rect = triggerRef.current.getBoundingClientRect();
    const spaceBelow = window.innerHeight - rect.bottom - 16; // 16px запас
    const spaceAbove = rect.top - 16;
    const maxDropdownHeight = Math.min(520, window.innerHeight * 0.85);

    const baseStyle: React.CSSProperties = {
      position: 'fixed',
      zIndex: 50,
      width: Math.max(rect.width, 320),
      minWidth: '320px',
      //  ВСЕГДА ограничиваем высоту
      maxHeight: `${maxDropdownHeight}px`,
      overflowY: 'auto',
      overscrollBehavior: 'contain',
    };

    // Выбираем сторону, где больше места
    if (spaceBelow >= spaceAbove || spaceBelow >= 400) {
      // Открываем вниз
      baseStyle.top = rect.bottom + 8;
      baseStyle.left = rect.left;
      baseStyle.maxHeight = `${Math.min(maxDropdownHeight, spaceBelow)}px`;
    } else {
      // Открываем вверх
      baseStyle.bottom = window.innerHeight - rect.top + 8;
      baseStyle.left = rect.left;
      baseStyle.maxHeight = `${Math.min(maxDropdownHeight, spaceAbove)}px`;
    }

    // Горизонтальная корректировка — не даём вылезти справа
    const rightEdge = rect.left + (baseStyle.width as number);
    if (rightEdge > window.innerWidth - 16) {
      baseStyle.left = Math.max(16, window.innerWidth - (baseStyle.width as number) - 16);
    }

    return baseStyle;
  };

  return (
    <div className={`space-y-2 ${disabled ? 'opacity-50 pointer-events-none' : ''}`}>
      {label && (
        <label className="text-sm font-medium text-foreground">{label}</label>
      )}

      {/* Trigger */}
      <button
        ref={triggerRef}
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
            onClick={handleClear}
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
          ref={dropdownRef}
          className="rounded-lg border border-border p-3 space-y-3 bg-card"
          style={{
            ...getDropdownStyle(),
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

      {error && <p className="text-xs text-destructive">{error}</p>}
    </div>
  );
}