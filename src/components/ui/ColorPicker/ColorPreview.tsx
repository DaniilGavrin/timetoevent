import type { ColorPreviewProps } from './types';

const sizes = {
  sm: 'w-6 h-6',
  md: 'w-10 h-10',
  lg: 'w-16 h-16',
};

export function ColorPreview({ color, size = 'md' }: ColorPreviewProps) {
  return (
    <div
      className={`${sizes[size]} rounded-lg border border-border relative overflow-hidden`}
      style={{
        backgroundColor: color,
        boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.1), 0 1px 3px rgba(0,0,0,0.4)',
      }}
    >
      {/* Блик сверху — эффект полированного металла */}
      <div
        className="absolute inset-x-0 top-0 h-1/2 pointer-events-none"
        style={{
          background: 'linear-gradient(180deg, rgba(255,255,255,0.15) 0%, transparent 100%)',
        }}
      />
    </div>
  );
}