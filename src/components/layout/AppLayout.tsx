import { Outlet, useLocation } from '@tanstack/react-router';
import { motion, AnimatePresence } from 'framer-motion';
import { LeftSidebar } from './LeftSidebar';
import { RightPanel } from './RightPanel';
import { Header } from './Header';

export function AppLayout() {
  const location = useLocation();
  const pathSegments = location.pathname.split('/').filter(Boolean);

  const isEventDetail =
    pathSegments.length >= 2 &&
    pathSegments[0] === 'events' &&
    pathSegments[1] !== 'new';

  const isFavorites = location.pathname === '/favorites';
  const hideRightPanel = isEventDetail || isFavorites;

  return (
    <div className="flex h-screen overflow-hidden bg-background">
      <LeftSidebar />
      <div className="flex-1 flex flex-col min-w-0">
        <Header />
        <div className="flex-1 flex overflow-hidden">
          <main className="flex-1 min-w-0 overflow-y-auto">
            <Outlet />
          </main>

          <AnimatePresence initial={false}>
            {!hideRightPanel && (
              <motion.aside
                key="right-panel"
                initial={{ width: 0, opacity: 0 }}
                animate={{ width: 320, opacity: 1 }}
                exit={{ width: 0, opacity: 0 }}
                transition={{
                  width: { duration: 0.4, ease: [0.4, 0, 0.2, 1] as const },
                  opacity: { duration: 0.25, ease: 'easeOut' },
                }}
                className="flex-shrink-0 border-l border-border bg-card overflow-hidden"
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
    </div>
  );
}