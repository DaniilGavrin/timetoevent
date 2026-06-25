# TimeToEvent

> **Трекер событий и таймеров с P2P-синхронизацией между устройствами — без серверов, без облака, без регистрации.**

[![Tauri V2](https://img.shields.io/badge/Tauri-V2-FFC131?logo=tauri)](https://tauri.app/)
[![React](https://img.shields.io/badge/React-19-61DAFB?logo=react)](https://react.dev/)
[![Rust](https://img.shields.io/badge/Rust-2021-000000?logo=rust)](https://www.rust-lang.org/)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.8-3178C6?logo=typescript)](https://www.typescriptlang.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](./LICENSE)
[![Status](https://img.shields.io/badge/Status-Alpha-orange)](#статус-проекта-alpha)

---

## 🎯 Что это?

**TimeToEvent** — локальное приложение для отслеживания событий и таймеров. Отвечает на два вопроса:
- **Сколько времени до события?** (countdown)
- **Сколько прошло с события?** (countup)

Все данные хранятся **локально** на устройстве. Синхронизация между устройствами происходит **напрямую**, через локальную сеть (mDNS + WebSocket), с end-to-end шифрованием. **Без серверов. Без интернета. Без регистрации.**

### Примеры использования

- Таймер до дедлайна проекта
- Счётчик «сколько я не курю»
- Таймер до отпуска / дня рождения / Нового года
- Трекер привычек с визуализацией
- Синхронизация между телефоном и ПК в одной WiFi-сети

---

## ⚠️ Статус проекта: Alpha

Проект находится в **активной разработке**. Текущая версия — **v0.1.0** (завершена).

**Прогресс:** ~40% от полного бэклога (87/220 задач)

### Что уже работает (v0.1.0)

**Backend (Rust) — 100% готов:**
- ✅ SQLite CRUD событий с автоматическим broadcast в sync_log
- ✅ Reminders с планировщиком через tokio::spawn
- ✅ mDNS discovery на порту 5354 с SO_REUSEADDR
- ✅ WebSocket server/client с ECDH (X25519) + AES-256-GCM шифрованием
- ✅ Автопереподключение при разрыве связи (exponential backoff)
- ✅ Heartbeat каждые 30 секунд
- ✅ Pairing: 6-значные коды + HMAC constant-time + блокировка 30 сек
- ✅ Sync engine: delta changes + last-write-wins + batch apply
- ✅ Unit-тесты для криптографии и mDNS

**Frontend — ~25% готов:**
- ✅ SplashScreen с Framer Motion анимацией
- ✅ Тёмная/светлая тема с авто-переключением
- ✅ TanStack Router настроен
- ✅ eventsStore (Zustand) с fetch + create
- ✅ Все TypeScript типы и API обёртки в `lib/tauri.ts`
- ✅ Базовый UI списка событий

### В разработке (v0.2.0 — MVP таймеров)

- 🚧 Живые таймеры countdown/countup (обновление каждую секунду)
- 🚧 Форма создания/редактирования событий
- 🚧 Детальный экран события
- 🚧 Категории событий с цветовым кодированием
- 🚧 Избранные события
-  Поиск и фильтры
- 🚧 Удаление с подтверждением

### Планируется (v0.3.0 – v0.5.0)

- 🔜 UI для P2P-синхронизации (список устройств, статус)
- 🔜 QR-коды для сопряжения
- 🔜 Экспорт/импорт данных в JSON
- 🔜 Повторяющиеся события
- 🔜 Группы событий

---

##  Скриншоты

> *Скриншоты будут добавлены по мере готовности UI.*

---

## 🛠 Стек технологий

### Frontend

- **React 19** + **TypeScript 5.8**
- **Vite 7** — бандлер
- **Tailwind CSS 3.4** — стили
- **Framer Motion** — анимации
- **Zustand** — глобальный стейт
- **TanStack Router** — роутинг
- **date-fns** — работа с датами
- **react-hook-form + zod** — формы и валидация
- **lucide-react** — иконки
- **sonner** — toast-уведомления
- **html5-qrcode + qrcode.react** — QR-коды

### Backend (Rust)

- **Tauri V2** — desktop/mobile framework
- **SQLite** (через `rusqlite`) — локальное хранилище
- **socket2** — mDNS discovery (порт 5354)
- **tokio-tungstenite** — WebSocket сервер/клиент
- **x25519-dalek** — ECDH key exchange
- **aes-gcm** — AES-256-GCM шифрование
- **hkdf + sha2 + hmac** — криптографические примитивы
- **qrcode + image** — генерация QR-кодов
- **serde + bincode** — сериализация

### Tauri плагины

- `tauri-plugin-notification` — локальные уведомления
- `tauri-plugin-fs` — файловая система
- `tauri-plugin-dialog` — диалоги выбора файлов
- `tauri-plugin-shell` — запуск процессов
- `tauri-plugin-autostart` — автозапуск
- `tauri-plugin-clipboard-manager` — буфер обмена
- `tauri-plugin-os` — информация об ОС
- `tauri-plugin-log` — логирование
- `tauri-plugin-updater` — автообновления
- `tauri-plugin-process` — управление процессами

---

##  Установка для разработки

Подробная инструкция — в [`INSTALL.md`](./docs/INSTALL.md).

### Быстрый старт

<pre><code># 1. Клонируем репозиторий
git clone https://github.com/DaniilGavrin/TimeToEvent.git
cd TimeToEvent

# 2. Устанавливаем frontend зависимости
npm install

# 3. Запускаем в режиме разработки
npm run tauri dev</code></pre>

Первый запуск может занять **5-15 минут** — Rust компилирует ~670 зависимостей с нуля. Последующие запуски — секунды.

### Сборка production-бинарника

<pre><code>npm run tauri build</code></pre>

Готовые бинарники появятся в `src-tauri/target/release/bundle/`:
- Windows: `.msi`, `.exe`
- Linux: `.deb`, `.AppImage`
- Android: `.apk` (требует Android SDK)

---

##  Структура проекта

<pre><code>TimeToEvent/
├── src/                        # Frontend (React + TypeScript)
│   ├── components/
│   │   ├── ui/                 # Переиспользуемые UI компоненты
│   │   ├── layout/             # Header, Sidebar, BottomNav
│   │   ├── events/             # EventCard, EventForm, EventList
│   │   ├── pairing/            # QRScanner, PairingCode
│   │   ── SplashScreen.tsx
│   ├── routes/                 # TanStack Router
│   ├── stores/                 # Zustand stores
│   ├── lib/                    # Утилиты и хелперы
│   ── hooks/                  # Кастомные хуки
│
├── src-tauri/                  # Backend (Rust)
│   ├── src/
│   │   ├── commands/           # Tauri команды (invoke)
│   │   ├── discovery/          # mDNS
│   │   ├── transport/          # WebSocket
│   │   ├── crypto/             # ECDH + AES-256-GCM
│   │   ├── db/                 # SQLite
│   │   └── models/             # Модели данных
│   ├── Cargo.toml
│   └── tauri.conf.json
│
├── docs/                       # Документация
│   ├── README.md               # Этот файл
│   ├── INSTALL.md              # Установка и сборка
│   ├── USAGE.md                # Как пользоваться
│   ├── FAQ.md                  # Частые вопросы
│   ├── TROUBLESHOOTING.md      # Решение проблем
│   ├── API.md                  # Документация Tauri команд
│   ├── PROTOCOL.md             # Протокол синхронизации
│   ├── CRYPTO.md               # Описание криптографии
│   ├── CONTRIBUTING.md         # Как внести вклад
│   ├── ARCHITECTURE.md         # Архитектура проекта
│   ├── CHANGELOG.md            # История изменений
│   └── TODO                    # Бэклог задач
│
├── collect-app.ps1             # Скрипт экспорта кода
├── package.json
└── LICENSE                     # MIT</code></pre>

---

## 🔒 Безопасность

- **Все данные хранятся локально** — ничего не уходит в интернет
- **P2P-синхронизация** — только между вашими устройствами в локальной сети
- **End-to-end шифрование** — X25519 (ECDH) + AES-256-GCM
- **Защита от MITM** — 6-значный код при сопряжении + HMAC
- **Блокировка после 3 неудачных попыток** ввода кода
- **Нет серверов, нет телеметрии, нет аналитики**

Подробное описание криптографии — в [`CRYPTO.md`](./docs/CRYPTO.md).

---

## 🌍 Поддерживаемые платформы

| Платформа | Статус |
|-----------|--------|
| Windows 10/11 | ✅ Поддерживается |
| Linux (Ubuntu, Fedora, etc.) | ✅ Поддерживается |
| Android 7+ | ✅ Поддерживается |
| iOS | ❌ Не поддерживается (осознанно) |
| macOS | ❌ Не поддерживается (осознанно) |

> **Почему нет iOS/macOS?** Разработка под Apple-платформы требует значительных ресурсов (Xcode, Apple Developer Account $99/год, специфичные API), которые в рамках solo-проекта нецелесообразны. Фокус — на Windows, Linux и Android.

---

## ☕ Поддержать проект

TimeToEvent — **бесплатный open-source проект без рекламы**. Если он вам полезен, вы можете поддержать разработку:

**USDT (TRC-20):**
<pre><code>TQ3pKUs7Wox8yyeSdTvjw4pfEBVCU57Bm6</code></pre>

> ⚠️ Отправляйте только **USDT в сети TRC-20 (Tron)**. Отправка в другой сети может привести к безвозвратной потере средств.

Каждая поддержка мотивирует делать приложение лучше! 💙

---

## 📚 Документация

- [`INSTALL.md`](./docs/INSTALL.md) — установка и сборка
- [`USAGE.md`](./docs/USAGE.md) — как пользоваться приложением
- [`FAQ.md`](./docs/FAQ.md) — частые вопросы
- [`TROUBLESHOOTING.md`](./docs/TROUBLESHOOTING.md) — решение проблем
- [`API.md`](./docs/API.md) — документация Tauri команд
- [`PROTOCOL.md`](./docs/PROTOCOL.md) — протокол синхронизации
- [`CRYPTO.md`](./docs/CRYPTO.md) — описание криптографии
- [`CONTRIBUTING.md`](./docs/CONTRIBUTING.md) — как внести вклад
- [`ARCHITECTURE.md`](./docs/ARCHITECTURE.md) — архитектура проекта
- [`CHANGELOG.md`](./docs/CHANGELOG.md) — история изменений
- [`TODO`](./docs/TODO) — бэклог задач

---

## 🤝 Вклад

Проект разрабатывается одним человеком, но если у вас есть идеи или предложения — создавайте Issue или Pull Request.

Подробности — в [`CONTRIBUTING.md`](./docs/CONTRIBUTING.md).

---

## 📄 Лицензия

Этот проект распространяется под лицензией **MIT**. См. [LICENSE](./LICENSE) для подробностей.

---

## 👤 Автор

**ByteWizard** (Даниил Гаврин)
- GitHub: [@DaniilGavrin](https://github.com/DaniilGavrin)
- Email: daniilgavrin@bytewizard.ru
- Website: [shop.bytewizard.ru](https://shop.bytewizard.ru)

---

<div align="center">
**Сделано с 💙 для тех, кто ценит приватность и локальные решения**

*© 2026 ByteWizard*
</div>