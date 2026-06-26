import { useState, useEffect } from 'react';
import type { ColorRGBInputProps } from './types';
import { colorUtils } from './types';

export function ColorRGBInput({ value, onChange }: ColorRGBInputProps) {
  const [rgb, setRgb] = useState({ r: 0, g: 0, b: 0 });

  useEffect(() => {
    const { r, g, b } = colorUtils.hexToArgb(value);
    setRgb({ r, g, b });
  }, [value]);

  const handleChange = (channel: 'r' | 'g' | 'b', val: number) => {
    const newRgb = { ...rgb, [channel]: val };
    setRgb(newRgb);
    onChange(colorUtils.rgbToHex(newRgb.r, newRgb.g, newRgb.b));
  };

  const handleInputChange = (channel: 'r' | 'g' | 'b', raw: string) => {
    const val = Math.max(0, Math.min(255, parseInt(raw) || 0));
    handleChange(channel, val);
  };

  return (
    <div className="space-y-3">
      {/* R */}
      <div className="space-y-1">
        <div className="flex items-center justify-between">
          <label className="text-xs font-medium text-red-400">R</label>
          <input
            type="number"
            value={rgb.r}
            onChange={(e) => handleInputChange('r', e.target.value)}
            min={0}
            max={255}
            className="w-14 px-2 py-0.5 text-xs font-mono text-right bg-secondary rounded border border-border focus:border-primary focus:outline-none"
          />
        </div>
        <input
          type="range"
          value={rgb.r}
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
            value={rgb.g}
            onChange={(e) => handleInputChange('g', e.target.value)}
            min={0}
            max={255}
            className="w-14 px-2 py-0.5 text-xs font-mono text-right bg-secondary rounded border border-border focus:border-primary focus:outline-none"
          />
        </div>
        <input
          type="range"
          value={rgb.g}
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
            value={rgb.b}
            onChange={(e) => handleInputChange('b', e.target.value)}
            min={0}
            max={255}
            className="w-14 px-2 py-0.5 text-xs font-mono text-right bg-secondary rounded border border-border focus:border-primary focus:outline-none"
          />
        </div>
        <input
          type="range"
          value={rgb.b}
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