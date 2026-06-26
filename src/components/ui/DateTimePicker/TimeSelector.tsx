import { Clock } from 'lucide-react';
import type { TimeSelectorProps } from './types';

export function TimeSelector({ value, onChange, minuteStep = 1 }: TimeSelectorProps) {
  const hours = value ? value.getHours() : 0;
  const minutes = value ? value.getMinutes() : 0;

  const hoursOptions = Array.from({ length: 24 }, (_, i) => i);
  const minutesOptions = Array.from({ length: 60 / minuteStep }, (_, i) => i * minuteStep);

  const updateHours = (h: number) => {
    const d = value ? new Date(value) : new Date();
    d.setHours(h);
    onChange(d);
  };

  const updateMinutes = (m: number) => {
    const d = value ? new Date(value) : new Date();
    d.setMinutes(m);
    onChange(d);
  };

  return (
    <div className="space-y-2">
      <div className="flex items-center gap-1.5 text-xs font-medium text-muted-foreground uppercase tracking-wider">
        <Clock className="w-3.5 h-3.5" />
        Время
      </div>

      <div className="flex items-center gap-2">
        {/* Часы */}
        <div className="flex-1">
          <select
            value={hours}
            onChange={(e) => updateHours(Number(e.target.value))}
            className="w-full px-3 py-2 bg-secondary rounded-md border border-border text-center font-mono text-lg focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary/30 transition-colors"
          >
            {hoursOptions.map((h) => (
              <option key={h} value={h}>
                {String(h).padStart(2, '0')}
              </option>
            ))}
          </select>
          <div className="text-center text-xs text-muted-foreground mt-1">Часы</div>
        </div>

        <span className="text-2xl font-mono text-muted-foreground pb-4">:</span>

        {/* Минуты */}
        <div className="flex-1">
          <select
            value={minutes}
            onChange={(e) => updateMinutes(Number(e.target.value))}
            className="w-full px-3 py-2 bg-secondary rounded-md border border-border text-center font-mono text-lg focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary/30 transition-colors"
          >
            {minutesOptions.map((m) => (
              <option key={m} value={m}>
                {String(m).padStart(2, '0')}
              </option>
            ))}
          </select>
          <div className="text-center text-xs text-muted-foreground mt-1">Минуты</div>
        </div>
      </div>
    </div>
  );
}