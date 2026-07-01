import { Home, Star, Wifi, Settings } from 'lucide-react';
import { Link, useLocation } from '@tanstack/react-router';
import { motion } from 'framer-motion';

const navItems = [
  { to: '/', icon: Home, label: 'Главная' },
  { to: '/favorites', icon: Star, label: 'Избранное' },
  { to: '/devices', icon: Wifi, label: 'Устройства' },
  { to: '/settings', icon: Settings, label: 'Настройки' },
];

export function BottomNav() {
  const location = useLocation();

  return (
    <nav className="md:hidden fixed bottom-0 left-0 right-0 z-40 border-t border-border bg-card/95 backdrop-blur-md safe-area-bottom">
      <div className="flex items-center justify-around h-16 px-2">
        {navItems.map(({ to, icon: Icon, label }) => {
          const isActive = location.pathname === to;
          return (
            <Link
              key={to}
              to={to}
              className={`
                flex flex-col items-center justify-center gap-0.5
                flex-1 h-full py-2 rounded-lg
                transition-colors relative
                ${isActive
                  ? 'text-foreground'
                  : 'text-muted-foreground hover:text-foreground'
                }
              `}
            >
              {/* Индикатор активной вкладки */}
              {isActive && (
                <motion.div
                  layoutId="bottomNavIndicator"
                  className="absolute top-0 left-1/2 -translate-x-1/2 w-8 h-0.5 bg-foreground rounded-full"
                  transition={{ type: 'spring', stiffness: 500, damping: 35 }}
                />
              )}
              <Icon className={`w-5 h-5 ${isActive ? 'stroke-[2.5px]' : ''}`} />
              <span className="text-[10px] font-medium">{label}</span>
            </Link>
          );
        })}
      </div>
    </nav>
  );
}