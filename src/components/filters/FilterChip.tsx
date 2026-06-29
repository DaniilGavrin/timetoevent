interface FilterChipProps {
  label: string;
  active?: boolean;
  count?: number;
  onClick: () => void;
}

export function FilterChip({ label, active, count, onClick }: FilterChipProps) {
  return (
    <button
      onClick={onClick}
      className={`
        inline-flex items-center gap-1.5 px-2.5 py-1 rounded-md text-xs font-medium
        border transition-colors
        ${active
          ? 'bg-foreground/10 border-foreground/20 text-foreground'
          : 'bg-transparent border-border text-muted-foreground hover:border-foreground/10 hover:text-foreground'
        }
      `}
    >
      {label}
      {count !== undefined && (
        <span className={`text-[10px] ${active ? 'text-foreground/70' : 'text-muted-foreground/60'}`}>
          {count}
        </span>
      )}
    </button>
  );
}