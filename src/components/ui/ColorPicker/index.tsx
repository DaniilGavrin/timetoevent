import { useState, useRef, useEffect } from 'react';
import { ColorPalette } from './ColorPalette';
import { ColorHexInput } from './ColorHexInput';
import { ColorRGBInput } from './ColorRGBInput';
import { ColorARGBInput } from './ColorARGBInput';
import { ColorPreview } from './ColorPreview';
import { DEFAULT_PALETTE, type ColorPickerProps } from './types';

type InputMode = 'palette' | 'hex' | 'rgb' | 'argb';

export function ColorPicker({
  value,
  onChange,
  label,
  error,
  disabled,
  presetColors = DEFAULT_PALETTE,
  showAlpha = false,
}: ColorPickerProps) {
  const [isOpen, setIsOpen] = useState(false);
  const [mode, setMode] = useState<InputMode>('palette');
  const triggerRef = useRef<HTMLButtonElement>(null);
  const containerRef = useRef<HTMLDivElement>(null);
  const dropdownRef = useRef<HTMLDivElement>(null);

  // Закрытие по клику вне
  useEffect(() => {
    if (!isOpen) return;
    const handleClickOutside = (e: MouseEvent) => {
      if (
        dropdownRef.current &&
        !dropdownRef.current.contains(e.target as Node) &&
        triggerRef.current &&
        !triggerRef.current.contains(e.target as Node)
      ) {
        setIsOpen(false);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, [isOpen]);

  // Блокируем скролл body
  useEffect(() => {
    if (!isOpen) return;
    const originalOverflow = document.body.style.overflow;
    document.body.style.overflow = 'hidden';
    return () => {
      document.body.style.overflow = originalOverflow;
    };
  }, [isOpen]);

  // 🔥 Умное позиционирование
  const getDropdownStyle = (): React.CSSProperties => {
    if (!triggerRef.current) return {};
    const rect = triggerRef.current.getBoundingClientRect();
    const dropdownWidth = 280;
    const gap = 8;
    const edgePadding = 16;

    const spaceBelow = window.innerHeight - rect.bottom - edgePadding;
    const spaceAbove = rect.top - edgePadding;

    const style: React.CSSProperties = {
      position: 'fixed',
      zIndex: 50,
      width: Math.min(dropdownWidth, window.innerWidth - edgePadding * 2),
    };

    if (spaceBelow >= 300 || spaceBelow >= spaceAbove) {
      style.top = rect.bottom + gap;
    } else {
      style.bottom = window.innerHeight - rect.top + gap;
    }

    if (rect.left + dropdownWidth > window.innerWidth - edgePadding) {
      style.right = edgePadding;
    } else {
      style.left = rect.left;
    }

    return style;
  };

  const renderInput = () => {
    switch (mode) {
      case 'palette':
        return (
          <ColorPalette
            colors={presetColors}
            selected={value}
            onSelect={(color) => {
              onChange(color);
              setIsOpen(false);
            }}
          />
        );
      case 'hex':
        return (
          <div className="space-y-3">
            <ColorHexInput value={value} onChange={onChange} showAlpha={showAlpha} />
            <div className="flex justify-center">
              <ColorPreview color={value} size="lg" />
            </div>
          </div>
        );
      case 'rgb':
        return (
          <div className="space-y-3">
            <ColorRGBInput value={value} onChange={onChange} />
            <div className="flex justify-center">
              <ColorPreview color={value} size="lg" />
            </div>
          </div>
        );
      case 'argb':
        return (
          <div className="space-y-3">
            <ColorARGBInput value={value} onChange={onChange} />
            <div className="flex justify-center">
              <ColorPreview color={value} size="lg" />
            </div>
          </div>
        );
    }
  };

  const modeButton = (m: InputMode, text: string) => (
    <button
      type="button"
      onClick={() => setMode(m)}
      className={`flex-1 px-2 py-1 text-xs font-medium rounded transition-all ${
        mode === m
          ? 'bg-card text-foreground shadow-sm'
          : 'text-muted-foreground hover:text-foreground'
      }`}
    >
      {text}
    </button>
  );

  return (
    <div
      ref={containerRef}
      className={`relative space-y-1.5 ${disabled ? 'opacity-50 pointer-events-none' : ''}`}
    >
      {label && (
        <label className="block text-sm font-medium text-foreground">{label}</label>
      )}

      <button
        ref={triggerRef}
        type="button"
        onClick={() => setIsOpen(!isOpen)}
        disabled={disabled}
        className={`
          w-full flex items-center gap-3 px-3 py-2
          bg-secondary rounded-lg border transition-colors
          ${error ? 'border-destructive' : 'border-border hover:border-primary/50'}
          ${isOpen ? 'border-primary ring-1 ring-primary/30' : ''}
        `}
        style={{ boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.04)' }}
      >
        <ColorPreview color={value} size="sm" />
        <span className="text-sm font-mono text-foreground">{value.toUpperCase()}</span>
        <span className="ml-auto text-xs text-muted-foreground">
          {isOpen ? 'Закрыть' : 'Выбрать'}
        </span>
      </button>

      {isOpen && (
        <div
          ref={dropdownRef}
          className="rounded-lg border border-border p-3 space-y-3 bg-card"
          style={{
            ...getDropdownStyle(),
            boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.04), 0 8px 24px rgba(0,0,0,0.5)',
          }}
        >
          {/* 🔥 4 режима */}
          <div className="flex gap-1 p-0.5 bg-secondary rounded-md">
            {modeButton('palette', 'Палитра')}
            {modeButton('hex', 'HEX')}
            {modeButton('rgb', 'RGB')}
            {modeButton('argb', 'ARGB')}
          </div>

          {renderInput()}
        </div>
      )}

      {error && <p className="text-xs text-destructive">{error}</p>}
    </div>
  );
}