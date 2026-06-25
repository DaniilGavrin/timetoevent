# Troubleshooting — Решение типичных проблем

> Сборник проблем и решений, с которыми можно столкнуться при установке, сборке и использовании TimeToEvent.

---

##  Как собрать логи для отладки

Прежде чем разбираться с проблемой — собери логи. Это сэкономит время.

### Rust backend логи

```bash
# Запуск с подробным логированием
RUST_LOG=debug npm run tauri dev

# Только ошибки
RUST_LOG=error npm run tauri dev

# Конкретные модули
RUST_LOG=timetoevent=debug,tokio=warn npm run tauri dev
```

Логи пишутся в:
- **Windows:** `%APPDATA%\rs.bytewizard.timetoevent\logs\`
- **Linux:** `~/.local/share/timetoevent/logs/`

### Frontend логи

Открой DevTools в окне приложения:
- **Windows/Linux:** `Ctrl + Shift + I`
- **macOS:** `Cmd + Option + I`

В консоли будут видны ошибки React и Tauri IPC.

### Tauri CLI логи

```bash
# Подробный вывод сборки
npm run tauri build -- --debug --verbose
```

---

##  Установка и зависимости

### Rust не устанавливается / rustup не работает

**Симптом:** `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh` падает.

**Причины:**
- Нет интернета или блокировка домена
- Антивирус блокирует скрипт
- Неправильный прокси

**Решение:**
1. Проверь интернет: `curl -I https://sh.rustup.rs`
2. Если прокси — настрой переменные:
   ```bash
   export https_proxy=http://127.0.0.1:7890
   export http_proxy=http://127.0.0.1:7890
   ```
3. Скачай `rustup-init.exe` вручную с [rustup.rs](https://rustup.rs/) и запусти

---

### Ошибка "linker `link.exe` not found" (Windows)

**Симптом:**
```
error: linker `link.exe` not found
```

**Причина:** Не установлен MSVC toolchain или не запущен из правильного терминала.

**Решение:**
1. Переустанови **Visual Studio Build Tools 2022** с workload *"Разработка классических приложений на C++"*
2. Запускай команду из **"x64 Native Tools Command Prompt for VS 2022"** (не из обычного cmd!)
3. Проверь: `where link.exe` — должен показать путь к MSVC

---

### Ошибка "gcc not found" / "cc not found" (Linux)

**Симптом:**
```
error: linker `cc` not found
```

**Причина:** Не установлены базовые компиляторы.

**Решение:**
```bash
# Ubuntu/Debian
sudo apt install build-essential

# Fedora
sudo dnf install gcc gcc-c++ make

# Arch
sudo pacman -S base-devel
```

---

### Таймауты при скачивании зависимостей Rust

**Симптом:**
```
error: failed to download `...`
caused by: timeout
```

**Причина:** crates.io медленно работает из СНГ.

**Решение:** Настрой зеркало rsproxy. Создай `~/.cargo/config.toml`:

```toml
[source.crates-io]
replace-with = 'rsproxy-sparse'

[source.rsproxy-sparse]
registry = "sparse+https://rsproxy.cn/index/"

[net]
git-fetch-with-cli = true
```

Если rsproxy не работает — попробуй альтернативу:
```toml
[source.crates-io]
replace-with = 'ustc'

[source.ustc]
registry = "sparse+https://mirrors.ustc.edu.cn/crates.io-index/"
```

---

### Ошибка "webkit2gtk-4.1 not found" (Linux)

**Симптом:**
```
error: failed to run custom build command for `tauri`
Package webkit2gtk-4.1 was not found
```

**Причина:** Не установлены системные зависимости Tauri.

**Решение:**
```bash
# Ubuntu/Debian
sudo apt install libwebkit2gtk-4.1-dev libgtk-3-dev \
  libayatana-appindicator3-dev librsvg2-dev patchelf

# Fedora
sudo dnf install webkit2gtk4.1-devel gtk3-devel \
  libappindicator-gtk3-devel librsvg2-devel

# Arch
sudo pacman -S webkit2gtk-4.1 gtk3 libappindicator-gtk3 librsvg
```

---

### Ошибка "WebView2 not found" (Windows)

**Симптом:** Приложение не запускается, белый экран или ошибка.

**Причина:** WebView2 не установлен (редко на Windows 10/11, но бывает).

**Решение:**
1. Скачай [WebView2 Bootstrapper](https://developer.microsoft.com/en-us/microsoft-edge/webview2/)
2. Запусти установщик
3. Перезапусти приложение

---

## 🚀 Запуск и разработка

### Vite dev-сервер не открывается / белый экран

**Симптом:** Tauri запустился, но окно пустое или "Unable to connect to localhost:1420".

**Причина:** TUN-прокси (Happ, Clash, V2Ray, WireGuard) перехватывает localhost.

**Решение:**
1. **Отключи TUN-режим** в прокси-приложении
2. Обычный system proxy работает нормально — его можно оставить
3. Альтернатива — добавь исключение для `localhost` и `127.0.0.1`

---

### Порт 1420 уже занят

**Симптом:**
```
Error: Port 1420 is already in use
```

**Решение:**
```bash
# Найди процесс
# Windows
netstat -ano | findstr :1420
taskkill /PID <PID> /F

# Linux
lsof -i :1420
kill -9 <PID>
```

Или измени порт в `vite.config.ts`:
```typescript
server: {
  port: 1421,  // любой свободный
  strictPort: true,
}
```

---

### HMR (hot reload) не работает

**Симптом:** Изменения в коде не применяются автоматически, нужно перезапускать.

**Причины:**
- Tauri watcher игнорирует `src-tauri/` (это нормально — Rust нужно перекомпилировать)
- Фронтенд HMR сломался из-за ошибки в коде

**Решение:**
1. Проверь консоль DevTools на ошибки
2. Для Rust-изменений — нужен полный рестарт (`Ctrl+C` → `npm run tauri dev`)
3. Для frontend — должно работать мгновенно

---

### "First build takes forever" (10–20 минут)

**Симптом:** Первый `npm run tauri dev` компилируется очень долго.

**Это нормально.** Rust компилирует ~670 зависимостей с нуля.

**Как ускорить:**
- Установи `sccache` для кэширования:
  ```bash
  cargo install sccache
  export RUSTC_WRAPPER=sccache
  ```
- Используй `mold` линкер вместо `ld` (Linux):
  ```bash
  sudo apt install mold
  # В ~/.cargo/config.toml
  [target.x86_64-unknown-linux-gnu]
  linker = "clang"
  rustflags = ["-C", "link-arg=-fuse-ld=mold"]
  ```

Последующие сборки — секунды (инкрементальная компиляция).

---

## 📱 Android

### "NDK not found" при сборке APK

**Симптом:**
```
error: failed to run custom build command
NDK_HOME is not set
```

**Решение:**
1. Проверь путь к NDK:
   ```bash
   ls $ANDROID_HOME/ndk/
   ```
2. Установи правильный `NDK_HOME` в `~/.bashrc`:
   ```bash
   export NDK_HOME="$ANDROID_HOME/ndk/26.1.10909125"
   ```
3. Перезапусти терминал

---

### "No Android device found"

**Симптом:** `npm run tauri android dev` не находит устройство.

**Решение:**
1. Включи **USB-отладку** на телефоне (Настройки → О телефоне → 7 раз тап по "Номер сборки" → Developer options → USB debugging)
2. Проверь: `adb devices` — должно показать устройство
3. Если устройство не видно — установи драйверы (для Windows)
4. Для эмулятора — запусти его в Android Studio

---

### APK не устанавливается на устройство

**Симптом:** "App not installed" или "Parse error".

**Причины:**
- Не включена установка из неизвестных источников
- Несоответствие архитектуры (arm64 vs armv7)
- Подпись APK

**Решение:**
1. Включи "Install unknown apps" для файлового менеджера
2. Для debug-сборки — подпись не нужна
3. Для release — настрой keystore в `build.gradle`

---

### Эмулятор Android тормозит

**Решение:**
1. Включи **Hardware Acceleration** (HAXM или Hyper-V)
2. Используй **x86_64** образ вместо ARM
3. Выдели больше RAM (4 GB+) в AVD Manager
4. Используй **Google Play** образы — они оптимизированы

---

## 🌐 Сеть и P2P

### mDNS не находит устройства в сети

**Симптом:** Список устройств пуст, хотя оба устройства в одной сети.

**Причины:**
- Устройства в разных подсетях
- Файрвол блокирует порт 5354
- Роутер изолирует клиентов (AP isolation)
- mDNS не работает в некоторых корпоративных сетях

**Решение:**
1. Проверь, что оба устройства в **одной WiFi-сети** (не guest network)
2. Отключи файрвол на время теста:
   ```bash
   # Linux
   sudo ufw disable
   # Windows — через Settings → Firewall
   ```
3. Проверь порт:
   ```bash
   # Должен слушать
   netstat -ulnp | grep 5354
   ```
4. В будущих версиях будет ручной ввод IP как fallback

---

### WebSocket соединение не устанавливается

**Симптом:** Peer обнаружен через mDNS, но WS handshake падает.

**Причины:**
- Порт 8080 заблокирован
- Неправильный public key
- Race condition при handshake

**Решение:**
1. Проверь логи Rust: `RUST_LOG=debug npm run tauri dev`
2. Убедись, что порт 8080 свободен:
   ```bash
   netstat -tlnp | grep 8080
   ```
3. Проверь, что public key валидный base64 (32 байта после декодирования)

---

### "Too many attempts. Blocked for 30 seconds"

**Симптом:** При вводе 6-значного кода появляется ошибка блокировки.

**Причина:** 3 неудачных попытки ввода кода.

**Решение:**
- Подожди 30 секунд
- Введи код аккуратно (код регенерируется при каждом новом pairing)
- Если код не совпадает — проверь, что оба устройства показывают **одинаковый** код

---

### Автопереподключение не работает

**Симптом:** После разрыва связи peer не переподключается.

**Причина:** Peer удалён из `desired_connections` (например, через `disconnect_peer`).

**Решение:**
- `disconnect_peer` — полное отключение (удаляет из desired)
- Если нужно переподключение — не вызывай `disconnect_peer`, просто закрой приложение
- Reconnect loop срабатывает каждые 5 секунд с exponential backoff

---

##  База данных

### "database is locked"

**Симптом:**
```
Error: database is locked
```

**Причина:** Несколько потоков пытаются писать в SQLite одновременно.

**Решение:**
- В текущей архитектуре это маловероятно (Mutex вокруг Connection)
- Если всё же случилось — перезапусти приложение
- Проверь, что нет zombie-процессов: `ps aux | grep timetoevent`

---

### "no such table: events"

**Симптом:**
```
Error: no such table: events
```

**Причина:** Миграции не запустились или БД повреждена.

**Решение:**
1. Удали файл БД:
   ```bash
   # Windows
   del %APPDATA%\rs.bytewizard.timetoevent\timetoevent.db
   # Linux
   rm ~/.local/share/timetoevent/timetoevent.db
   ```
2. Перезапусти приложение — миграции создадут таблицы заново

---

### Данные пропали после обновления

**Симптом:** После обновления версии приложения события исчезли.

**Причина:** Изменился `app_data_dir` (например, при смене identifier в `tauri.conf.json`).

**Решение:**
1. Найди старую БД:
   ```bash
   find ~ -name "timetoevent.db" 2>/dev/null
   ```
2. Скопируй в новый `app_data_dir`
3. Не меняй `identifier` в `tauri.conf.json` после релиза!

---

## 🔒 Криптография

### "Invalid base64" при handshake

**Симптом:**
```
Error: Invalid base64: ...
```

**Причина:** Public key повреждён или неправильный формат.

**Решение:**
- Public key должен быть валидным base64 (44 символа для X25519)
- Проверь, что key не обрезан при передаче
- Regenerate key pair и начни pairing заново

---

### "Decryption failed" при получении сообщений

**Симптом:**
```
Error: Decryption failed: ...
```

**Причины:**
- Session key не совпадает (разные shared secrets)
- Сообщение повреждено
- Replay attack (nonce уже использован)

**Решение:**
1. Перезапусти приложение на обоих устройствах
2. Начни pairing заново
3. Проверь, что нет двух экземпляров приложения

---

### Ключи потерялись после перезапуска

**Это не баг, а фича.** Session keys хранятся только в памяти.

**Почему так:**
- Безопасность — ключи не на диске
- При каждом запуске генерируется новый key pair
- Pairing сохраняется в БД (is_trusted = 1), но session key пересоздаётся

**Решение:** Никакое. Это правильное поведение.

---

##  Производительность

### Приложение потребляет много CPU

**Симптом:** Диспетчер задач показывает 20-30% CPU в фоне.

**Причины:**
- mDNS сканирование каждые 30 секунд
- WebSocket heartbeat каждые 30 секунд
- Reconnect loop каждые 5 секунд

**Решение:**
- Это нормально для активной синхронизации
- Если peer'ов нет — потребление должно быть минимальным
- В будущих версиях будет "тихий режим"

---

### Таймеры тормозят при большом количестве событий

**Симптом:** UI лагает при 100+ событиях.

**Решение:**
- В будущих версиях: виртуализация списков (react-window)
- Временно: используй фильтры и поиск
- Оптимизация рендеров через `React.memo`

---

### Большой размер бандла

**Симптом:** APK > 50 MB или бинарник > 30 MB.

**Решение:**
```bash
# Анализ бандла
npm run build
npx vite-bundle-visualizer

# Оптимизация
# 1. Code splitting
const EventForm = lazy(() => import('./components/EventForm'))

# 2. Tree shaking (уже работает с Vite)
# 3. Сжатие
npm run tauri build -- --target x86_64-unknown-linux-gnu
```

---

## 🔄 Обновления

### "No updates available" хотя новая версия есть

**Симптом:** Приложение не видит обновление.

**Причины:**
- Неправильный `pubkey` в `tauri.conf.json`
- Неправильный URL в `endpoints`
- Обновление не подписано

**Решение:**
1. Сгенерируй ключи:
   ```bash
   npm run tauri signer generate -w ~/.tauri/timetoevent.key
   ```
2. Пропиши публичный ключ в `tauri.conf.json`
3. Создай `update.json` на GitHub Gist:
   ```json
   {
     "version": "0.2.0",
     "notes": "New features",
     "pub_date": "2026-06-25T12:00:00Z",
     "platforms": {
       "linux-x86_64": {
         "signature": "...",
         "url": "https://github.com/.../timetoevent.AppImage"
       }
     }
   }
   ```

---

### Обновление не устанавливается

**Симптом:** Скачалось, но не применилось.

**Причина:** Неправильная подпись или несовместимая версия.

**Решение:**
1. Проверь подпись в логах
2. Убедись, что `version` в `update.json` > текущей версии
3. Попробуй установить вручную из GitHub Releases

---

##  UI и темы

### Тема не переключается

**Симптом:** Кнопка переключения темы не работает.

**Причина:** В текущей версии тема переключается только по системным настройкам.

**Решение:**
- Измени тему в настройках ОС
- В будущих версиях будет ручной переключатель

---

### Анимации лагают

**Симптом:** Framer Motion анимации дергаются.

**Причины:**
- Слабое GPU
- Включён `prefers-reduced-motion`
- Слишком много анимаций одновременно

**Решение:**
1. Проверь `prefers-reduced-motion` в ОС
2. Обнови драйверы GPU
3. В коде добавь:
   ```typescript
   const prefersReducedMotion = useMediaQuery('(prefers-reduced-motion: reduce)')
   ```

---

## 🐛 Разное

### "Task join error" в Rust

**Симптом:**
```
Error: Task join error: task was cancelled
```

**Причина:** Tokio задача отменена (например, при закрытии приложения).

**Решение:**
- Это нормально при shutdown
- Если происходит в работе — проверь, нет ли паники в задаче
- Добавь `.await` к важным задачам

---

### "Mutex poisoned"

**Симптом:**
```
Error: Mutex poisoned: ...
```

**Причина:** Поток упал с паникой, держа Mutex.

**Решение:**
1. Найди панику в логах (обычно выше этой ошибки)
2. Исправь причину паники
3. Как временное решение — перезапусти приложение

---

### Приложение не запускается после сборки

**Симптом:** `npm run tauri build` прошёл, но бинарник не запускается.

**Причины:**
- Не установлены runtime зависимости (WebView2, libwebkit2gtk)
- Неправильная архитектура
- Антивирус блокирует

**Решение:**
1. Запусти из терминала — увидишь ошибку
2. Проверь зависимости (см. раздел INSTALL.md)
3. Добавь в исключения антивируса

---

## 📞 Не получилось решить?

Если проблема не описана здесь:

1. **Собери логи** (см. первый раздел)
2. **Проверь GitHub Issues:** [github.com/DaniilGavrin/TimeToEvent/issues](https://github.com/DaniilGavrin/TimeToEvent/issues)
3. **Создай новый Issue** с:
   - Описанием проблемы
   - Шагами воспроизведения
   - Логами
   - Версией ОС и приложения
4. **Напиши на email:** daniilgavrin@bytewizard.ru

---

## 📚 Связанные документы

- [`INSTALL.md`](./INSTALL.md) — установка и сборка
- [`USAGE.md`](./USAGE.md) — как пользоваться
- [`FAQ.md`](./FAQ.md) — частые вопросы
- [`ARCHITECTURE.md`](./ARCHITECTURE.md) — архитектура
- [`TODO`](./TODO) — бэклог задач

---

<div align="center">
*© 2026 ByteWizard*
</div>