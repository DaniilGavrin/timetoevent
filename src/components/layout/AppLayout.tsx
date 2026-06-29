import { Outlet } from '@tanstack/react-router';
import { LeftSidebar } from './LeftSidebar';
import { RightPanel } from './RightPanel';
import { Header } from './Header';

export function AppLayout() {
  return (
    <div className="flex h-screen overflow-hidden bg-background">
      {/* Левая панель */}
      <LeftSidebar />

      {/* Правая часть: Header + (Центр + Правая панель) */}
      <div className="flex-1 flex flex-col min-w-0">
        {/* Шапка (только над центром + правой панелью) */}
        <Header />

        {/* Контент: центр + правая панель */}
        <div className="flex-1 flex overflow-hidden">
          {/* Центральная часть */}
          <main className="flex-1 min-w-0 overflow-y-auto">
            <Outlet />
          </main>

          {/* Правая панель */}
          <RightPanel />
        </div>
      </div>
    </div>
  );
}