import { useState, useMemo } from 'react';
import { motion } from 'framer-motion';
import { ArrowLeft, Clock, Tag, FileText, Type } from 'lucide-react';
import { toast } from 'sonner';
import { ColorPicker } from '../ui/ColorPicker';
import { DateTimePicker } from '../ui/DateTimePicker';
import type { Event, NewEvent } from '../../lib/tauri';

interface EventFormProps {
  initialData?: Event;
  onSubmit: (data: NewEvent | Event) => Promise<void>;
  onCancel: () => void;
  submitLabel: string;
  title: string;
}

// Анимации
const containerVariants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: {
      staggerChildren: 0.08,
      delayChildren: 0.15,
    },
  },
};

const fieldVariants = {
  hidden: { opacity: 0, y: 16, scale: 0.98 },
  visible: {
    opacity: 1,
    y: 0,
    scale: 1,
    transition: {
      duration: 0.45,
      ease: [0.22, 1, 0.36, 1] as const,
    },
  },
};

const headerVariants = {
  hidden: { opacity: 0, x: -16 },
  visible: {
    opacity: 1,
    x: 0,
    transition: { duration: 0.5, ease: [0.22, 1, 0.36, 1] as const },
  },
};

export function EventForm({
  initialData,
  onSubmit,
  onCancel,
  submitLabel,
  title,
}: EventFormProps) {
  const [titleValue, setTitleValue] = useState(initialData?.title || '');
  const [description, setDescription] = useState(initialData?.description || '');
  const [eventType, setEventType] = useState<'countdown' | 'countup'>(
    initialData?.event_type || 'countdown'
  );
  const [eventDate, setEventDate] = useState<Date | null>(
    initialData?.event_date ? new Date(initialData.event_date * 1000) : null
  );
  const [category, setCategory] = useState(initialData?.category || '');
  const [color, setColor] = useState<string>(initialData?.color || '#3b82f6');
  const [loading, setLoading] = useState(false);

  // Динамические ограничения даты
  const dateConstraints = useMemo(() => {
    const now = new Date();
    if (eventType === 'countdown') {
      return { minDate: now, maxDate: undefined };
    } else {
      return { minDate: undefined, maxDate: now };
    }
  }, [eventType]);

  // При смене типа — сбрасываем невалидную дату
  const handleTypeChange = (newType: 'countdown' | 'countup') => {
    setEventType(newType);
    if (eventDate) {
      const now = Date.now();
      const ts = eventDate.getTime();
      if (newType === 'countdown' && ts <= now) {
        setEventDate(null);
      }
      if (newType === 'countup' && ts > now) {
        setEventDate(null);
      }
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!titleValue.trim()) {
      toast.error('Название обязательно');
      return;
    }
    if (!eventDate) {
      toast.error('Дата и время обязательны');
      return;
    }

    const nowTs = Math.floor(Date.now() / 1000);
    const eventTs = Math.floor(eventDate.getTime() / 1000);

    if (eventType === 'countdown' && eventTs <= nowTs) {
      toast.error('Для обратного отсчёта дата должна быть в будущем');
      return;
    }
    if (eventType === 'countup' && eventTs > nowTs) {
      toast.error('Для прямого отсчёта дата должна быть в прошлом');
      return;
    }

    setLoading(true);
    try {
      const payload = {
        title: titleValue.trim(),
        description: description.trim() || null,
        event_type: eventType,
        event_date: eventTs,
        category: category.trim() || null,
        color: color || null,
      };

      if (initialData) {
        // Обновление — передаём полный Event объект
        await onSubmit({
          ...initialData,
          ...payload,
          updated_at: nowTs,
        } as Event);
      } else {
        // Создание
        await onSubmit(payload as NewEvent);
      }
    } catch (err) {
      toast.error(`Ошибка: ${String(err)}`);
    } finally {
      setLoading(false);
    }
  };

  return (
    <motion.main
      className="min-h-full overflow-y-auto pb-safe-bottom"
      initial={{ opacity: 0, y: 24, scale: 0.98 }}
      animate={{ opacity: 1, y: 0, scale: 1 }}
      exit={{ opacity: 0, y: -16, scale: 0.99 }}
      transition={{ duration: 0.5, ease: [0.22, 1, 0.36, 1] as const }}
    >
      <div className="container mx-auto px-6 py-8 max-w-3xl">
        {/* Header */}
        <motion.div
          className="mb-8 flex items-center gap-4"
          variants={headerVariants}
          initial="hidden"
          animate="visible"
        >
          <motion.button
            onClick={onCancel}
            className="p-2 hover:bg-secondary rounded-lg transition-colors"
            title="Назад"
            whileHover={{ scale: 1.08, x: -2 }}
            whileTap={{ scale: 0.92 }}
            transition={{ type: 'spring', stiffness: 400, damping: 17 }}
          >
            <ArrowLeft className="w-5 h-5" />
          </motion.button>
          <div className="flex-1">
            <motion.h1
              className="text-3xl font-bold"
              initial={{ opacity: 0, y: -8 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.4, delay: 0.1 }}
            >
              {title}
            </motion.h1>
            <motion.p
              className="mt-1 text-muted-foreground text-sm"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ duration: 0.4, delay: 0.2 }}
            >
              {initialData ? 'Измените данные события' : 'Заполните информацию о событии'}
            </motion.p>
          </div>
        </motion.div>

        {/* Форма */}
        <motion.form
          onSubmit={handleSubmit}
          className="space-y-5"
          variants={containerVariants}
          initial="hidden"
          animate="visible"
        >
          {/* Название */}
          <motion.div variants={fieldVariants} className="card">
            <label className="flex items-center gap-2 text-sm font-medium mb-3">
              <Type className="w-4 h-4 text-muted-foreground" />
              Название <span className="text-destructive">*</span>
            </label>
            <input
              type="text"
              value={titleValue}
              onChange={(e) => setTitleValue(e.target.value)}
              className="w-full px-4 py-2.5 bg-secondary rounded-lg border border-border focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary/30 transition-all"
              placeholder="Например: Отпуск в Турции"
              required
              autoFocus
            />
          </motion.div>

          {/* Описание */}
          <motion.div variants={fieldVariants} className="card">
            <label className="flex items-center gap-2 text-sm font-medium mb-3">
              <FileText className="w-4 h-4 text-muted-foreground" />
              Описание
            </label>
            <textarea
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              className="w-full px-4 py-2.5 bg-secondary rounded-lg border border-border focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary/30 transition-all resize-none"
              rows={3}
              placeholder="Дополнительная информация о событии..."
            />
          </motion.div>

          {/* Тип и Дата */}
          <motion.div variants={fieldVariants} className="card">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="flex items-center gap-2 text-sm font-medium mb-3">
                  <Clock className="w-4 h-4 text-muted-foreground" />
                  Тип события
                </label>
                <div className="grid grid-cols-2 gap-2">
                  <motion.button
                    type="button"
                    onClick={() => handleTypeChange('countdown')}
                    className={`relative px-3 py-2.5 rounded-lg border text-sm font-medium transition-all ${
                      eventType === 'countdown'
                        ? 'border-primary bg-primary/10 text-foreground'
                        : 'border-border bg-secondary/30 text-muted-foreground hover:bg-secondary hover:text-foreground'
                    }`}
                    whileHover={{ scale: 1.02 }}
                    whileTap={{ scale: 0.98 }}
                  >
                    <div className="flex items-center justify-center gap-2">
                      <span>⏳</span>
                      <span>До события</span>
                    </div>
                    {eventType === 'countdown' && (
                      <motion.div
                        className="absolute top-1 right-1 w-2 h-2 rounded-full bg-primary"
                        layoutId="eventTypeIndicator"
                        transition={{ type: 'spring', stiffness: 500, damping: 30 }}
                      />
                    )}
                  </motion.button>
                  <motion.button
                    type="button"
                    onClick={() => handleTypeChange('countup')}
                    className={`relative px-3 py-2.5 rounded-lg border text-sm font-medium transition-all ${
                      eventType === 'countup'
                        ? 'border-primary bg-primary/10 text-foreground'
                        : 'border-border bg-secondary/30 text-muted-foreground hover:bg-secondary hover:text-foreground'
                    }`}
                    whileHover={{ scale: 1.02 }}
                    whileTap={{ scale: 0.98 }}
                  >
                    <div className="flex items-center justify-center gap-2">
                      <span>⏱</span>
                      <span>С события</span>
                    </div>
                    {eventType === 'countup' && (
                      <motion.div
                        className="absolute top-1 right-1 w-2 h-2 rounded-full bg-primary"
                        layoutId="eventTypeIndicator"
                        transition={{ type: 'spring', stiffness: 500, damping: 30 }}
                      />
                    )}
                  </motion.button>
                </div>
                <motion.p
                  className="mt-2 text-xs text-muted-foreground"
                  key={eventType}
                  initial={{ opacity: 0, y: -4 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ duration: 0.3 }}
                >
                  {eventType === 'countdown'
                    ? '⏳ Обратный отсчёт — только будущая дата'
                    : '⏱ Прямой отсчёт — только прошедшая дата'}
                </motion.p>
              </div>

              <div>
                <DateTimePicker
                  value={eventDate}
                  onChange={setEventDate}
                  label="Дата и время"
                  minDate={dateConstraints.minDate}
                  maxDate={dateConstraints.maxDate}
                  placeholder={
                    eventType === 'countdown'
                      ? 'Выберите будущую дату...'
                      : 'Выберите прошедшую дату...'
                  }
                />
              </div>
            </div>
          </motion.div>

          {/* Категория и Цвет */}
          <motion.div variants={fieldVariants} className="card">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="flex items-center gap-2 text-sm font-medium mb-3">
                  <Tag className="w-4 h-4 text-muted-foreground" />
                  Категория
                </label>
                <input
                  type="text"
                  value={category}
                  onChange={(e) => setCategory(e.target.value)}
                  className="w-full px-4 py-2.5 bg-secondary rounded-lg border border-border focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary/30 transition-all"
                  placeholder="Работа, Личное, Здоровье..."
                />
              </div>
              <div>
                <ColorPicker
                  value={color}
                  onChange={setColor}
                  label="Цвет события"
                />
              </div>
            </div>
          </motion.div>

          {/* Кнопки */}
          <motion.div
            variants={fieldVariants}
            className="flex gap-3 pt-4"
          >
            <motion.button
              type="submit"
              disabled={loading}
              className="btn-primary flex-1 disabled:opacity-50 disabled:cursor-not-allowed"
              whileHover={{ scale: loading ? 1 : 1.01, y: loading ? 0 : -1 }}
              whileTap={{ scale: loading ? 1 : 0.98 }}
              transition={{ type: 'spring', stiffness: 400, damping: 17 }}
            >
              {loading ? (
                <span className="flex items-center justify-center gap-2">
                  <motion.div
                    className="w-4 h-4 border-2 border-primary-foreground/30 border-t-primary-foreground rounded-full"
                    animate={{ rotate: 360 }}
                    transition={{ duration: 1, repeat: Infinity, ease: 'linear' }}
                  />
                  Сохранение...
                </span>
              ) : (
                submitLabel
              )}
            </motion.button>
            <motion.button
              type="button"
              onClick={onCancel}
              className="btn-secondary"
              whileHover={{ scale: 1.01, y: -1 }}
              whileTap={{ scale: 0.98 }}
              transition={{ type: 'spring', stiffness: 400, damping: 17 }}
              disabled={loading}
            >
              Отмена
            </motion.button>
          </motion.div>
        </motion.form>
      </div>
    </motion.main>
  );
}