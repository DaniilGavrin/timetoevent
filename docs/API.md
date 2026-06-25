# API Reference — Tauri Commands

> Полная документация всех Rust-команд, доступных из frontend через `invoke()`.

---

## 📋 Обзор

Все команды вызываются из React через Tauri IPC:

```typescript
import { invoke } from '@tauri-apps/api/core';

// Пример
const events = await invoke<Event[]>('get_events');
```

**Правила:**
- Все команды асинхронные (кроме `get_local_ip`, `is_peer_connected`, `disconnect_peer`)
- Возвращают `Result<T, String>` — при ошибке возвращается строка с описанием
- Все timestamp в Unix формате (секунды)
- UUID в формате v4

---

## 🗂 Модели данных

### Event

```typescript
interface Event {
  id: string;              // UUID v4
  title: string;
  description: string | null;
  event_date: number;      // Unix timestamp (секунды)
  event_type: 'countdown' | 'countup';
  category: string | null;
  color: string | null;
  is_favorite: boolean;
  is_archived: boolean;
  created_at: number;
  updated_at: number;
}
```

### NewEvent

```typescript
interface NewEvent {
  title: string;
  description?: string;
  event_date: number;
  event_type: 'countdown' | 'countup';
  category?: string;
  color?: string;
}
```

### Reminder

```typescript
interface Reminder {
  id: string;
  event_id: string;
  remind_at: number;       // Unix timestamp
  message: string | null;
  is_sent: boolean;
  created_at: number;
}
```

### NewReminder

```typescript
interface NewReminder {
  event_id: string;
  remind_at: number;
  message?: string;
}
```

### Peer

```typescript
interface Peer {
  id: string;
  name: string;
  public_key: string;      // Base64-encoded X25519 public key
  last_seen: number | null;
  is_trusted: boolean;
  created_at: number;
}
```

### SyncChange

```typescript
interface SyncChange {
  entity_type: 'event' | 'reminder';
  entity_id: string;
  action: 'create' | 'update' | 'delete';
  timestamp: number;
  data?: unknown;          // JSON сериализованная сущность (кроме delete)
}
```

### SyncStatus

```typescript
interface SyncStatus {
  pending_changes: number;
  last_sync: number | null;
  total_synced: number;
  total_conflicts: number;
}
```

### DeltaResponse

```typescript
interface DeltaResponse {
  changes: SyncChange[];
  generated_at: number;
  device_id: string;       // Стабильный UUID устройства
}
```

### PairingRequest

```typescript
interface PairingRequest {
  peer_name: string;
  public_key: string;      // Base64-encoded X25519 public key
  device_info?: string;
}
```

### PairingResponse

```typescript
interface PairingResponse {
  peer_id: string;
  code: string;            // 6-значный код для подтверждения
  local_public_key: string;
}
```

### PairingStatus

```typescript
interface PairingStatus {
  peer_id: string;
  peer_name: string;
  is_verified: boolean;
  attempts: number;
  blocked_for_seconds: number | null;
}
```

### WsMessage

```typescript
interface WsMessage {
  msg_type: string;
  payload: string;
  timestamp: number;
  signature: string | null;
}
```

---

## 🖥 System

### `get_local_ip`

Получить локальный IP-адрес устройства.

**Параметры:** нет

**Возвращает:** `string` — IP-адрес (например, `"192.168.1.100"`)

**Пример:**
```typescript
const ip = await invoke<string>('get_local_ip');
console.log(ip); // "192.168.1.100"
```

---

## 📅 Events

### `create_event`

Создать новое событие.

**Параметры:**
```typescript
{
  newEvent: NewEvent
}
```

**Возвращает:** `Event` — созданное событие

**Пример:**
```typescript
const event = await invoke<Event>('create_event', {
  newEvent: {
    title: 'Отпуск в Турции',
    description: 'Лето 2026',
    event_date: 1782389291,
    event_type: 'countdown',
    category: 'Личное',
    color: '#10b981',
  },
});
```

**Ошибки:**
- `"Failed to insert event: ..."` — ошибка БД

---

### `get_events`

Получить список всех активных событий (не архивных), отсортированных по дате.

**Параметры:** нет

**Возвращает:** `Event[]`

**Пример:**
```typescript
const events = await invoke<Event[]>('get_events');
```

---

### `update_event`

Обновить существующее событие.

**Параметры:**
```typescript
{
  event: Event  // Полный объект события
}
```

**Возвращает:** `void`

**Пример:**
```typescript
await invoke('update_event', {
  event: {
    ...existingEvent,
    title: 'Новое название',
    updated_at: Date.now() / 1000,
  },
});
```

**Ошибки:**
- `"Failed to update event: ..."` — ошибка БД

---

### `delete_event`

Удалить событие (физически, не архивация).

**Параметры:**
```typescript
{
  eventId: string
}
```

**Возвращает:** `void`

**Пример:**
```typescript
await invoke('delete_event', { eventId: 'uuid-here' });
```

---

### `toggle_favorite`

Переключить статус избранного.

**Параметры:**
```typescript
{
  eventId: string
}
```

**Возвращает:** `boolean` — новое значение `is_favorite`

**Пример:**
```typescript
const isFavorite = await invoke<boolean>('toggle_favorite', {
  eventId: 'uuid-here',
});
```

---

## 🔔 Reminders

### `create_reminder`

Создать напоминание для события.

**Параметры:**
```typescript
{
  newReminder: NewReminder
}
```

**Возвращает:** `Reminder`

**Пример:**
```typescript
const reminder = await invoke<Reminder>('create_reminder', {
  newReminder: {
    event_id: 'uuid-event',
    remind_at: Date.now() / 1000 + 3600, // через 1 час
    message: 'Не забудь!',
  },
});
```

**Примечание:** Уведомление автоматически планируется через `tokio::spawn`. Если время уже прошло — показывается сразу.

---

### `get_reminders`

Получить все напоминания для конкретного события.

**Параметры:**
```typescript
{
  eventId: string
}
```

**Возвращает:** `Reminder[]` (отсортированы по `remind_at`)

**Пример:**
```typescript
const reminders = await invoke<Reminder[]>('get_reminders', {
  eventId: 'uuid-event',
});
```

---

### `delete_reminder`

Удалить напоминание.

**Параметры:**
```typescript
{
  reminderId: string
}
```

**Возвращает:** `void`

**Пример:**
```typescript
await invoke('delete_reminder', { reminderId: 'uuid-reminder' });
```

---

### `get_pending_reminders`

Получить все напоминания, которые должны были сработать, но ещё не отправлены (включая пропущенные).

**Параметры:** нет

**Возвращает:** `Reminder[]`

**Пример:**
```typescript
const pending = await invoke<Reminder[]>('get_pending_reminders');
```

**Примечание:** Используется при старте приложения для показа пропущенных уведомлений.

---

## 🔗 Pairing

### `start_pairing`

Начать процесс сопряжения с другим устройством.

**Параметры:**
```typescript
{
  request: PairingRequest
}
```

**Возвращает:** `PairingResponse`

**Пример:**
```typescript
const response = await invoke<PairingResponse>('start_pairing', {
  request: {
    peer_name: 'MyPhone',
    public_key: 'base64-encoded-public-key',
    device_info: 'Android 14',
  },
});
console.log(response.code); // "123456"
```

**Ошибки:**
- `"Failed to insert peer: ..."` — ошибка БД

---

### `verify_pairing_code`

Проверить 6-значный код сопряжения.

**Параметры:**
```typescript
{
  peerId: string,
  code: string  // 6 цифр
}
```

**Возвращает:** `boolean` — `true` если код верный

**Пример:**
```typescript
const verified = await invoke<boolean>('verify_pairing_code', {
  peerId: 'uuid-peer',
  code: '123456',
});
```

**Ошибки:**
- `"Pairing session not found."` — сессия истекла или не найдена
- `"Too many attempts. Try again in X seconds"` — блокировка
- `"Invalid code format. Must be 6 digits."` — неверный формат
- `"Invalid code. N attempts remaining"` — неверный код

---

### `cancel_pairing`

Отменить активное сопряжение.

**Параметры:**
```typescript
{
  peerId: string
}
```

**Возвращает:** `void`

**Пример:**
```typescript
await invoke('cancel_pairing', { peerId: 'uuid-peer' });
```

---

### `get_pairing_status`

Получить статус всех активных сессий сопряжения.

**Параметры:** нет

**Возвращает:** `PairingStatus[]`

**Пример:**
```typescript
const statuses = await invoke<PairingStatus[]>('get_pairing_status');
```

---

### `get_paired_devices`

Получить список всех доверенных (сопряжённых) устройств.

**Параметры:** нет

**Возвращает:** `Peer[]` (отсортированы по `last_seen DESC`)

**Пример:**
```typescript
const peers = await invoke<Peer[]>('get_paired_devices');
```

---

### `remove_peer`

Удалить доверенное устройство.

**Параметры:**
```typescript
{
  peerId: string
}
```

**Возвращает:** `void`

**Пример:**
```typescript
await invoke('remove_peer', { peerId: 'uuid-peer' });
```

---

### `update_peer_last_seen`

Обновить время последнего появления устройства.

**Параметры:**
```typescript
{
  peerId: string
}
```

**Возвращает:** `void`

**Пример:**
```typescript
await invoke('update_peer_last_seen', { peerId: 'uuid-peer' });
```

---

### `is_peer_connected`

Проверить, подключено ли устройство через WebSocket.

**Параметры:**
```typescript
{
  peerId: string
}
```

**Возвращает:** `boolean`

**Пример:**
```typescript
const connected = await invoke<boolean>('is_peer_connected', {
  peerId: 'uuid-peer',
});
```

---

### `disconnect_peer`

Отключить устройство (удаляет из `desired_connections` — не будет переподключаться автоматически).

**Параметры:**
```typescript
{
  peerId: string
}
```

**Возвращает:** `void`

**Пример:**
```typescript
await invoke('disconnect_peer', { peerId: 'uuid-peer' });
```

---

## 🔄 Sync

### `get_sync_status`

Получить общий статус синхронизации.

**Параметры:** нет

**Возвращает:** `SyncStatus`

**Пример:**
```typescript
const status = await invoke<SyncStatus>('get_sync_status');
console.log(status.pending_changes); // 5
```

---

### `get_pending_changes`

Получить все несинхронизированные изменения (delta).

**Параметры:** нет

**Возвращает:** `DeltaResponse`

**Пример:**
```typescript
const delta = await invoke<DeltaResponse>('get_pending_changes');
console.log(delta.changes.length); // 5
console.log(delta.device_id);      // "uuid-device"
```

---

### `mark_as_synced`

Отметить изменения как синхронизированные до определённого timestamp.

**Параметры:**
```typescript
{
  timestamp: number  // Unix timestamp
}
```

**Возвращает:** `number` — количество обновлённых записей

**Пример:**
```typescript
const updated = await invoke<number>('mark_as_synced', {
  timestamp: Date.now() / 1000,
});
```

---

### `apply_remote_change`

Применить одно удалённое изменение.

**Параметры:**
```typescript
{
  change: SyncChange
}
```

**Возвращает:** `ApplyResult`

```typescript
interface ApplyResult {
  status: 'applied' | 'skipped_conflict' | 'error';
  entity_id: string;
  message?: string;
}
```

**Пример:**
```typescript
const result = await invoke<ApplyResult>('apply_remote_change', {
  change: {
    entity_type: 'event',
    entity_id: 'uuid-event',
    action: 'update',
    timestamp: 1782389291,
    data: { /* Event object */ },
  },
});
```

---

### `apply_remote_batch`

Применить пакет удалённых изменений (в транзакции).

**Параметры:**
```typescript
{
  changes: SyncChange[]
}
```

**Возвращает:** `BatchApplyResult`

```typescript
interface BatchApplyResult {
  applied: number;
  skipped: number;
  errors: number;
  results: ApplyResult[];
}
```

**Пример:**
```typescript
const result = await invoke<BatchApplyResult>('apply_remote_batch', {
  changes: [...],
});
console.log(result.applied); // 3
console.log(result.skipped); // 1 (конфликт)
```

---

### `cleanup_old_sync_logs`

Удалить старые синхронизированные записи из `sync_log`.

**Параметры:**
```typescript
{
  days: number  // Удалить записи старше N дней
}
```

**Возвращает:** `number` — количество удалённых записей

**Пример:**
```typescript
const deleted = await invoke<number>('cleanup_old_sync_logs', {
  days: 30,
});
```

---

### `force_sync_all`

Сбросить флаг `synced` для всех записей — заставит пересинхронизировать всё.

**Параметры:** нет

**Возвращает:** `void`

**Пример:**
```typescript
await invoke('force_sync_all');
```

---

### `connect_to_peer`

Подключиться к устройству через WebSocket (добавляет в `desired_connections` для автопереподключения).

**Параметры:**
```typescript
{
  peerId: string,
  ip: string,
  port: number,
  public_key: string  // Base64-encoded X25519 public key
}
```

**Возвращает:** `void`

**Пример:**
```typescript
await invoke('connect_to_peer', {
  peerId: 'uuid-peer',
  ip: '192.168.1.100',
  port: 8080,
  public_key: 'base64-key',
});
```

---

### `send_ws_message`

Отправить зашифрованное сообщение подключённому устройству.

**Параметры:**
```typescript
{
  peerId: string,
  message: WsMessage
}
```

**Возвращает:** `void`

**Пример:**
```typescript
await invoke('send_ws_message', {
  peerId: 'uuid-peer',
  message: {
    msg_type: 'sync_changes',
    payload: JSON.stringify(changes),
    timestamp: Date.now() / 1000,
    signature: null,
  },
});
```

**Ошибки:**
- `"Peer uuid-peer not connected"` — устройство не подключено
- `"Peer uuid-peer has no session key"` — нет ключа сессии

---

### `get_ws_connected_peers`

Получить список ID всех подключённых через WebSocket устройств.

**Параметры:** нет

**Возвращает:** `string[]`

**Пример:**
```typescript
const peers = await invoke<string[]>('get_ws_connected_peers');
```

---

### `disconnect_ws_peer`

Отключить устройство от WebSocket (без удаления из `desired_connections`).

**Параметры:**
```typescript
{
  peerId: string
}
```

**Возвращает:** `void`

**Пример:**
```typescript
await invoke('disconnect_ws_peer', { peerId: 'uuid-peer' });
```

---

## ⚠️ Обработка ошибок

Все команды возвращают `Result<T, String>`. В frontend ошибки ловятся через `try/catch`:

```typescript
try {
  const event = await invoke<Event>('create_event', { newEvent });
} catch (error) {
  console.error('Failed to create event:', error);
  // error — это строка с описанием
}
```

**Типичные ошибки:**
- `"Failed to ..."` — ошибка БД
- `"Mutex poisoned: ..."` — паника в другом потоке (редко)
- `"Task join error: ..."` — задача отменена
- `"Pairing session not found."` — сессия истекла
- `"Too many attempts. Blocked for 30 seconds"` — блокировка pairing

---

## 🔐 Безопасность

- Все данные между устройствами шифруются **AES-256-GCM**
- Ключи сессии выводятся через **HKDF-SHA256** из **X25519 shared secret**
- 6-значные коды защищены **HMAC-SHA256** (constant-time сравнение)
- Session keys хранятся **только в памяти** (не на диске)

---

##  Связанные документы

- [`ARCHITECTURE.md`](./ARCHITECTURE.md) — архитектура проекта
- [`PROTOCOL.md`](./PROTOCOL.md) — протокол синхронизации
- [`CRYPTO.md`](./CRYPTO.md) — описание криптографии
- [`USAGE.md`](./USAGE.md) — как пользоваться приложением

---

<div align="center">
*© 2026 ByteWizard*
</div>