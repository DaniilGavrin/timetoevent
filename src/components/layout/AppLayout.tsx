import { Outlet, useLocation } from '@tanstack/react-router';
import { motion, AnimatePresence } from 'framer-motion';
import { LeftSidebar } from './LeftSidebar';
import { RightPanel } from './RightPanel';
import { Header } from './Header';

export function AppLayout() {
  const location = useLocation();

  // Определяем, на экране ли деталей события
  const pathSegments = location.pathname.split('/').filter(Boolean);
  const isEventDetail =
    pathSegments.length === 2 &&
    pathSegments[0] === 'events' &&
    pathSegments[1] !== 'new';

  return (
    <div className="flex h-screen overflow-hidden bg-background">
      <LeftSidebar />

      <div className="flex-1 flex flex-col min-w-0">
        <Header />

        <div className="flex-1 flex overflow-hidden">
          {/* Центральный контент — занимает всё оставшееся */}
          <main className="flex-1 min-w-0 overflow-y-auto">
            <Outlet />
          </main>

          {/* 🔥 Правая панель с плавной анимацией появления/исчезновения */}
          <AnimatePresence initial={false}>
            {!isEventDetail && (
              <motion.aside
                key="right-panel"
                initial={{ width: 0, opacity: 0 }}
                animate={{ width: 320, opacity: 1 }}
                exit={{ width: 0, opacity: 0 }}
                transition={{
                  width: { duration: 0.4, ease: [0.4, 0, 0.2, 1] },
                  opacity: { duration: 0.25, ease: 'easeOut' },
                }}
                className="flex-shrink-0 border-l border-border bg-card overflow-hidden"
                style={{ willChange: 'width, opacity' }}
              >
                {/* Внутренний контейнер фиксированной ширины, чтобы контент не сжимался */}
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