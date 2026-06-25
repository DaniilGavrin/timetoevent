# Changelog

Все значимые изменения в проекте TimeToEvent будут документироваться в этом файле.

Формат основан на [Keep a Changelog](https://keepachangelog.com/),
и этот проект придерживается [Semantic Versioning](https://semver.org/).

---

## [Unreleased]

### Добавлено (25.06.2026)
- **Backend полностью готов (100%)**:
  - SQLite CRUD событий с автоматическим broadcast в sync_log
  - `toggle_favorite` с синхронизацией через WebSocket
  - mDNS discovery на порту 5354 с `SO_REUSEADDR` (через `socket2`)
  - WebSocket server/client с ECDH (X25519) + AES-256-GCM шифрованием
  - Автопереподключение при разрыве связи (каждые 5 сек + exponential backoff)
  - Heartbeat каждые 30 секунд
  - Pairing: 6-значные коды + HMAC constant-time + блокировка 30 сек
  - Sync engine: delta changes + last-write-wins + batch apply
  - `handle_sync_message` с полной обработкой ошибок
  - `sync_with_peer` с задержкой 500ms для избежания race condition
  - Unit-тесты для криптографии (aes, ecdh, codes) и mDNS
- **Frontend (25%)**:
  - SplashScreen с Framer Motion анимацией
  - Базовый UI списка событий
  - `eventsStore` (Zustand) с fetch + create
  - Все TypeScript типы и API обёртки в `lib/tauri.ts`
  - Тёмная/светлая тема с авто-переключением
  - TanStack Router настроен

### Изменено
- mDNS порт изменён с 5353 на 5354 (избежание конфликтов с системными сервисами)
- `reconnect_loop` интервал: 1 сек → 5 сек (меньше нагрузки)
- Добавлена зависимость `socket2 = "0.5"` для `SO_REUSEADDR`

### Исправлено
- `toggle_favorite` теперь синхронизируется с другими устройствами
- `check_missed_reminders` корректно работает при старте
- Race condition в `sync_with_peer` (добавлена задержка)
- Обработка ошибок в `handle_sync_message` (отправка `sync_error` peer)

---

### Добавлено
- Настройка проекта Tauri V2 + React 19 + TypeScript
- Установка всех зависимостей (frontend + backend)
- Базовая структура папок (src/, src-tauri/src/)
- SplashScreen с анимацией (часы, пульсирующие кольца, градиентный текст)
- Базовая Tauri команда `get_local_ip`
- Tailwind CSS 3.4 с тёмной/светлой темой
- TanStack Router настроен
- Подключение всех Tauri плагинов:
  - `notification`, `fs`, `dialog`, `shell`
  - `autostart`, `clipboard-manager`, `os`, `log`
  - `updater`, `process`
- Rust зависимости для P2P:
  - `mdns` + `local-ip-address` + `if-watch` (discovery)
  - `tokio-tungstenite` (WebSocket)
  - `x25519-dalek` + `aes-gcm` + `hkdf` + `sha2` + `hmac` (криптография)
  - `rusqlite` (SQLite)
  - `qrcode` + `image` (QR-коды)
- Скрипт `collect-app.ps1` для экспорта кода проекта
- Файлы документации: `README.md`, `LICENSE`, `BACKLOG.md`

### Изменено
- Откат `bincode` с версии 3.0.0 (тролль-релиз) до 1.3.3
- Настройка зеркала crates.io через rsproxy (для обхода проблем с сетью в СНГ)

### Исправлено
- Ошибка компиляции `tauri_plugin_log::init()` → `Builder::new().build()`
- Ошибка компиляции `tauri_plugin_updater::init()` → `Builder::new().build()`
- Ошибка компиляции `tauri_plugin_autostart::init()` — добавлены аргументы `MacosLauncher`
- Добавлена конфигурация `plugins.updater` в `tauri.conf.json`
- Проблема с Vite dev server и TUN-прокси (Happ) — решение: отключать TUN при разработке

---

## [0.1.0] - TBA (первый публичный релиз)

> *Дата релиза будет объявлена дополнительно*

### Планируется для этого релиза
- Создание/редактирование/удаление событий
- Таймеры countdown/countup в реальном времени
- Категории событий
- Локальные уведомления
- Экспорт/импорт данных в JSON
- Тёмная/светлая тема
- Адаптивный дизайн (mobile-first)

---

## [0.2.0] - TBA

### Планируется
- mDNS discovery (обнаружение устройств в сети)
- QR-коды для сопряжения
- 6-значные коды подтверждения
- Сохранение доверенных устройств

---

## [0.3.0] - TBA

### Планируется
- WebSocket сервер/клиент
- ECDH key exchange (X25519)
- AES-256-GCM шифрование
- P2P-синхронизация между устройствами
- Автопереподключение при разрыве связи

---

## [1.0.0] - TBA

### Планируется
- Стабильная версия для публичного релиза
- Сборка под Windows/Linux/Android
- Полная документация
- Публикация на GitHub Releases

---

## Версии ниже 0.1.0

До версии 0.1.0 проект находится в активной разработке и не имеет стабильных релизов.
Все изменения до первого публичного релиза документируются в секции `[Unreleased]`.

---

## Типы изменений

- **Добавлено** — новые функции
- **Изменено** — изменения в существующем функционале
- **Устарело** — функции, которые будут удалены в будущих версиях
- **Удалено** — удалённые функции
- **Исправлено** — исправления багов
- **Безопасность** — изменения, связанные с уязвимостями

---

<div align="center">

*© 2026 ByteWizard*

</div>