# Установка и сборка TimeToEvent

> Полная инструкция по установке, настройке и сборке проекта для всех поддерживаемых платформ.

---

## 📋 Системные требования

### Общие (для всех платформ)

| Компонент | Минимальная версия | Рекомендуемая |
|-----------|-------------------|---------------|
| **Node.js** | 20.x | 22.x LTS |
| **npm** | 10.x | 10.x (идёт с Node) |
| **Rust** | 1.75+ | Стабильный канал через `rustup` |
| **Git** | 2.30+ | Последняя |

### Windows (10 / 11)

| Компонент | Примечания |
|-----------|------------|
| **Visual Studio Build Tools 2022** | Workload: *"Разработка классических приложений на C++"* |
| **WebView2** | Обычно предустановлен в Windows 10/11 |
| **Windows SDK 10.0.19041+** | Устанавливается вместе с Build Tools |

> ⚠️ При установке VS Build Tools обязательно отметь галочку **"MSVC v143"** и **"Windows 10/11 SDK"**. Без них Rust не скомпилируется.

### Linux (Ubuntu 22.04+, Fedora 38+, Arch)

Необходимые системные пакеты:

**Ubuntu / Debian:**

```bash
sudo apt update
sudo apt install -y \
  build-essential \
  curl \
  wget \
  file \
  libssl-dev \
  libgtk-3-dev \
  libayatana-appindicator3-dev \
  librsvg2-dev \
  libwebkit2gtk-4.1-dev \
  patchelf
```

**Fedora:**

```bash
sudo dnf install -y \
  gcc \
  gcc-c++ \
  make \
  curl \
  wget \
  file \
  openssl-devel \
  gtk3-devel \
  libappindicator-gtk3-devel \
  librsvg2-devel \
  webkit2gtk4.1-devel
```

**Arch:**

```bash
sudo pacman -S --needed \
  base-devel \
  curl \
  wget \
  file \
  openssl \
  gtk3 \
  libappindicator-gtk3 \
  librsvg \
  webkit2gtk-4.1
```

### Android (опционально)

| Компонент | Версия |
|-----------|--------|
| **Android Studio** | Последняя стабильная |
| **Android SDK** | API 24+ (Android 7.0) |
| **Android NDK** | r26+ |
| **JDK** | 17+ |
| **Rust target** | `aarch64-linux-android`, `armv7-linux-androideabi`, `x86_64-linux-android`, `i686-linux-android` |

---

## 🚀 Установка для разработки

### 1. Клонирование репозитория

```bash
git clone https://github.com/DaniilGavrin/TimeToEvent.git
cd TimeToEvent
```

### 2. Установка Rust (если ещё не установлен)

**Linux / macOS:**

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env
rustup default stable
```

**Windows:** скачай [rustup-init.exe](https://rustup.rs/) и запусти. При установке выбери **MSVC toolchain** (по умолчанию).

Проверка:

```bash
rustc --version
cargo --version
```

### 3. Настройка зеркала crates.io (для СНГ)

Если cargo медленно скачивает зависимости или выдаёт таймауты, настрой зеркало:

```bash
mkdir -p ~/.cargo
cat >> ~/.cargo/config.toml << 'EOF'
[source.crates-io]
replace-with = 'rsproxy-sparse'

[source.rsproxy]
registry = "https://rsproxy.cn/crates.io-index"

[source.rsproxy-sparse]
registry = "sparse+https://rsproxy.cn/index/"

[registries.rsproxy]
index = "https://rsproxy.cn/crates.io-index"

[net]
git-fetch-with-cli = true
EOF
```

> 💡 Зеркало `rsproxy.cn` — публичное, работает стабильно в РФ/СНГ. Если не работает — можно использовать `https://mirrors.tuna.tsinghua.edu.cn/crates.io-index/`.

### 4. Установка frontend-зависимостей

```bash
npm install
```

### 5. Запуск в режиме разработки

```bash
npm run tauri dev
```

**Первый запуск займёт 5–15 минут** — Rust компилирует ~670 зависимостей с нуля. Последующие запуски — секунды (работает инкрементальная компиляция).

Что происходит при `npm run tauri dev`:

1. Vite поднимает dev-сервер на `http://localhost:1420`
2. Cargo компилирует Rust backend
3. Tauri запускает WebView с подключением к Vite (HMR работает)
4. Откроется окно приложения

---

## 📦 Сборка production-бинарника

### Desktop (Windows / Linux)

```bash
npm run tauri build
```

Готовые бинарники появятся в `src-tauri/target/release/bundle/`:

| Платформа | Форматы |
|-----------|---------|
| **Windows** | `.msi`, `.exe` (NSIS installer) |
| **Linux** | `.deb`, `.AppImage` |

> 💡 Размер финального бинарника: ~8–15 MB (благодаря системному WebView вместо Electron).

### Android

#### Подготовка окружения

1. Установи Android Studio и SDK через SDK Manager:
   - **SDK Platforms:** Android 7.0 (API 24) и выше
   - **SDK Tools:** Android SDK Build-Tools, Android SDK Command-line Tools, Android NDK (r26+)

2. Добавь Rust targets:

```bash
rustup target add \
  aarch64-linux-android \
  armv7-linux-androideabi \
  x86_64-linux-android \
  i686-linux-android
```

3. Настрой переменные окружения (добавь в `~/.bashrc` или `~/.zshrc`):

```bash
export ANDROID_HOME="$HOME/Android/Sdk"
export NDK_HOME="$ANDROID_HOME/ndk/26.1.10909125"  # подставь свою версию
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"
```

4. Добавь в `~/.cargo/config.toml` конфиг линковщика для каждой архитектуры:

```toml
[target.aarch64-linux-android]
ar = "$NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ar"
linker = "$NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android24-clang"

[target.armv7-linux-androideabi]
ar = "$NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ar"
linker = "$NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/armv7a-linux-androideabi24-clang"

[target.x86_64-linux-android]
ar = "$NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ar"
linker = "$NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/x86_64-linux-android24-clang"

[target.i686-linux-android]
ar = "$NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ar"
linker = "$NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/i686-linux-android24-clang"
```

#### Сборка APK

```bash
# Инициализация Android-проекта (один раз)
npm run tauri android init

# Сборка APK
npm run tauri android build
```

APK появится в `src-tauri/gen/android/app/build/outputs/apk/`.

#### Запуск на устройстве / эмуляторе

```bash
# В режиме разработки (с HMR)
npm run tauri android dev
```

Перед этим:

- Включи **USB-отладку** на телефоне
- Подключи по USB или запусти эмулятор в Android Studio
- Проверь: `adb devices`

---

## 📁 Структура проекта

```
TimeToEvent/
├── src/                          # Frontend (React 19 + TypeScript)
│   ├── App.tsx                   # Корневой компонент
│   ├── main.tsx                  # Точка входа
│   ├── index.css                 # Глобальные стили + тема
│   ├── components/               # UI-компоненты
│   │   ├── ui/                   # Button, Input, Modal, ...
│   │   ├── layout/               # Header, Sidebar, BottomNav
│   │   ├── events/               # EventCard, EventForm, EventList
│   │   ├── pairing/              # QRScanner, PairingCode
│   │   └── SplashScreen.tsx
│   ├── routes/                   # TanStack Router (file-based)
│   ├── stores/                   # Zustand stores
│   ├── lib/                      # Утилиты и API-обёртки
│   └── hooks/                    # Кастомные React-хуки
│
├── src-tauri/                    # Backend (Rust)
│   ├── src/
│   │   ├── main.rs               # Точка входа
│   │   ├── lib.rs                # Tauri setup + плагины
│   │   ├── commands/             # Tauri-команды (invoke)
│   │   ├── discovery/            # mDNS
│   │   ├── transport/            # WebSocket
│   │   ├── crypto/               # ECDH + AES-256-GCM
│   │   ├── db/                   # SQLite + миграции
│   │   └── models/               # Модели данных
│   ├── Cargo.toml                # Rust-зависимости
│   ├── tauri.conf.json           # Конфиг Tauri
│   └── capabilities/             # Tauri permissions
│
├── docs/                         # Документация
├── package.json                  # Frontend-зависимости
├── vite.config.ts                # Vite конфиг
├── tailwind.config.js            # Tailwind конфиг
└── tsconfig.json                 # TypeScript конфиг
```

---

## 🛠 Полезные команды

| Команда | Описание |
|---------|----------|
| `npm run dev` | Только Vite dev-сервер (без Tauri) |
| `npm run tauri dev` | Полный dev-режим (Vite + Tauri + Rust) |
| `npm run build` | Только frontend-сборка |
| `npm run tauri build` | Полная production-сборка |
| `npm run tauri android dev` | Android dev-режим |
| `npm run tauri android build` | Android production-сборка |
| `npm run tauri android init` | Инициализация Android-проекта (один раз) |
| `cargo test` (в `src-tauri/`) | Rust unit-тесты |

---

## 🔐 Проверка подписей обновлений (опционально)

Для автообновлений через `tauri-plugin-updater` нужно сгенерировать ключи:

```bash
npm run tauri signer generate -w ~/.tauri/timetoevent.key
```

Публичный ключ пропиши в `src-tauri/tauri.conf.json` → `plugins.updater.pubkey`.

> ⚠️ **Никогда не коммить приватный ключ** (`*.key`) в репозиторий!

---

## 📚 Дополнительная документация

- [`README.md`](./README.md) — обзор проекта
- [`ARCHITECTURE.md`](./ARCHITECTURE.md) — архитектура
- [`USAGE.md`](./USAGE.md) — как пользоваться приложением
- [`CHANGELOG.md`](./CHANGELOG.md) — история изменений
- [`TROUBLESHOOTING.md`](./TROUBLESHOOTING.md) — решение типичных проблем
- [`TODO`](./TODO) — бэклог задач

---

<div align="center">
*© 2026 ByteWizard*
</div>