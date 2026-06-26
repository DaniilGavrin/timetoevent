import type { ColorPaletteProps } from './types';

export function ColorPalette({ colors, selected, onSelect }: ColorPaletteProps) {
  return (
    <div className="grid grid-cols-8 gap-1.5">
      {colors.map((color) => {
        const isSelected = selected.toLowerCase() === color.toLowerCase();
        return (
          <button
            key={color}
            type="button"
            onClick={() => onSelect(color)}
            className={`
              relative w-7 h-7 rounded-md transition-all
              ${isSelected
                ? 'ring-2 ring-primary ring-offset-2 ring-offset-card scale-110'
                : 'hover:scale-110 hover:ring-1 hover:ring-primary/50'}
            `}
            style={{
              backgroundColor: color,
              boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.1), 0 1px 2px rgba(0,0,0,0.4)',
            }}
            title={color}
          >
            {/* Блик */}
            <div
              className="absolute inset-x-0 top-0 h-1/2 rounded-t-md pointer-events-none"
              style={{
                background: 'linear-gradient(180deg, rgba(255,255,255,0.15) 0%, transparent 100%)',
              }}
            />
            {/* Галочка для выбранного */}
            {isSelected && (
              <svg
                className="absolute inset-0 m-auto w-3.5 h-3.5 text-white drop-shadow-md"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
                strokeWidth={3}
              >
                <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" />
              </svg>
            )}
          </button>
        );
      })}
    </div>
  );
}