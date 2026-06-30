import { Home, Star, Folder, Wifi, Settings } from 'lucide-react';
import { Link, useLocation } from '@tanstack/react-router';

export function LeftSidebar() {
  const location = useLocation();

  const navItems = [
    { to: '/', icon: Home, label: 'Главная', available: true },
    { to: '/favorites', icon: Star, label: 'Избранное', available: true },
    { to: '/devices', icon: Wifi, label: 'Устройства', available: true },
  ];

  return (
    <aside className="w-16 flex-shrink-0 flex flex-col border-r border-border bg-card">
      {/* Логотип */}
      <div className="h-14 flex items-center justify-center border-b border-border">
        <div className="w-8 h-8 rounded-lg bg-secondary flex items-center justify-center">
          <span className="text-foreground font-bold text-sm">T</span>
        </div>
      </div>

      {/* Навигация */}
      <nav className="flex-1 py-3 space-y-1">
        {navItems.map(({ to, icon: Icon, label, available }) => {
          const isActive = location.pathname === to;

          if (!available) {
            return (
              <button
                key={to}
                disabled
                className="w-full flex items-center justify-center p-3 rounded-lg text-muted-foreground/30 cursor-not-allowed group relative focus:outline-none"
                title={`${label} (скоро)`}
              >
                <Icon className="w-5 h-5" />
                <span className="absolute left-full ml-2 px-2 py-1 bg-card border border-border rounded text-xs whitespace-nowrap opacity-0 group-hover:opacity-100 pointer-events-none transition-opacity z-50">
                  {label} (скоро)
                </span>
              </button>
            );
          }

          return (
            <Link
              key={to}
              to={to}
              className={`
                w-full flex items-center justify-center p-3 rounded-lg
                transition-colors group relative
                focus:outline-none focus-visible:ring-2 focus-visible:ring-primary/50
                ${isActive
                  ? 'bg-secondary text-foreground'
                  : 'text-muted-foreground hover:bg-secondary hover:text-foreground'
                }
              `}
              title={label}
            >
              <Icon className="w-5 h-5" />
              <span className="absolute left-full ml-2 px-2 py-1 bg-card border border-border rounded text-xs whitespace-nowrap opacity-0 group-hover:opacity-100 pointer-events-none transition-opacity z-50">
                {label}
              </span>
            </Link>
          );
        })}
      </nav>

      {/* Настройки внизу */}
      <div className="p-2 border-t border-border">
        <button
          disabled
          className="w-full flex items-center justify-center p-3 rounded-lg text-muted-foreground/30 cursor-not-allowed focus:outline-none"
          title="Настройки (скоро)"
        >
          <Settings className="w-5 h-5" />
        </button>
      </div>
    </aside>
  );
}