import { useState, useEffect } from 'react';
import type { ColorHexInputProps } from './types';

// 🔥 Валидация: #RGB, #RRGGBB, #AARRGGBB (ARGB!)
function isValidHex(value: string): boolean {
  return /^#([0-9A-Fa-f]{3}|[0-9A-Fa-f]{6}|[0-9A-Fa-f]{8})$/.test(value);
}

function normalizeHex(value: string): string {
  if (!value.startsWith('#')) value = '#' + value;
  const body = value.slice(1);
  if (body.length === 3) {
    return '#' + body.split('').map(c => c + c).join('').toUpperCase();
  }
  return value.toUpperCase();
}

export function ColorHexInput({ value, onChange, showAlpha }: ColorHexInputProps) {
  const [inputValue, setInputValue] = useState(value);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    setInputValue(value);
    setError(null);
  }, [value]);

  const handleChange = (raw: string) => {
    let v = raw.trim();
    if (!v.startsWith('#')) v = '#' + v;
    setInputValue(v);

    if (isValidHex(v)) {
      setError(null);
      onChange(normalizeHex(v));
    } else if (v.length >= 4) {
      setError(
        showAlpha
          ? 'Формат: #AARRGGBB (например, #FF3B82F6)'
          : 'Формат: #RRGGBB (например, #3B82F6)'
      );
    } else {
      setError(null);
    }
  };

  return (
    <div className="space-y-1.5">
      <div className="flex items-center gap-2">
        <span className="text-xs text-muted-foreground uppercase tracking-wider font-medium">
          HEX{showAlpha ? ' (ARGB)' : ''}
        </span>
        <div className="relative flex-1">
          <input
            type="text"
            value={inputValue}
            onChange={(e) => handleChange(e.target.value)}
            maxLength={showAlpha ? 9 : 7}
            placeholder={showAlpha ? '#FF3B82F6' : '#3B82F6'}
            className={`
              w-full px-3 py-1.5 text-sm font-mono uppercase
              bg-secondary rounded-md border transition-colors
              ${error ? 'border-destructive' : 'border-border focus:border-primary'}
              focus:outline-none focus:ring-1 focus:ring-primary/30
            `}
          />
        </div>
      </div>
      {error && <p className="text-xs text-destructive">{error}</p>}
      {showAlpha && !error && (
        <p className="text-xs text-muted-foreground">
          Формат: <span className="font-mono">#AARRGGBB</span> — AA это прозрачность (FF = непрозрачный, 00 = прозрачный)
        </p>
      )}
    </div>
  );
}