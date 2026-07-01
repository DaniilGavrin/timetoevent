import { Link } from '@tanstack/react-router';
import { Search, Bell, SlidersHorizontal } from 'lucide-react';

interface HeaderProps {
  onOpenFilters: () => void;
}

export function Header({ onOpenFilters }: HeaderProps) {
  return (
    <header className="h-14 flex-shrink-0 flex items-center justify-between px-4 md:px-6 border-b border-border bg-card">
      {/* Заголовок */}
      <div className="flex items-center gap-2">
        <h1 className="text-lg md:text-xl font-bold">TimeToEvent</h1>
      </div>

      {/* Поиск — скрыт на мобильных (будет в фильтрах) */}
      <div className="hidden md:flex flex-1 max-w-md mx-8">
        <div className="relative w-full">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
          <input
            type="text"
            placeholder="Поиск событий..."
            className="w-full pl-10 pr-4 py-2 bg-secondary rounded-lg border border-border focus:border-primary focus:outline-none text-sm"
          />
        </div>
      </div>

      {/* Действия */}
      <div className="flex items-center gap-2 md:gap-3">
        {/* Кнопка фильтров — только на мобильных */}
        <button
          onClick={onOpenFilters}
          className="md:hidden p-2 hover:bg-secondary rounded-lg transition-colors relative"
          title="Фильтры"
        >
          <SlidersHorizontal className="w-5 h-5 text-muted-foreground" />
        </button>

        <button className="p-2 hover:bg-secondary rounded-lg transition-colors relative">
          <Bell className="w-5 h-5 text-muted-foreground" />
          <span className="absolute top-1 right-1 w-2 h-2 bg-destructive rounded-full"></span>
        </button>

        <Link
          to="/events/new"
          className="btn-primary text-sm px-3 py-1.5 md:px-4 md:py-2"
        >
          <span className="hidden sm:inline">+ Создать</span>
          <span className="sm:hidden">+</span>
        </Link>
      </div>
    </header>
  );
}