import { Link } from '@tanstack/react-router';
import { Search, Bell } from 'lucide-react';

export function Header() {
  return (
    <header className="h-14 flex-shrink-0 flex items-center justify-between px-6 border-b border-border bg-card">
      {/* Заголовок */}
      <div>
        <h1 className="text-xl font-bold">TimeToEvent</h1>
      </div>

      {/* Поиск */}
      <div className="flex-1 max-w-md mx-8">
        <div className="relative">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
          <input
            type="text"
            placeholder="Поиск событий..."
            className="w-full pl-10 pr-4 py-2 bg-secondary rounded-lg border border-border focus:border-primary focus:outline-none text-sm"
          />
        </div>
      </div>

      {/* Действия */}
      <div className="flex items-center gap-3">
        <button className="p-2 hover:bg-secondary rounded-lg transition-colors relative">
          <Bell className="w-5 h-5 text-muted-foreground" />
          {/* Бейдж уведомлений (опционально) */}
          <span className="absolute top-1 right-1 w-2 h-2 bg-destructive rounded-full"></span>
        </button>

        <Link to="/events/new" className="btn-primary text-sm">
          + Создать
        </Link>
      </div>
    </header>
  );
}