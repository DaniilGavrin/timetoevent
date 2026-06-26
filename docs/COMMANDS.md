# Справочник команд — TimeToEvent

> Полный список команд для разработки, сборки, тестирования и отладки проекта.

---

## 📦 npm / Node.js

| Команда | Описание |
|---------|----------|
| `npm install` | Установить frontend-зависимости |
| `npm run dev` | Запустить только Vite dev-сервер (без Tauri) |
| `npm run build` | Собрать только frontend (TypeScript + Vite) |
| `npm run preview` | Предпросмотр production-сборки |
| `npm run tauri` | Запустить Tauri CLI (показывает справку) |

---

## 🦀 Tauri CLI

### Desktop

| Команда | Описание |
|---------|----------|
| `npm run tauri dev` | Полный dev-режим: Vite + Tauri + Rust (hot reload) |
| `npm run tauri build` | Production-сборка для текущей платформы |
| `npm run tauri build -- --debug` | Debug-сборка (с символами отладки) |
| `npm run tauri build -- --target x86_64-unknown-linux-gnu` | Сборка под конкретный target |
| `npm run tauri info` | Показать информацию об окружении Tauri |
| `npm run tauri icon ./icon.png` | Сгенерировать иконки из исходника |

### Android

| Команда | Описание |
|---------|----------|
| `npm run tauri android init` | Инициализировать Android-проект (один раз) |
| `npm run tauri android dev` | Android dev-режим с HMR |
| `npm run tauri android build` | Production-сборка APK/AAB |
| `npm run tauri android build -- --apk` | Собрать только APK |
| `npm run tauri android build -- --aab` | Собрать AAB (для Google Play) |
| `npm run tauri android open` | Открыть проект в Android Studio |

### Updater (подпись обновлений)

| Команда | Описание |
|---------|----------|
| `npm run tauri signer generate -w ~/.tauri/timetoevent.key` | Сгенерировать пару ключей Ed25519 |
| `npm run tauri signer sign --private-key ~/.tauri/timetoevent.key file.AppImage` | Подписать бинарник |

---

## ⚙️ Cargo / Rust

### Сборка

| Команда | Описание |
|---------|----------|
| `cargo build` | Собрать проект (debug) |
| `cargo build --release` | Собрать проект (release, оптимизировано) |
| `cargo check` | Проверить код без сборки (быстро) |
| `cargo clean` | Очистить `target/` |
| `cargo run` | Собрать и запустить |

### Тесты

| Команда | Описание |
|---------|----------|
| `cargo test` | Запустить все unit-тесты |
| `cargo test --lib crypto` | Тесты только модуля `crypto` |
| `cargo test --lib mdns` | Тесты только модуля `mdns` |
| `cargo test -- --nocapture` | Тесты с выводом в консоль |
| `cargo test -- --test-threads=1` | Тесты в одном потоке (для отладки) |

### Качество кода

| Команда | Описание |
|---------|----------|
| `cargo fmt` | Форматировать код (rustfmt) |
| `cargo fmt -- --check` | Проверить форматирование без изменений |
| `cargo clippy` | Линтер Rust (поиск проблем) |
| `cargo clippy --all-targets --all-features -- -D warnings` | Строгий clippy (все warnings = ошибки) |
| `cargo clippy --fix` | Автоисправление простых проблем |

### Зависимости

| Команда | Описание |
|---------|----------|
| `cargo tree` | Дерево зависимостей |
| `cargo tree --duplicates` | Найти дублирующиеся версии |
| `cargo update` | Обновить зависимости до совместимых версий |
| `cargo outdated` | Показать устаревшие зависимости (требует `cargo-outdated`) |
| `cargo audit` | Проверить зависимости на уязвимости (требует `cargo-audit`) |

### Документация

| Команда | Описание |
|---------|----------|
| `cargo doc` | Сгенерировать rustdoc |
| `cargo doc --open` | Сгенерировать и открыть в браузере |
| `cargo doc --no-deps` | Документация только по проекту (без зависимостей) |

### Профилирование

| Команда | Описание |
|---------|----------|
| `cargo flamegraph --bin timetoevent` | Flamegraph (требует `cargo-flamegraph`) |
| `cargo build --release --timings` | Анализ времени компиляции |

---

## 🔧 Rustup

| Команда | Описание |
|---------|----------|
| `rustup default stable` | Установить стабильный toolchain по умолчанию |
| `rustup update` | Обновить все toolchains |
| `rustup show` | Показать текущую конфигурацию |
| `rustup target list --installed` | Список установленных target'ов |
| `rustup target add aarch64-linux-android` | Добавить Android target |
| `rustup target add x86_64-pc-windows-msvc` | Добавить Windows MSVC target |
| `rustup target add x86_64-unknown-linux-gnu` | Добавить Linux GNU target |
| `rustup component add rust-src` | Исходники стандартной библиотеки (нужны для cross-compile) |
| `rustup component add rustfmt clippy` | Форматтер и линтер |

---

## 📱 Android / ADB

| Команда | Описание |
|---------|----------|
| `adb devices` | Список подключённых устройств |
| `adb install app.apk` | Установить APK на устройство |
| `adb uninstall rs.bytewizard.timetoevent` | Удалить приложение |
| `adb logcat -s timetoevent` | Логи приложения (по тегу) |
| `adb logcat -c` | Очистить буфер логов |
| `adb shell` | Открыть shell на устройстве |
| `adb push file.txt /sdcard/` | Загрузить файл на устройство |
| `adb pull /sdcard/file.txt .` | Скачать файл с устройства |
| `adb reverse tcp:1420 tcp:1420` | Проброс порта для dev-сервера |
| `emulator -avd Pixel_6_API_33` | Запустить эмулятор |

---

## 🌿 Git

### Основные

| Команда | Описание |
|---------|----------|
| `git status` | Статус репозитория |
| `git add .` | Добавить все изменения в индекс |
| `git commit -m "feat(scope): description"` | Создать коммит |
| `git push` | Отправить изменения на remote |
| `git pull` | Получить и слить изменения |
| `git fetch` | Получить изменения без слияния |

### Ветки

| Команда | Описание |
|---------|----------|
| `git branch` | Список локальных веток |
| `git branch -a` | Все ветки (локальные + remote) |
| `git checkout -b feature/name` | Создать и переключиться на ветку |
| `git switch main` | Переключиться на ветку |
| `git branch -d feature/name` | Удалить ветку (после merge) |
| `git branch -D feature/name` | Принудительно удалить ветку |

### История

| Команда | Описание |
|---------|----------|
| `git log --oneline --graph --all` | Краткая история в виде графа |
| `git log --since="2026-06-01"` | История с даты |
| `git log --author="Daniil"` | История по автору |
| `git show <commit>` | Показать изменения в коммите |
| `git diff` | Несохранённые изменения |
| `git diff --cached` | Изменения в индексе |
| `git diff main...feature` | Разница между ветками |

### Откат

| Команда | Описание |
|---------|----------|
| `git reset --soft HEAD~1` | Отменить последний коммит (сохранить изменения) |
| `git reset --hard HEAD~1` | Отменить последний коммит (удалить изменения) |
| `git checkout -- file.tsx` | Отменить изменения в файле |
| `git stash` | Временно отложить изменения |
| `git stash pop` | Вернуть отложенные изменения |
| `git revert <commit>` | Создать коммит, отменяющий указанный |

### Rebase

| Команда | Описание |
|---------|----------|
| `git rebase main` | Перебазировать текущую ветку на main |
| `git rebase -i HEAD~3` | Интерактивный rebase последних 3 коммитов |
| `git rebase --abort` | Прервать rebase |
| `git rebase --continue` | Продолжить после разрешения конфликтов |

---

## 🔍 Отладка и диагностика

### Логи приложения

```bash
# Rust backend — подробные логи
RUST_LOG=debug npm run tauri dev

# Только ошибки
RUST_LOG=error npm run tauri dev

# Конкретные модули
RUST_LOG=timetoevent=debug,tokio=warn npm run tauri dev

# С выводом в файл
RUST_LOG=debug npm run tauri dev 2>&1 | tee debug.log
```

Логи пишутся в:
- **Windows:** `%APPDATA%\rs.bytewizard.timetoevent\logs\`
- **Linux:** `~/.local/share/timetoevent/logs/`

### Сеть

```bash
# Кто слушает порт 1420 (Vite)
netstat -ano | findstr :1420        # Windows
lsof -i :1420                       # Linux/macOS

# Кто слушает порт 8080 (WebSocket)
netstat -tlnp | grep 8080           # Linux
netstat -ano | findstr :8080        # Windows

# Кто слушает порт 5354 (mDNS)
netstat -ulnp | grep 5354           # Linux

# Проверить доступность порта
telnet 192.168.1.100 8080
curl http://localhost:1420
```

### Процессы

```bash
# Найти процесс приложения
ps aux | grep timetoevent           # Linux/macOS
tasklist | findstr timetoevent      # Windows

# Убить процесс
kill -9 <PID>                       # Linux/macOS
taskkill /PID <PID> /F              # Windows

# Мониторинг ресурсов
htop                                # Linux
top                                 # macOS
Task Manager                        # Windows
```

### База данных

```bash
# Открыть SQLite БД
sqlite3 ~/.local/share/timetoevent/timetoevent.db   # Linux
sqlite3 %APPDATA%\rs.bytewizard.timetoevent\timetoevent.db  # Windows

# Полезные SQL-команды внутри sqlite3
.tables                           # Список таблиц
.schema events                    # Схема таблицы
SELECT COUNT(*) FROM events;      # Количество событий
SELECT * FROM sync_log WHERE synced = 0;  # Несинхронизированные изменения
.quit                             # Выход
```

### Зависимости и бандл

```bash
# Анализ размера бандла
npm run build
npx vite-bundle-visualizer

# Размер APK
ls -lh src-tauri/gen/android/app/build/outputs/apk/

# Размер бинарника
ls -lh src-tauri/target/release/bundle/
```

---

## 🛠 Утилиты разработки

### sccache (кэш компиляции Rust)

```bash
cargo install sccache
export RUSTC_WRAPPER=sccache        # Linux/macOS
set RUSTC_WRAPPER=sccache           # Windows CMD
$env:RUSTC_WRAPPER="sccache"        # Windows PowerShell

# Статистика кэша
sccache --show-stats
sccache --zero-stats                # Сбросить счётчики
```

### mold (быстрый линкер, Linux)

```bash
sudo apt install mold

# В ~/.cargo/config.toml
[target.x86_64-unknown-linux-gnu]
linker = "clang"
rustflags = ["-C", "link-arg=-fuse-ld=mold"]
```

### cargo-watch (автопересборка при изменениях)

```bash
cargo install cargo-watch
cargo watch -x test                 # Автозапуск тестов
cargo watch -x "clippy --all-targets"  # Автозапуск clippy
cargo watch -x run                  # Автозапуск приложения
```

---

## 📊 Быстрые сниппеты

### Полный сброс и пересборка

```bash
# Очистить всё и собрать заново
rm -rf target/ dist/ node_modules/
npm install
npm run tauri build
```

### Сброс БД (для тестирования)

```bash
# Linux
rm ~/.local/share/timetoevent/timetoevent.db

# Windows
del %APPDATA%\rs.bytewizard.timetoevent\timetoevent.db

# macOS
rm ~/Library/Application\ Support/rs.bytewizard.timetoevent/timetoevent.db
```

### Проверка перед коммитом

```bash
# Rust
cargo fmt -- --check
cargo clippy --all-targets --all-features -- -D warnings
cargo test

# TypeScript
npx tsc --noEmit
npx prettier --check "src/**/*.{ts,tsx}"

# Всё вместе
cargo fmt -- --check && cargo clippy --all-targets -- -D warnings && cargo test && npx tsc --noEmit
```

---

##  Связанные документы

- [`INSTALL.md`](./INSTALL.md) — установка и настройка окружения
- [`TROUBLESHOOTING.md`](./TROUBLESHOOTING.md) — решение типичных проблем
- [`CONTRIBUTING.md`](./CONTRIBUTING.md) — гайд для контрибьюторов
- [`COMMITS.md`](./COMMITS.md) — правила написания коммитов

---

<div align="center">
*© 2026 ByteWizard*
</div>