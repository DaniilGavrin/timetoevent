# Архитектура TimeToEvent

Этот документ описывает архитектуру проекта TimeToEvent — локального трекера событий с P2P-синхронизацией.

---

## 🎯 Обзор

TimeToEvent — desktop/mobile приложение, построенное на **Tauri V2** с **React** frontend и **Rust** backend. Ключевая особенность — P2P-синхронизация между устройствами в локальной сети **без серверов**, с end-to-end шифрованием.

### Основные принципы
- **Local-first** — все данные хранятся локально, интернет не требуется
- **Privacy by design** — end-to-end шифрование по умолчанию
- **Zero server** — синхронизация напрямую между устройствами
- **Cross-platform** — Windows, Linux, Android (iOS/macOS не поддерживаются)

---

## 🏗 Общая архитектура

<pre><code>┌─────────────────────────────────────────────────────────┐
│ Frontend (React 19 + TypeScript)                         │
│ - TanStack Router (роутинг)                              │
│ - Zustand (стейт)                                        │
│ - Framer Motion (анимации)                               │
│ - Tailwind 3.4 (стили)                                   │
│ - date-fns (работа с датами)                             │
└────────────────┬────────────────────────────────────────┘
                 │ invoke() через Tauri IPC
                 ▼
┌─────────────────────────────────────────────────────────┐
│ Rust Backend (Tauri V2)                                  │
│                                                          │
│ ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │
│ │ Discovery    │  │ Auth         │  │ Sync Engine  │   │
│ │ - mDNS       │  │ - ECDH       │  │ - Diff calc  │   │
│ │              │  │ - 6-digit    │  │ - Encrypt    │   │
│ │              │  │ - AES-256    │  │ - WebSocket  │   │
│ └──────────────┘  └──────────────┘  └──────────────┘   │
│                                                          │
│ ┌──────────────────────────────────────────────────┐   │
│ │ SQLite (events, reminders, peers, sync_log)      │   │
│ └──────────────────────────────────────────────────┘   │
└────────────────┬────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────┐
│ OS Native APIs                                           │
│ - NotificationManager (Android)                         │
│ - Windows Toast Notifications                           │
│ - libnotify (Linux)                                     │
└─────────────────────────────────────────────────────────┘</code></pre>

---

## 📁 Структура проекта

<pre><code>TimeToEvent/
├── src/                          # Frontend (React + TypeScript)
│   ├── App.tsx                   # Корневой компонент
│   ├── main.tsx                  # Точка входа
│   ├── index.css                 # Глобальные стили + тема
│   │
│   ├── components/
│   │   ├── ui/                   # Переиспользуемые UI (Button, Input, Modal)
│   │   ├── layout/               # Header, Sidebar, BottomNav
│   │   ├── events/               # EventCard, EventForm, EventList
│   │   ├── pairing/              # QRScanner, PairingCode, DeviceList
│   │   └── SplashScreen.tsx      # Анимация загрузки
│   │
│   ├── routes/                   # TanStack Router (file-based)
│   │   ├── __root.tsx
│   │   ├── index.tsx             # Главная (список событий)
│   │   ├── events.$id.tsx        # Детали события
│   │   ├── settings.tsx          # Настройки
│   │   └── pairing.tsx           # Сопряжение устройств
│   │
│   ├── stores/                   # Zustand stores
│   │   ├── eventsStore.ts        # События
│   │   ├── syncStore.ts          # Статус синхронизации
│   │   └── settingsStore.ts      # Настройки
│   │
│   ├── lib/                      # Утилиты
│   │   ├── tauri.ts              # invoke() wrappers
│   │   ├── types.ts              # TypeScript типы
│   │   ├── dateUtils.ts          # date-fns хелперы
│   │   └── crypto.ts             # Крипто хелперы
│   │
│   └── hooks/                    # Кастомные хуки
│       ├── useEvents.ts
│       ├── useSync.ts
│       └── useTimer.ts           # Хук для таймеров в реальном времени
│
├── src-tauri/                    # Backend (Rust)
│   ├── Cargo.toml
│   ├── tauri.conf.json
│   ├── build.rs
│   │
│   ├── capabilities/
│   │   └── default.json          # Tauri permissions
│   │
│   └── src/
│       ├── main.rs               # Точка входа
│       ├── lib.rs                # Tauri setup + регистрация плагинов
│       │
│       ├── commands/             # Tauri команды (вызываются через invoke)
│       │   ├── mod.rs
│       │   ├── events.rs         # CRUD событий
│       │   ├── reminders.rs      # Планировщик уведомлений
│       │   ├── sync.rs           # Оркестрация синхронизации
│       │   └── pairing.rs        # Сопряжение устройств
│       │
│       ├── discovery/            # Обнаружение устройств
│       │   ├── mod.rs
│       │   └── mdns.rs           # mDNS advertising + scanning
│       │
│       ├── transport/            # Передача данных
│       │   ├── mod.rs
│       │   └── websocket.rs      # WebSocket server/client
│       │
│       ├── crypto/               # Криптография
│       │   ├── mod.rs
│       │   ├── ecdh.rs           # X25519 key exchange
│       │   ├── aes.rs            # AES-256-GCM шифрование
│       │   └── codes.rs          # 6-значные коды сопряжения
│       │
│       ├── db/                   # База данных
│       │   ├── mod.rs
│       │   ├── sqlite.rs         # SQLite wrapper
│       │   └── migrations.rs     # Миграции БД
│       │
│       └── models/               # Модели данных
│           ├── mod.rs
│           ├── event.rs          # Event
│           ├── reminder.rs       # Reminder
│           └── peer.rs           # Peer (устройство)
│
├── collect-app.ps1               # Скрипт экспорта кода
├── BACKLOG.md                    # Полный бэклог задач
├── ARCHITECTURE.md               # Этот файл
├── CHANGELOG.md                  # История изменений
├── README.md                     # Описание проекта
└── LICENSE                       # MIT</code></pre>

---

## 🎨 Frontend

### Технологии
- **React 19** — UI библиотека
- **TypeScript 5.8** — типизация
- **Vite 7** — бандлер и dev server
- **Tailwind CSS 3.4** — utility-first стили
- **Framer Motion** — анимации
- **Zustand** — глобальный стейт
- **TanStack Router** — file-based роутинг
- **date-fns** — работа с датами
- **react-hook-form + zod** — формы и валидация
- **lucide-react** — иконки
- **sonner** — toast-уведомления
- **html5-qrcode + qrcode.react** — QR-коды

### Архитектура UI

<pre><code>App.tsx
├── SplashScreen (при загрузке, 2.5 сек)
└── RouterProvider
    ├── __root.tsx (общий layout)
    ├── index.tsx (главная — список событий)
    ├── events.$id.tsx (детали события)
    ├── settings.tsx (настройки)
    └── pairing.tsx (сопряжение устройств)</code></pre>

### Стейт-менеджмент

Используем **Zustand** для глобального стейта:

<pre><code>eventsStore     — список событий, CRUD операции
syncStore       — статус синхронизации, список устройств
settingsStore   — настройки (тема, язык, уведомления)</code></pre>

### Взаимодействие с Rust

Через Tauri IPC (`invoke()`):

<pre><code>// src/lib/tauri.ts
import { invoke } from '@tauri-apps/api/core';

export const api = {
  getLocalIp: () => invoke<string>('get_local_ip'),
  getEvents: () => invoke<Event[]>('get_events'),
  createEvent: (event: NewEvent) => invoke<Event>('create_event', { event }),
  // ...
};</code></pre>

---

## 🦀 Backend (Rust)

### Технологии
- **Tauri V2** — framework для desktop/mobile
- **rusqlite** — SQLite wrapper
- **tokio** — async runtime
- **tokio-tungstenite** — WebSocket
- **mdns** — mDNS discovery
- **x25519-dalek** — ECDH
- **aes-gcm** — шифрование
- **hkdf + sha2 + hmac** — криптопримитивы
- **qrcode + image** — генерация QR
- **serde + bincode** — сериализация

### Модули

#### `commands/` — Tauri команды
Функции, вызываемые из frontend через `invoke()`. Каждая команда:
- Принимает сериализованные аргументы
- Возвращает `Result<T, String>`
- Обрабатывает ошибки и логирует их

#### `discovery/` — обнаружение устройств
- **mDNS advertising** — устройство анонсирует себя в сети
- **mDNS scanning** — поиск других устройств с TimeToEvent
- Использует crate `mdns`

#### `transport/` — передача данных
- **WebSocket server** — принимает подключения от других устройств
- **WebSocket client** — подключается к другим устройствам
- Автопереподключение при разрыве связи
- Heartbeat для проверки живости

#### `crypto/` — криптография
- **ECDH (X25519)** — обмен ключами
- **AES-256-GCM** — шифрование данных
- **HKDF** — вывод ключей из shared secret
- **6-значные коды** — защита от MITM-атак

#### `db/` — база данных
- **SQLite** — локальное хранилище
- **Миграции** — версионирование схемы БД
- Таблицы: `events`, `reminders`, `peers`, `sync_log`

#### `models/` — модели данных
Структуры данных с `serde::Serialize/Deserialize`:
- `Event` — событие
- `Reminder` — напоминание
- `Peer` — доверенное устройство

---

## 🌐 P2P Синхронизация

### Протокол

<pre><code>1. Discovery (mDNS)
   Устройство A анонсирует: _time2event._tcp.local
   Устройство B находит A через mDNS scanning

2. Handshake
   A → B: {pub_key_A, device_info, nonce_A}
   B → A: {pub_key_B, nonce_B}
   Обе стороны: shared_secret = X25519(priv, pub_other)
   Обе стороны: session_key = HKDF(shared_secret, nonce_A + nonce_B)

3. Verification
   A → B: ENCRYPT(session_key, "AUTH_CODE:123456")
   B проверяет код (пользователь вводит на UI)
   Если код верный → канал установлен

4. Data Transfer
   Все данные шифруются AES-256-GCM с session_key
   Формат: {type, payload, timestamp, signature}

5. Auto-reconnect
   При разрыве связи — автоматическое переподключение
   Heartbeat каждые 30 секунд</code></pre>

### Поток данных при синхронизации

<pre><code>1. Устройство A создаёт/изменяет событие
2. Изменение записывается в SQLite + sync_log
3. При обнаружении устройства B в сети:
   - Устанавливается WebSocket соединение
   - ECDH handshake + проверка 6-значного кода
   - Передаётся дельта изменений (только что изменилось)
4. Устройство B применяет изменения к своей БД
5. Конфликты разрешаются по last-write-wins</code></pre>

---

## 🔒 Безопасность

### Криптография
- **X25519** — эллиптическая кривая для ECDH
- **AES-256-GCM** — симметричное шифрование с аутентификацией
- **HKDF** — вывод ключей из shared secret
- **HMAC-SHA256** — проверка 6-значных кодов

### Защита от атак
- **MITM** — 6-значный код при сопряжении (пользователь визуально сравнивает)
- **Brute force** — 3 попытки + блокировка на 30 секунд
- **Replay** — nonce в каждом сообщении
- **Tampering** — AES-GCM включает аутентификацию

### Хранение данных
- SQLite без шифрования (пока)
- В будущем: SQLCipher для шифрования БД
- Ключи сессий — в памяти (не на диске)

---

## 📊 Поток данных

### Создание события

<pre><code>UI (React)
  │
  ├─► invoke('create_event', { event })
  │
  ▼
commands::create_event (Rust)
  │
  ├─► db::insert_event() → SQLite
  │
  ├─► sync::notify_change() → sync_log
  │
  └─► Ok(event)
  │
  ▼
UI обновляет eventsStore</code></pre>

### Синхронизация

<pre><code>discovery::mdns (Rust)
  │
  ├─► Обнаружено устройство B
  │
  ▼
transport::websocket::connect()
  │
  ├─► crypto::ecdh::handshake()
  │
  ├─► crypto::codes::verify()
  │
  ▼
sync::sync_changes()
  │
  ├─► db::get_delta_changes() → SQLite
  │
  ├─► crypto::aes::encrypt() → зашифрованные данные
  │
  ├─► websocket::send() → устройство B
  │
  └─► db::mark_as_synced() → SQLite</code></pre>

---

## 🎯 Целевые платформы

| Платформа | Статус | Примечания |
|-----------|--------|------------|
| Windows 10/11 | ✅ Поддерживается | WebView2 (обычно предустановлен) |
| Linux | ✅ Поддерживается | WebKitGTK |
| Android 7+ | ✅ Поддерживается | Системный WebView |
| iOS | ❌ Не поддерживается | Осознанное решение |
| macOS | ❌ Не поддерживается | Осознанное решение |

### Почему нет iOS/macOS?
- Требует Xcode + Apple Developer Account ($99/год)
- Специфичные API (Multipeer Connectivity вместо mDNS)
- Solo-проект не может поддерживать все платформы

---

## 🚀 Производительность

### Frontend
- Vite dev server — hot reload за 1-2 секунды
- React 19 — concurrent features
- Framer Motion — GPU-ускоренные анимации
- Zustand — минимальный overhead

### Backend
- Rust — компилируется в нативный код
- SQLite — быстрый локальный движок
- Tokio — async I/O без блокировок
- mDNS — минимальный сетевой трафик

### Оптимизации
- Виртуализация списков (react-window) — для 1000+ событий
- Debounce для поиска — 300ms
- Lazy loading компонентов
- Code splitting
- Индексы SQLite для частых запросов

---

## 🧪 Тестирование

### Unit-тесты (Rust)
- `#[test]` для каждого модуля
- Тесты SQLite CRUD
- Тесты криптографии
- Тесты mDNS discovery

### Unit-тесты (TypeScript)
- Vitest для компонентов
- React Testing Library
- Тесты Zustand stores

### E2E тесты
- Playwright для desktop
- Appium для Android
- Тесты синхронизации между двумя устройствами

---

## 📚 Ссылки

- [Tauri V2 Docs](https://v2.tauri.app/)
- [React 19 Docs](https://react.dev/)
- [Rust Book](https://doc.rust-lang.org/book/)
- [TanStack Router](https://tanstack.com/router)
- [Zustand](https://github.com/pmndrs/zustand)
- [Framer Motion](https://www.framer.com/motion/)

---

<div align="center">

*© 2026 ByteWizard*

</div>