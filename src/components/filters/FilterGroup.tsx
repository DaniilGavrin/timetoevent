import { ReactNode } from 'react';

interface FilterGroupProps {
  title: string;
  children: ReactNode;
}

export function FilterGroup({ title, children }: FilterGroupProps) {
  return (
    <div className="space-y-2">
      <h3 className="text-xs font-medium text-muted-foreground uppercase tracking-wider">
        {title}
      </h3>
      <div className="flex flex-wrap gap-1.5">{children}</div>
    </div>
  );
}