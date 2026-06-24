# TimeToEvent

> **Трекер событий и таймеров с P2P-синхронизацией между устройствами — без серверов, без облака, без регистрации.**

[![Tauri V2](https://img.shields.io/badge/Tauri-V2-FFC131?logo=tauri)](https://tauri.app/)
[![React](https://img.shields.io/badge/React-19-61DAFB?logo=react)](https://react.dev/)
[![Rust](https://img.shields.io/badge/Rust-2021-000000?logo=rust)](https://www.rust-lang.org/)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.8-3178C6?logo=typescript)](https://www.typescriptlang.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](./LICENSE)
[![Status](https://img.shields.io/badge/Status-TBA-orange)](#%D1%81%D1%82%D0%B0%D1%82%D1%83%D1%81-%D0%BF%D1%80%D0%BE%D0%B5%D0%BA%D1%82%D0%B0-tba)

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

## ⚠️ Статус проекта: TBA

Проект находится в **активной разработке**. Публичный релиз — по мере готовности.

**Почему TBA, а не релиз:**
- Проект разрабатывается одним человеком в свободное время
- P2P-синхронизация с шифрованием — сложная фича, требующая тщательного тестирования
- Мы не хотим выпускать сырой продукт

**Текущий прогресс:** ~8% от полного бэклога (см. [`BACKLOG.md`](./BACKLOG.md))

---

## ✨ Возможности

### Уже работает
- ✅ Tauri V2 + React 19 + TypeScript
- ✅ Rust backend со всеми плагинами
- ✅ SQLite для локального хранения
- ✅ SplashScreen с анимацией
- ✅ Базовая команда `get_local_ip`
- ✅ Tailwind CSS 3.4 + тёмная/светлая тема
- ✅ TanStack Router

### В разработке (MVP)
- 🚧 Создание/редактирование/удаление событий
- 🚧 Таймеры countdown/countup в реальном времени
- 🚧 Категории событий
- 🚧 Локальные уведомления
- 🚧 Экспорт/импорт JSON

### Планируется
- 🔜 mDNS discovery (обнаружение устройств в сети)
- 🔜 QR-коды и 6-значные коды сопряжения
- 🔜 WebSocket + ECDH + AES-256-GCM шифрование
- 🔜 P2P-синхронизация между устройствами
- 🔜 Автопереподключение при разрыве связи
- 🔜 Повторяющиеся события
- 🔜 Группы событий

---

## 📸 Скриншоты

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
- **mdns** — обнаружение устройств в локальной сети
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

## 🚀 Установка для разработки

### Требования
- **Node.js** 20+
- **Rust** (через [rustup](https://rustup.rs/))
- **Visual Studio Build Tools 2022** (Windows) с workload "Разработка классических приложений на C++"
- **WebView2** (Windows 10/11 — обычно уже установлен)

### Шаги

<pre><code># 1. Клонируем репозиторий
git clone https://github.com/DaniilGavrin/TimeToEvent.git
cd TimeToEvent

# 2. Устанавливаем frontend зависимости
npm install

# 3. Запускаем в режиме разработки
npm run tauri dev</code></pre>

Первый запуск может занять **5-10 минут** — Rust компилирует ~670 зависимостей с нуля. Последующие запуски — секунды.

### Сборка production-бинарника

<pre><code>npm run tauri build</code></pre>

Готовые бинарники появятся в `src-tauri/target/release/bundle/`:
- Windows: `.msi`, `.exe`
- Linux: `.deb`, `.AppImage`
- Android: `.apk` (требует Android SDK)

---

## 📁 Структура проекта

<pre><code>TimeToEvent/
├── src/                        # Frontend (React + TypeScript)
│   ├── components/
│   │   ├── ui/                 # Переиспользуемые UI компоненты
│   │   ├── layout/             # Header, Sidebar, BottomNav
│   │   ├── events/             # EventCard, EventForm, EventList
│   │   ├── pairing/            # QRScanner, PairingCode
│   │   └── SplashScreen.tsx
│   ├── routes/                 # TanStack Router
│   ├── stores/                 # Zustand stores
│   ├── lib/                    # Утилиты и хелперы
│   └── hooks/                  # Кастомные хуки
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
├── collect-app.ps1             # Скрипт экспорта кода
├── BACKLOG.md                  # Полный бэклог задач
├── ARCHITECTURE.md             # Архитектура проекта
├── README.md                   # Этот файл
└── LICENSE                     # MIT</code></pre>

---

## 🔒 Безопасность

- **Все данные хранятся локально** — ничего не уходит в интернет
- **P2P-синхронизация** — только между вашими устройствами в локальной сети
- **End-to-end шифрование** — X25519 (ECDH) + AES-256-GCM
- **Защита от MITM** — 6-значный код при сопряжении + HMAC
- **Блокировка после 3 неудачных попыток** ввода кода
- **Нет серверов, нет телеметрии, нет аналитики**

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

- [`BACKLOG.md`](./BACKLOG.md) — полный бэклог задач с приоритетами
- [`ARCHITECTURE.md`](./ARCHITECTURE.md) — архитектура проекта

---

## 🤝 Вклад

Проект разрабатывается одним человеком, но если у вас есть идеи или предложения — создавайте Issue или Pull Request.

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