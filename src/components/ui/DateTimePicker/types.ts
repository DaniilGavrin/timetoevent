export interface DateTimePickerProps {
  value: Date | null;
  onChange: (date: Date | null) => void;
  label?: string;
  error?: string;
  disabled?: boolean;
  minDate?: Date;
  maxDate?: Date;
  placeholder?: string;
}

export interface CalendarProps {
  value: Date | null;
  onChange: (date: Date | null) => void;
  minDate?: Date;
  maxDate?: Date;
  viewDate: Date;
  onViewDateChange: (date: Date) => void;
}

export interface TimeSelectorProps {
  value: Date | null;
  onChange: (date: Date | null) => void;
  minuteStep?: number;
}

export interface CalendarHeaderProps {
  viewDate: Date;
  onPrevMonth: () => void;
  onNextMonth: () => void;
  onToday: () => void;
  canGoPrev?: boolean;
  canGoNext?: boolean;
}

/** Дни недели (Пн — Вс) */
export const WEEKDAYS = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

/** Месяцы */
export const MONTHS = [
  'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
  'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь',
];

/** Утилиты для работы с датами */
export const dateUtils = {
  /** Начало дня (00:00:00) */
  startOfDay: (date: Date): Date => {
    const d = new Date(date);
    d.setHours(0, 0, 0, 0);
    return d;
  },

  /** Конец дня (23:59:59) */
  endOfDay: (date: Date): Date => {
    const d = new Date(date);
    d.setHours(23, 59, 59, 999);
    return d;
  },

  /** Первый день месяца */
  startOfMonth: (date: Date): Date => {
    const d = new Date(date);
    d.setDate(1);
    d.setHours(0, 0, 0, 0);
    return d;
  },

  /** Последний день месяца */
  endOfMonth: (date: Date): Date => {
    const d = new Date(date);
    d.setMonth(d.getMonth() + 1, 0);
    d.setHours(23, 59, 59, 999);
    return d;
  },

  /** Добавить месяц */
  addMonths: (date: Date, months: number): Date => {
    const d = new Date(date);
    d.setMonth(d.getMonth() + months);
    return d;
  },

  /** Один ли день */
  isSameDay: (a: Date, b: Date): boolean => {
    return (
      a.getFullYear() === b.getFullYear() &&
      a.getMonth() === b.getMonth() &&
      a.getDate() === b.getDate()
    );
  },

  /** Сегодня */
  isToday: (date: Date): boolean => {
    return dateUtils.isSameDay(date, new Date());
  },

  /** День в пределах [min, max] */
  isDateInRange: (date: Date, min?: Date, max?: Date): boolean => {
    const d = dateUtils.startOfDay(date);
    if (min && d < dateUtils.startOfDay(min)) return false;
    if (max && d > dateUtils.startOfDay(max)) return false;
    return true;
  },

  /** Сетка дней для календаря (включая дни с предыдущего/следующего месяца) */
  getCalendarGrid: (viewDate: Date): Date[] => {
    const firstDay = dateUtils.startOfMonth(viewDate);
    const grid: Date[] = [];

    // День недели первого дня месяца (0 = Пн, 6 = Вс)
    let startWeekday = firstDay.getDay() - 1;
    if (startWeekday < 0) startWeekday = 6;

    // Дни предыдущего месяца
    for (let i = startWeekday; i > 0; i--) {
      const d = new Date(firstDay);
      d.setDate(d.getDate() - i);
      grid.push(d);
    }

    // Дни текущего месяца + следующий месяц до 42 ячеек (6 недель)
    const currentMonth = firstDay.getMonth();
    let d = new Date(firstDay);
    while (grid.length < 42) {
      grid.push(new Date(d));
      d.setDate(d.getDate() + 1);
    }

    return grid;
  },

  /** Форматирование для отображения */
  formatDisplay: (date: Date | null): string => {
    if (!date) return '';
    const day = String(date.getDate()).padStart(2, '0');
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const year = date.getFullYear();
    const hours = String(date.getHours()).padStart(2, '0');
    const minutes = String(date.getMinutes()).padStart(2, '0');
    return `${day}.${month}.${year} ${hours}:${minutes}`;
  },
};