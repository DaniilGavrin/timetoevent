import { RouterProvider, createRouter } from '@tanstack/react-router';
import { routeTree } from './routeTree.gen';
import { Toaster } from 'sonner';
import { useState, useEffect } from 'react';
import { AnimatePresence } from 'framer-motion';
import { SplashScreen } from './components/SplashScreen';
import { api } from './lib/tauri';
import './index.css';

const router = createRouter({ routeTree });

declare module '@tanstack/react-router' {
  interface Register {
    router: typeof router;
  }
}

function App() {
  const [minTimePassed, setMinTimePassed] = useState(false);
  const [isBackendReady, setIsBackendReady] = useState(false);

  useEffect(() => {
    // Минимальное время показа splash (для красивой анимации)
    const timer = setTimeout(() => setMinTimePassed(true), 1500);

    // Проверяем готовность бэкенда через реальный вызов
    api
      .getLocalIp()
      .then(() => setIsBackendReady(true))
      .catch(() => setIsBackendReady(true)); // Всё равно показываем UI

    // Инициализируем тему (светлая/тёмная)
    initTheme();

    return () => clearTimeout(timer);
  }, []);

  const showSplash = !minTimePassed || !isBackendReady;

  return (
    <>
      <AnimatePresence mode="wait">
        {showSplash && <SplashScreen key="splash" />}
      </AnimatePresence>
      {!showSplash && (
        <>
          <RouterProvider router={router} />
          <Toaster position="top-center" richColors />
        </>
      )}
    </>
  );
}

function initTheme() {
  const saved = localStorage.getItem('theme') as 'dark' | 'light' | 'system' | null;
  const mediaQuery = window.matchMedia('(prefers-color-scheme: light)');

  const updateTheme = () => {
    if (saved === 'light') {
      document.documentElement.classList.add('light');
    } else if (saved === 'dark') {
      document.documentElement.classList.remove('light');
    } else {
      // system — следуем за ОС
      document.documentElement.classList.toggle('light', mediaQuery.matches);
    }
  };

  updateTheme();
  mediaQuery.addEventListener('change', () => {
    // Перечитываем только если тема = system
    const current = localStorage.getItem('theme');
    if (!current || current === 'system') {
      updateTheme();
    }
  });
}

export default App;