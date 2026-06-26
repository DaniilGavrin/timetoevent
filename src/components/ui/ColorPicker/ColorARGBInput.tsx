import { useState, useEffect } from 'react';
import type { ColorARGBInputProps } from './types';
import { colorUtils } from './types';

export function ColorARGBInput({ value, onChange }: ColorARGBInputProps) {
  const [argb, setArgb] = useState({ a: 255, r: 0, g: 0, b: 0 });

  useEffect(() => {
    const parsed = colorUtils.hexToArgb(value);
    setArgb(parsed);
  }, [value]);

  const handleChange = (channel: 'a' | 'r' | 'g' | 'b', val: number) => {
    const newArgb = { ...argb, [channel]: val };
    setArgb(newArgb);
    onChange(colorUtils.argbToHex(newArgb.a, newArgb.r, newArgb.g, newArgb.b));
  };

  const handleInputChange = (channel: 'a' | 'r' | 'g' | 'b', raw: string) => {
    const val = Math.max(0, Math.min(255, parseInt(raw) || 0));
    handleChange(channel, val);
  };

  // 🔥 Цвет без альфы — для градиента альфы
  const rgbHex = colorUtils.rgbToHex(argb.r, argb.g, argb.b);

  return (
    <div className="space-y-3">
      {/* 🔥 Alpha — с checkerboard фоном */}
      <div className="space-y-1">
        <div className="flex items-center justify-between">
          <label className="text-xs font-medium text-muted-foreground">
            A <span className="text-muted-foreground/60">(прозрачность)</span>
          </label>
          <input
            type="number"
            value={argb.a}
            onChange={(e) => handleInputChange('a', e.target.value)}
            min={0}
            max={255}
            className="w-14 px-2 py-0.5 text-xs font-mono text-right bg-secondary rounded border border-border focus:border-primary focus:outline-none"
          />
        </div>
        <div className="relative w-full h-2 rounded-lg overflow-hidden">
          {/* Checkerboard — показывает прозрачность */}
          <div
            className="absolute inset-0"
            style={{
              backgroundImage: `
                linear-gradient(45deg, #808080 25%, transparent 25%),
                linear-gradient(-45deg, #808080 25%, transparent 25%),
                linear-gradient(45deg, transparent 75%, #808080 75%),
                linear-gradient(-45deg, transparent 75%, #808080 75%)
              `,
              backgroundSize: '8px 8px',
              backgroundPosition: '0 0, 0 4px, 4px -4px, -4px 0px',
            }}
          />
          {/* Градиент от прозрачного к цвету */}
          <div
            className="absolute inset-0"
            style={{
              background: `linear-gradient(to right, transparent 0%, ${rgbHex} 100%)`,
            }}
          />
          {/* Невидимый слайдер */}
          <input
            type="range"
            value={argb.a}
            onChange={(e) => handleChange('a', parseInt(e.target.value))}
            min={0}
            max={255}
            className="absolute inset-0 w-full h-full opacity-0 cursor-pointer"
          />
          {/* Индикатор позиции */}
          <div
            className="absolute top-1/2 -translate-y-1/2 w-3 h-3 bg-white border-2 border-border rounded-full shadow-md pointer-events-none"
            style={{ left: `calc(${(argb.a / 255) * 100}% - 6px)` }}
          />
        </div>
      </div>

      {/* R */}
      <div className="space-y-1">
        <div className="flex items-center justify-between">
          <label className="text-xs font-medium text-red-400">R</label>
          <input
            type="number"
            value={argb.r}
            onChange={(e) => handleInputChange('r', e.target.value)}
            min={0}
            max={255}
            className="w-14 px-2 py-0.5 text-xs font-mono text-right bg-secondary rounded border border-border focus:border-primary focus:outline-none"
          />
        </div>
        <input
          type="range"
          value={argb.r}
          onChange={(e) => handleChange('r', parseInt(e.target.value))}
          min={0}
          max={255}
          className="w-full h-2 rounded-lg appearance-none cursor-pointer"
          style={{ background: 'linear-gradient(to right, #000000, #FF0000)' }}
        />
      </div>

      {/* G */}
      <div className="space-y-1">
        <div className="flex items-center justify-between">
          <label className="text-xs font-medium text-green-400">G</label>
          <input
            type="number"
            value={argb.g}
            onChange={(e) => handleInputChange('g', e.target.value)}
            min={0}
            max={255}
            className="w-14 px-2 py-0.5 text-xs font-mono text-right bg-secondary rounded border border-border focus:border-primary focus:outline-none"
          />
        </div>
        <input
          type="range"
          value={argb.g}
          onChange={(e) => handleChange('g', parseInt(e.target.value))}
          min={0}
          max={255}
          className="w-full h-2 rounded-lg appearance-none cursor-pointer"
          style={{ background: 'linear-gradient(to right, #000000, #00FF00)' }}
        />
      </div>

      {/* B */}
      <div className="space-y-1">
        <div className="flex items-center justify-between">
          <label className="text-xs font-medium text-blue-400">B</label>
          <input
            type="number"
            value={argb.b}
            onChange={(e) => handleInputChange('b', e.target.value)}
            min={0}
            max={255}
            className="w-14 px-2 py-0.5 text-xs font-mono text-right bg-secondary rounded border border-border focus:border-primary focus:outline-none"
          />
        </div>
        <input
          type="range"
          value={argb.b}
          onChange={(e) => handleChange('b', parseInt(e.target.value))}
          min={0}
          max={255}
          className="w-full h-2 rounded-lg appearance-none cursor-pointer"
          style={{ background: 'linear-gradient(to right, #000000, #0000FF)' }}
        />
      </div>
    </div>
  );
}