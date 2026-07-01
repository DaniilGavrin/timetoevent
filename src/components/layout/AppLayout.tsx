import { Outlet, useLocation } from '@tanstack/react-router';
import { motion, AnimatePresence } from 'framer-motion';
import { useState } from 'react';
import { LeftSidebar } from './LeftSidebar';
import { BottomNav } from './BottomNav';
import { RightPanel } from './RightPanel';
import { FiltersDrawer } from './FiltersDrawer';
import { Header } from './Header';

export function AppLayout() {
  const location = useLocation();
  const [filtersOpen, setFiltersOpen] = useState(false);

  const pathSegments = location.pathname.split('/').filter(Boolean);
  const isEventDetail =
    pathSegments.length >= 2 &&
    pathSegments[0] === 'events' &&
    pathSegments[1] !== 'new';
  const isFavorites = location.pathname === '/favorites';
  const isSettings = location.pathname === '/settings';
  const isDevices = location.pathname === '/devices';

  // RightPanel показываем только на главной (список событий)
  const showRightPanel = !isEventDetail && !isFavorites && !isSettings && !isDevices;

  return (
    <div className="flex h-screen overflow-hidden bg-background">
      {/* Desktop sidebar */}
      <div className="hidden md:block h-full">
        <LeftSidebar />
      </div>

      <div className="flex-1 flex flex-col min-w-0">
        <Header onOpenFilters={() => setFiltersOpen(true)} />

        <div className="flex-1 flex overflow-hidden">
          <main className="flex-1 min-w-0 overflow-y-auto mobile-bottom-padding">
            <Outlet />
          </main>

          {/* Desktop right panel */}
          <AnimatePresence initial={false}>
            {showRightPanel && (
              <motion.aside
                key="right-panel"
                initial={{ width: 0, opacity: 0 }}
                animate={{ width: 320, opacity: 1 }}
                exit={{ width: 0, opacity: 0 }}
                transition={{
                  width: { duration: 0.4, ease: [0.4, 0, 0.2, 1] as const },
                  opacity: { duration: 0.25, ease: 'easeOut' },
                }}
                className="hidden md:flex flex-shrink-0 border-l border-border bg-card overflow-hidden"
                style={{ willChange: 'width, opacity' }}
              >
                <div className="w-80 h-full">
                  <RightPanel />
                </div>
              </motion.aside>
            )}
          </AnimatePresence>
        </div>
      </div>

      {/* Mobile bottom nav */}
      <BottomNav />

      {/* Mobile filters drawer */}
      <FiltersDrawer isOpen={filtersOpen} onClose={() => setFiltersOpen(false)} />
    </div>
  );
}