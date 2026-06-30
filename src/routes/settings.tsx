import { createFileRoute, useNavigate } from '@tanstack/react-router';
import { Palette, Globe, Info, Monitor, Moon, Sun, Bell, Wifi, ArrowLeft } from 'lucide-react';
import { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { api } from '../lib/tauri';

export const Route = createFileRoute('/settings')({
  component: SettingsPage,
});

// === Варианты анимаций ===

const pageVariants = {
  initial: { opacity: 0, y: 24, scale: 0.98 },
  animate: {
    opacity: 1,
    y: 0,
    scale: 1,
    transition: {
      duration: 0.5,
      ease: [0.22, 1, 0.36, 1] as const,  // ← as const здесь
    },
  },
  exit: {
    opacity: 0,
    y: -16,
    scale: 0.99,
    transition: { duration: 0.3, ease: [0.4, 0, 1, 1] as const },  // ← и тут
  },
} as const;  // ← или as const на весь объект

const staggerContainer = {
  animate: {
    transition: {
      staggerChildren: 0.08,
      delayChildren: 0.15,
    },
  },
};

const sectionVariants = {
  initial: { opacity: 0, y: 20 },
  animate: {
    opacity: 1,
    y: 0,
    transition: {
      duration: 0.5,
      ease: [0.22, 1, 0.36, 1] as const,
    },
  },
};

const headerVariants = {
  initial: { opacity: 0, x: -12 },
  animate: {
    opacity: 1,
    x: 0,
    transition: { duration: 0.4, delay: 0.05, ease: [0.22, 1, 0.36, 1] as const },
  },
};

type Theme = 'dark' | 'light' | 'system';

function SettingsPage() {
  const navigate = useNavigate();
  const [theme, setTheme] = useState<Theme>(() => {
    const saved = localStorage.getItem('theme');
    return (saved as Theme) || 'system';
  });
  const [language, setLanguage] = useState('ru');
  const [notifications, setNotifications] = useState(true);
  const [localIp, setLocalIp] = useState<string>('...');

  useEffect(() => {
    api
      .getLocalIp()
      .then(setLocalIp)
      .catch(() => setLocalIp('Не определён'));
  }, []);

  useEffect(() => {
    applyTheme(theme);
    localStorage.setItem('theme', theme);
  }, [theme]);

  return (
    <motion.main
      className="min-h-full overflow-y-auto"
      variants={pageVariants}
      initial="initial"
      animate="animate"
      exit="exit"
    >
      <div className="container mx-auto px-6 py-8 max-w-3xl">
        {/* Заголовок с кнопкой назад */}
        <motion.div
          className="mb-8 flex items-center gap-4"
          variants={headerVariants}
        >
          <motion.button
            onClick={() => navigate({ to: '/' })}
            className="p-2 hover:bg-secondary rounded-lg transition-colors"
            title="Назад"
            whileHover={{ scale: 1.08, x: -2 }}
            whileTap={{ scale: 0.92 }}
            transition={{ type: 'spring', stiffness: 400, damping: 17 }}
          >
            <ArrowLeft className="w-5 h-5" />
          </motion.button>
          <div>
            <motion.h1
              className="text-3xl font-bold"
              initial={{ opacity: 0, y: -8 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.4, delay: 0.1 }}
            >
              Настройки
            </motion.h1>
            <motion.p
              className="mt-1 text-muted-foreground"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ duration: 0.4, delay: 0.2 }}
            >
              Настрой TimeToEvent под себя
            </motion.p>
          </div>
        </motion.div>

        {/* Секции с stagger-анимацией */}
        <motion.div
          className="space-y-6"
          variants={staggerContainer}
          initial="initial"
          animate="animate"
        >
          {/* Внешний вид */}
          <motion.div variants={sectionVariants}>
            <SettingsSection
              icon={Palette}
              title="Внешний вид"
              description="Тема оформления интерфейса"
            >
              <div className="grid grid-cols-3 gap-3">
                <ThemeOption
                  icon={Moon}
                  label="Тёмная"
                  active={theme === 'dark'}
                  onClick={() => setTheme('dark')}
                />
                <ThemeOption
                  icon={Sun}
                  label="Светлая"
                  active={theme === 'light'}
                  onClick={() => setTheme('light')}
                />
                <ThemeOption
                  icon={Monitor}
                  label="Системная"
                  active={theme === 'system'}
                  onClick={() => setTheme('system')}
                />
              </div>
            </SettingsSection>
          </motion.div>

          {/* Язык */}
          <motion.div variants={sectionVariants}>
            <SettingsSection
              icon={Globe}
              title="Язык"
              description="Язык интерфейса"
            >
              <div className="grid grid-cols-2 gap-3">
                <LanguageOption
                  label="Русский"
                  code="ru"
                  active={language === 'ru'}
                  onClick={() => setLanguage('ru')}
                />
                <LanguageOption
                  label="English"
                  code="en"
                  active={language === 'en'}
                  onClick={() => setLanguage('en')}
                />
              </div>
              <motion.p
                className="mt-3 text-xs text-muted-foreground"
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                transition={{ delay: 0.5 }}
              >
                💡 Перевод интерфейса появится в будущих версиях
              </motion.p>
            </SettingsSection>
          </motion.div>

          {/* Уведомления */}
          <motion.div variants={sectionVariants}>
            <SettingsSection
              icon={Bell}
              title="Уведомления"
              description="Напоминания о событиях"
            >
              <ToggleOption
                label="Показывать уведомления"
                description="Получать напоминания о событиях"
                checked={notifications}
                onChange={setNotifications}
              />
            </SettingsSection>
          </motion.div>

          {/* Сеть и синхронизация */}
          <motion.div variants={sectionVariants}>
            <SettingsSection
              icon={Wifi}
              title="Сеть и синхронизация"
              description="P2P-подключение к другим устройствам"
            >
              <div className="space-y-2 text-sm">
                <InfoRow label="Локальный IP" value={localIp} />
                <InfoRow label="Порт mDNS" value="5354" />
                <InfoRow label="Порт WebSocket" value="8080" />
                <InfoRow label="Статус" value="Готов к подключению" />
              </div>
              <motion.p
                className="mt-3 text-xs text-muted-foreground"
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                transition={{ delay: 0.6 }}
              >
                🔒 Все данные передаются с end-to-end шифрованием (AES-256-GCM)
              </motion.p>
            </SettingsSection>
          </motion.div>

          {/* О программе */}
          <motion.div variants={sectionVariants}>
            <SettingsSection
              icon={Info}
              title="О программе"
              description="Информация о TimeToEvent"
            >
              <div className="space-y-2 text-sm">
                <InfoRow label="Версия" value="0.2.0 (alpha)" />
                <InfoRow label="Сборка" value="dev" />
                <InfoRow label="Платформа" value="Tauri v2 + React 19" />
                <InfoRow label="Backend" value="Rust + SQLite" />
                <InfoRow label="Лицензия" value="MIT" />
                <InfoRow label="Автор" value="ByteWizard (Даниил Гаврин)" />
              </div>
              <motion.div
                className="mt-4 pt-4 border-t border-border"
                initial={{ opacity: 0, y: 8 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.7 }}
              >
                <p className="text-xs text-muted-foreground text-center">
                  Сделано с 💙 для тех, кто ценит приватность
                </p>
                <p className="text-xs text-muted-foreground text-center mt-1">
                  © 2026 ByteWizard
                </p>
              </motion.div>
            </SettingsSection>
          </motion.div>
        </motion.div>
      </div>
    </motion.main>
  );
}

// === Вспомогательные компоненты ===

function SettingsSection({
  icon: Icon,
  title,
  description,
  children,
}: {
  icon: React.ElementType;
  title: string;
  description: string;
  children: React.ReactNode;
}) {
  return (
    <div className="card">
      <div className="flex items-start gap-4 mb-5">
        <motion.div
          className="w-10 h-10 rounded-lg bg-secondary flex items-center justify-center flex-shrink-0"
          whileHover={{ rotate: [0, -8, 8, 0], transition: { duration: 0.5 } }}
        >
          <Icon className="w-5 h-5 text-muted-foreground" />
        </motion.div>
        <div>
          <h2 className="text-lg font-semibold">{title}</h2>
          <p className="text-sm text-muted-foreground">{description}</p>
        </div>
      </div>
      {children}
    </div>
  );
}

function ThemeOption({
  icon: Icon,
  label,
  active,
  onClick,
}: {
  icon: React.ElementType;
  label: string;
  active: boolean;
  onClick: () => void;
}) {
  return (
    <motion.button
      onClick={onClick}
      className={`
        relative flex flex-col items-center gap-2 p-4 rounded-lg border transition-colors
        ${active
          ? 'border-primary bg-primary/10 text-foreground'
          : 'border-border bg-secondary/30 text-muted-foreground hover:text-foreground'
        }
      `}
      whileHover={{
        scale: 1.03,
        y: -2,
        transition: { type: 'spring', stiffness: 400, damping: 20 },
      }}
      whileTap={{ scale: 0.96 }}
    >
      {/* Glow-эффект при active */}
      <AnimatePresence>
        {active && (
          <motion.div
            className="absolute inset-0 rounded-lg pointer-events-none"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            style={{
              boxShadow:
                '0 0 20px rgba(255, 255, 255, 0.08), inset 0 0 0 1px rgba(255, 255, 255, 0.05)',
            }}
          />
        )}
      </AnimatePresence>

      <motion.div
        animate={active ? { rotate: [0, -10, 10, 0] } : {}}
        transition={{ duration: 0.6 }}
      >
        <Icon className="w-6 h-6" />
      </motion.div>
      <span className="text-sm font-medium">{label}</span>

      {/* Галочка для выбранного */}
      <AnimatePresence>
        {active && (
          <motion.div
            className="absolute top-1.5 right-1.5 w-4 h-4 rounded-full bg-primary flex items-center justify-center"
            initial={{ scale: 0, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            exit={{ scale: 0, opacity: 0 }}
            transition={{ type: 'spring', stiffness: 500, damping: 25 }}
          >
            <svg
              className="w-2.5 h-2.5 text-primary-foreground"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
              strokeWidth={3}
            >
              <motion.path
                strokeLinecap="round"
                strokeLinejoin="round"
                d="M5 13l4 4L19 7"
                initial={{ pathLength: 0 }}
                animate={{ pathLength: 1 }}
                transition={{ duration: 0.3, delay: 0.1 }}
              />
            </svg>
          </motion.div>
        )}
      </AnimatePresence>
    </motion.button>
  );
}

function LanguageOption({
  label,
  code,
  active,
  onClick,
}: {
  label: string;
  code: string;
  active: boolean;
  onClick: () => void;
}) {
  return (
    <motion.button
      onClick={onClick}
      className={`
        relative flex items-center justify-between p-3 rounded-lg border transition-colors
        ${active
          ? 'border-primary bg-primary/10 text-foreground'
          : 'border-border bg-secondary/30 text-muted-foreground hover:text-foreground'
        }
      `}
      whileHover={{
        scale: 1.02,
        x: 2,
        transition: { type: 'spring', stiffness: 400, damping: 20 },
      }}
      whileTap={{ scale: 0.97 }}
    >
      <span className="text-sm font-medium">{label}</span>
      <span className="text-xs uppercase opacity-60 font-mono">{code}</span>

      {/* Индикатор выбора слева */}
      <AnimatePresence>
        {active && (
          <motion.div
            className="absolute left-0 top-1/2 -translate-y-1/2 w-1 h-6 bg-primary rounded-r"
            initial={{ height: 0, opacity: 0 }}
            animate={{ height: 24, opacity: 1 }}
            exit={{ height: 0, opacity: 0 }}
            transition={{ type: 'spring', stiffness: 500, damping: 25 }}
          />
        )}
      </AnimatePresence>
    </motion.button>
  );
}

function ToggleOption({
  label,
  description,
  checked,
  onChange,
}: {
  label: string;
  description?: string;
  checked: boolean;
  onChange: (value: boolean) => void;
}) {
  return (
    <div className="flex items-center justify-between">
      <div className="flex-1">
        <div className="text-sm font-medium">{label}</div>
        {description && (
          <div className="text-xs text-muted-foreground mt-0.5">{description}</div>
        )}
      </div>
      <motion.button
        onClick={() => onChange(!checked)}
        className={`
          relative w-11 h-6 rounded-full transition-colors flex-shrink-0
          ${checked ? 'bg-primary' : 'bg-secondary'}
        `}
        whileTap={{ scale: 0.95 }}
      >
        <motion.span
          className="absolute top-0.5 left-0.5 w-5 h-5 rounded-full bg-white shadow-md"
          animate={{
            x: checked ? 20 : 0,
            scale: checked ? 1.05 : 1,
          }}
          transition={{
            type: 'spring',
            stiffness: 500,
            damping: 30,
          }}
        />
        {/* Glow при active */}
        <AnimatePresence>
          {checked && (
            <motion.div
              className="absolute inset-0 rounded-full pointer-events-none"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              style={{
                boxShadow: '0 0 12px rgba(255, 255, 255, 0.15)',
              }}
            />
          )}
        </AnimatePresence>
      </motion.button>
    </div>
  );
}

function InfoRow({ label, value }: { label: string; value: string }) {
  return (
    <motion.div
      className="flex justify-between py-2 border-b border-border last:border-0"
      whileHover={{ x: 2, transition: { duration: 0.2 } }}
    >
      <span className="text-muted-foreground">{label}</span>
      <span className="font-medium font-mono">{value}</span>
    </motion.div>
  );
}

// === Утилиты для темы ===

function applyTheme(theme: Theme) {
  const html = document.documentElement;

  if (theme === 'system') {
    const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
    html.classList.toggle('light', !prefersDark);
  } else if (theme === 'light') {
    html.classList.add('light');
  } else {
    html.classList.remove('light');
  }
}