export interface ColorPickerProps {
  value: string;
  onChange: (color: string) => void;
  label?: string;
  error?: string;
  disabled?: boolean;
  presetColors?: string[];
  showAlpha?: boolean;
}

export interface ColorPaletteProps {
  colors: string[];
  selected: string;
  onSelect: (color: string) => void;
}

export interface ColorHexInputProps {
  value: string;
  onChange: (color: string) => void;
  showAlpha?: boolean;
}

export interface ColorRGBInputProps {
  value: string;
  onChange: (color: string) => void;
}

export interface ColorARGBInputProps {
  value: string;
  onChange: (color: string) => void;
}

export interface ColorPreviewProps {
  color: string;
  size?: 'sm' | 'md' | 'lg';
}

export const DEFAULT_PALETTE = [
  '#ef4444', '#f97316', '#eab308', '#22c55e', '#10b981',
  '#06b6d4', '#3b82f6', '#8b5cf6', '#ec4899',
  '#f8fafc', '#94a3b8', '#64748b', '#334155', '#1e293b',
  '#0f172a', '#000000',
];

// 🔥 Утилиты для конвертации — ARGB формат (#AARRGGBB)
export const colorUtils = {
  // Парсит любой HEX в {r, g, b, a}
  // Поддерживает: #RGB, #RRGGBB, #AARRGGBB (ARGB)
  hexToArgb: (hex: string): { a: number; r: number; g: number; b: number } => {
    let h = hex.replace('#', '').toUpperCase();
    if (h.length === 3) {
      h = h.split('').map(c => c + c).join('');
      return {
        a: 255,
        r: parseInt(h.slice(0, 2), 16),
        g: parseInt(h.slice(2, 4), 16),
        b: parseInt(h.slice(4, 6), 16),
      };
    }
    if (h.length === 6) {
      return {
        a: 255,
        r: parseInt(h.slice(0, 2), 16),
        g: parseInt(h.slice(2, 4), 16),
        b: parseInt(h.slice(4, 6), 16),
      };
    }
    if (h.length === 8) {
      // 🔥 ARGB формат: AA RRGGBB
      return {
        a: parseInt(h.slice(0, 2), 16),
        r: parseInt(h.slice(2, 4), 16),
        g: parseInt(h.slice(4, 6), 16),
        b: parseInt(h.slice(6, 8), 16),
      };
    }
    return { a: 255, r: 0, g: 0, b: 0 };
  },

  // Собирает ARGB hex из компонентов
  argbToHex: (a: number, r: number, g: number, b: number): string => {
    const toHex = (n: number) =>
      Math.max(0, Math.min(255, Math.round(n)))
        .toString(16)
        .padStart(2, '0')
        .toUpperCase();
    if (a < 255) {
      return `#${toHex(a)}${toHex(r)}${toHex(g)}${toHex(b)}`;
    }
    return `#${toHex(r)}${toHex(g)}${toHex(b)}`;
  },

  // RGB hex (без альфы)
  rgbToHex: (r: number, g: number, b: number): string => {
    const toHex = (n: number) =>
      Math.max(0, Math.min(255, Math.round(n)))
        .toString(16)
        .padStart(2, '0')
        .toUpperCase();
    return `#${toHex(r)}${toHex(g)}${toHex(b)}`;
  },

  // Для CSS (rgba()) — нужен для градиентов
  toRgba: (hex: string): string => {
    const { r, g, b, a } = colorUtils.hexToArgb(hex);
    return `rgba(${r}, ${g}, ${b}, ${(a / 255).toFixed(2)})`;
  },
};