import { ArrowUpDown } from 'lucide-react';
import type { SortBy } from '../../stores/filtersStore';

interface SortSelectorProps {
  value: SortBy;
  onChange: (value: SortBy) => void;
}

const OPTIONS: { value: SortBy; label: string }[] = [
  { value: 'date_asc', label: 'Сначала ближние' },
  { value: 'date_desc', label: 'Сначала дальние' },
  { value: 'title', label: 'По названию' },
  { value: 'created', label: 'По дате создания' },
];

export function SortSelector({ value, onChange }: SortSelectorProps) {
  return (
    <div className="space-y-2">
      <h3 className="text-xs font-medium text-muted-foreground uppercase tracking-wider flex items-center gap-1.5">
        <ArrowUpDown className="w-3 h-3" />
        Сортировка
      </h3>
      <select
        value={value}
        onChange={(e) => onChange(e.target.value as SortBy)}
        className="w-full px-3 py-2 bg-secondary rounded-lg border border-border text-sm focus:border-foreground/20 focus:outline-none transition-colors"
      >
        {OPTIONS.map((opt) => (
          <option key={opt.value} value={opt.value}>
            {opt.label}
          </option>
        ))}
      </select>
    </div>
  );
}