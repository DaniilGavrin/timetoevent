import { useState } from 'react';
import { ColorPalette } from './ColorPalette';
import { ColorHexInput } from './ColorHexInput';
import { ColorPreview } from './ColorPreview';
import { DEFAULT_PALETTE, type ColorPickerProps } from './types';

export function ColorPicker({
  value,
  onChange,
  label,
  error,
  disabled,
  presetColors = DEFAULT_PALETTE,
  showAlpha = false,
}: ColorPickerProps) {
  const [mode, setMode] = useState<'palette' | 'hex'>('palette');

  return (
    <div className={`space-y-2 ${disabled ? 'opacity-50 pointer-events-none' : ''}`}>
      {/* Label + Preview */}
      {label && (
        <div className="flex items-center justify-between">
          <label className="text-sm font-medium text-foreground">{label}</label>
          <ColorPreview color={value} size="sm" />
        </div>
      )}

      {/* Контейнер — матовый металлик */}
      <div
        className="rounded-lg border border-border p-3 space-y-3"
        style={{
          backgroundColor: 'var(--card)',
          boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.04), 0 1px 3px rgba(0,0,0,0.3)',
        }}
      >
        {/* Переключатель режимов */}
        <div className="flex gap-1 p-0.5 bg-secondary rounded-md">
          <button
            type="button"
            onClick={() => setMode('palette')}
            className={`
              flex-1 px-2 py-1 text-xs font-medium rounded transition-all
              ${mode === 'palette'
                ? 'bg-card text-foreground shadow-sm'
                : 'text-muted-foreground hover:text-foreground'}
            `}
          >
            Палитра
          </button>
          <button
            type="button"
            onClick={() => setMode('hex')}
            className={`
              flex-1 px-2 py-1 text-xs font-medium rounded transition-all
              ${mode === 'hex'
                ? 'bg-card text-foreground shadow-sm'
                : 'text-muted-foreground hover:text-foreground'}
            `}
          >
            HEX{showAlpha ? '/ARGB' : ''}
          </button>
        </div>

        {/* Контент */}
        {mode === 'palette' ? (
          <ColorPalette
            colors={presetColors}
            selected={value}
            onSelect={onChange}
          />
        ) : (
          <div className="space-y-3">
            <ColorHexInput
              value={value}
              onChange={onChange}
              showAlpha={showAlpha}
            />
            {/* Большой превью */}
            <div className="flex justify-center">
              <ColorPreview color={value} size="lg" />
            </div>
          </div>
        )}
      </div>

      {error && (
        <p className="text-xs text-destructive">{error}</p>
      )}
    </div>
  );
}