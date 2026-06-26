export interface ColorPickerProps {
  value: string;                    // HEX цвет (например, "#3b82f6")
  onChange: (color: string) => void;
  label?: string;
  error?: string;
  disabled?: boolean;
  /** Предустановленные цвета (переопределяет дефолтную палитру) */
  presetColors?: string[];
  /** Показывать alpha-канал */
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

export interface ColorPreviewProps {
  color: string;
  size?: 'sm' | 'md' | 'lg';
}

/** Предустановленная палитра в стиле металлик */
export const DEFAULT_PALETTE = [
  // Основные
  '#ef4444', // красный
  '#f97316', // оранжевый
  '#eab308', // жёлтый
  '#22c55e', // зелёный
  '#10b981', // изумрудный
  '#06b6d4', // циан
  '#3b82f6', // синий
  '#8b5cf6', // фиолетовый
  '#ec4899', // розовый
  // Нейтральные
  '#f8fafc', // белый
  '#94a3b8', // серый светлый
  '#64748b', // серый
  '#334155', // серый тёмный
  '#1e293b', // графит
  '#0f172a', // почти чёрный
  '#000000', // чёрный
];