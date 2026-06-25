# Protocol Specification — TimeToEvent P2P

> Детальная спецификация протокола синхронизации между устройствами.

---

## 📋 Обзор

TimeToEvent использует **децентрализованный P2P-протокол** для синхронизации данных между устройствами в локальной сети. Протокол состоит из 5 фаз:

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ─────────────┐    ┌─────────────┐
│  Discovery  │───▶│  Handshake  │───▶│ Verification│───▶│ Data Transfer│───▶│    Sync     │
│    (mDNS)   │    │   (ECDH)    │    │  (HMAC)     │    │  (AES-GCM)  │    │  (Delta)    │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
```

**Ключевые принципы:**
- **Local-first** — работает только в локальной сети, без выхода в интернет
- **Zero-trust** — каждое соединение требует криптографической верификации
- **End-to-end encryption** — все данные шифруются AES-256-GCM
- **Delta sync** — передаются только изменения, а не вся база данных

---

## 🔍 Фаза 1: Discovery (mDNS)

### Назначение

Обнаружение устройств TimeToEvent в локальной сети без предварительной настройки.

### Параметры

| Параметр | Значение |
|----------|----------|
| **Протокол** | UDP multicast |
| **Адрес** | `224.0.0.251` (mDNS) |
| **Порт** | `5354` (не 5353 — избежание конфликтов с Avahi/Bonjour) |
| **Сервис** | `_time2event._tcp.local` |
| **Интервал анонса** | 30 секунд |
| **Timeout stale peers** | 60 секунд |

### Формат пакета

```
_time2event._tcp.local<TAB>DEVICE_NAME<TAB>IP_ADDRESS<TAB>PORT
```

**Пример:**
```
_time2event._tcp.local	MyPC	192.168.1.100	8080
```

### Реализация

```rust
// src-tauri/src/discovery/mdns.rs
const MDNS_ADDR: Ipv4Addr = Ipv4Addr::new(224, 0, 0, 251);
const DISCOVERY_PORT: u16 = 5354;
const SERVICE_NAME: &str = "_time2event._tcp.local";

fn create_mdns_socket(port: u16) -> Result<UdpSocket, String> {
    let socket = Socket::new(Domain::IPV4, Type::DGRAM, Some(Protocol::UDP))?;
    socket.set_reuse_address(true)?;  // КЛЮЧЕВОЕ: SO_REUSEADDR
    socket.bind(&format!("0.0.0.0:{}", port))?;
    socket.join_multicast_v4(&MDNS_ADDR, &Ipv4Addr::UNSPECIFIED)?;
    socket.set_multicast_loop_v4(true)?;
    Ok(socket.into())
}
```

### Почему SO_REUSEADDR?

Позволяет нескольким процессам bind'ить один порт. Это нужно для:
- Одновременного advertising и scanning
- Нескольких экземпляров приложения (редко, но возможно)

### Поток данных

```
Устройство A                          Устройство B
    │                                     │
    │  ──announce (каждые 30 сек)──▶     │
    │  "_time2event._tcp.local\tA\t..."  │
    │                                     │
    │         ◀──announce──               │
    │         "_time2event._tcp.local\tB\t..."
    │                                     │
    │  [Обнаружено устройство B]          │
    │                                     │
    │  ──WebSocket connect──────────▶    │
    │                                     │
```

### Обработка stale peers

```rust
pub fn remove_stale_peers(&self, max_age_seconds: i64) {
    let now = chrono::Utc::now().timestamp();
    peers.retain(|p| now - p.last_seen < max_age_seconds);
}
```

---

## 🔐 Фаза 2: Handshake (ECDH X25519)

### Назначение

Установление общего секрета между двумя устройствами без передачи секретных ключей по сети.

### Параметры

| Параметр | Значение |
|----------|----------|
| **Алгоритм** | X25519 (Curve25519) |
| **Транспорт** | WebSocket (порт 8080) |
| **Формат handshake** | JSON |
| **Ключевая пара** | Статическая (генерируется при старте приложения) |

### Формат handshake сообщения

```typescript
interface HandshakeMessage {
  msg_type: "handshake";
  peer_id: string;      // UUID v4
  public_key: string;   // Base64-encoded X25519 public key (32 байта)
  timestamp: number;    // Unix timestamp (секунды)
}
```

### Поток handshake

```
Клиент (A)                              Сервер (B)
    │                                       │
    │  ──TCP connect:8080──────────────▶   │
    │                                       │
    │  ──WebSocket upgrade─────────────▶   │
    │                                       │
    │  ──HandshakeMessage (pub_key_A)──▶   │
    │                                       │
    │         ◀──HandshakeMessage (pub_key_B)
    │                                       │
    │  [Вычисление shared_secret]           │
    │  shared = X25519(priv_A, pub_key_B)   │
    │                                       │
    │         [Вычисление shared_secret]    │
    │         shared = X25519(priv_B, pub_key_A)
    │                                       │
    │  [shared_secret одинаковый!]          │
    │                                       │
```

### Вычисление session key

```rust
// src-tauri/src/crypto/ecdh.rs
impl KeyPair {
    pub fn compute_shared_secret(&self, other_public_b64: &str) -> Result<[u8; 32], String> {
        let other_bytes = base64::decode(other_public_b64)?;
        let other_public = PublicKey::from(other_bytes);
        let shared: SharedSecret = self.secret.diffie_hellman(&other_public);
        Ok(*shared.as_bytes())
    }
}

// src-tauri/src/crypto/aes.rs
pub fn derive_key(shared_secret: &[u8; 32], info: &[u8]) -> [u8; 32] {
    let hkdf = Hkdf::<Sha256>::new(None, shared_secret);
    let mut key = [0u8; 32];
    hkdf.expand(info, &mut key)?;
    key
}
```

**Info для HKDF:**
- Pairing: `"timetoevent-pairing-v1-{peer_id}"`
- Session: `"timetoevent-session-v1-{peer_id}"`

### Почему X25519?

- **Быстрый** — одна из самых быстрых кривых
- **Безопасный** — нет известных атак
- **Компактный** — 32 байта публичный ключ
- **Стандартный** — используется в Signal, TLS 1.3, WireGuard

---

## 🔢 Фаза 3: Verification (Pairing)

### Назначение

Защита от MITM-атак через визуальное сравнение 6-значных кодов.

### Параметры

| Параметр | Значение |
|----------|----------|
| **Длина кода** | 6 цифр (000000–999999) |
| **Алгоритм проверки** | HMAC-SHA256 (constant-time) |
| **Максимум попыток** | 3 |
| **Блокировка** | 30 секунд |
| **Генерация кода** | `rand::thread_rng()` |

### Поток pairing

```
Устройство A                          Устройство B
    │                                       │
    │  [Генерация key_pair]                 │
    │  [Вычисление shared_secret]           │
    │  [HKDF → session_key]                 │
    │                                       │
    │  [Генерация кода: "123456"]           │
    │  [HMAC(session_key, "123456")]        │
    │                                       │
    │  ──Показать код пользователю──        │
    │  "Введите этот код на устройстве B"   │
    │                                       │
    │         ◀──Пользователь вводит код──  │
    │         "123456"                      │
    │                                       │
    │  [HMAC(session_key, "123456")]        │
    │  [Сравнение HMAC (constant-time)]     │
    │                                       │
    │  [Совпадение!]                        │
    │  [Сохранение peer в БД]               │
    │  [Сохранение session_key в памяти]    │
    │                                       │
```

### Генерация кода

```rust
// src-tauri/src/crypto/codes.rs
pub fn generate_code() -> String {
    let mut rng = rand::thread_rng();
    let code: u32 = rng.gen_range(0..1_000_000);
    format!("{:06}", code)
}
```

### HMAC verification (constant-time)

```rust
pub fn verify_hmac(secret: &[u8], code: &str, expected_hmac: &str) -> bool {
    let expected_bytes = hex::decode(expected_hmac)?;
    let mut mac = HmacSha256::new_from_slice(secret)?;
    mac.update(code.as_bytes());
    // verify_slice использует constant-time сравнение
    mac.verify_slice(&expected_bytes).is_ok()
}
```

### Защита от brute force

```rust
// 3 попытки → блокировка на 30 секунд
session.attempts += 1;
if session.attempts >= 3 {
    session.blocked_until = Some(now + 30);
    return Err("Too many failed attempts. Blocked for 30 seconds");
}
```

### Почему HMAC, а не просто сравнение кодов?

- **Constant-time** — защита от timing attacks
- **Привязка к сессии** — код бесполезен без session_key
- **Невозможно подделать** — без знания shared_secret

---

## 🔒 Фаза 4: Data Transfer (AES-256-GCM)

### Назначение

Шифрование всех данных, передаваемых между устройствами.

### Параметры

| Параметр | Значение |
|----------|----------|
| **Алгоритм** | AES-256-GCM |
| **Размер ключа** | 32 байта (256 бит) |
| **Размер nonce** | 12 байт (96 бит) |
| **Генерация nonce** | `OsRng` (криптографически стойкий RNG) |
| **Формат сообщения** | Binary (nonce + ciphertext) |

### Формат зашифрованного сообщения

```
┌──────────────┬─────────────────────────────────┐
│    Nonce     │         Ciphertext              │
│  (12 байт)   │  (plaintext + 16 байт tag)      │
└──────────────┴─────────────────────────────────┘
```

### WsMessage структура

```typescript
interface WsMessage {
  msg_type: string;      // "sync_changes", "heartbeat", "sync_ack", etc.
  payload: string;       // JSON-сериализованные данные
  timestamp: number;     // Unix timestamp (секунды)
  signature: string | null;  // Опционально (пока не используется)
}
```

### Шифрование

```rust
// src-tauri/src/crypto/aes.rs
pub fn encrypt(key: &[u8; 32], plaintext: &[u8]) -> Result<Vec<u8>, String> {
    let cipher = Aes256Gcm::new_from_slice(key)?;
    let mut nonce_bytes = [0u8; 12];
    OsRng.fill_bytes(&mut nonce_bytes);
    let nonce = Nonce::from_slice(&nonce_bytes);
    let ciphertext = cipher.encrypt(nonce, plaintext)?;
    
    let mut result = Vec::with_capacity(12 + ciphertext.len());
    result.extend_from_slice(&nonce_bytes);
    result.extend_from_slice(&ciphertext);
    Ok(result)
}
```

### Расшифровка

```rust
pub fn decrypt(key: &[u8; 32], data: &[u8]) -> Result<Vec<u8>, String> {
    if data.len() < 12 {
        return Err("Data too short");
    }
    let cipher = Aes256Gcm::new_from_slice(key)?;
    let (nonce_bytes, ciphertext) = data.split_at(12);
    let nonce = Nonce::from_slice(nonce_bytes);
    cipher.decrypt(nonce, ciphertext)
}
```

### Отправка сообщения

```rust
// src-tauri/src/transport/websocket.rs
pub async fn send_message(&self, peer_id: &str, message: WsMessage) -> Result<(), String> {
    let peer = self.peers.get_mut(peer_id)?;
    let session_key = peer.session_key.ok_or("No session key")?;
    
    let json = serde_json::to_vec(&message)?;
    let encrypted = aes::encrypt(&session_key, &json)?;
    
    peer.sender.send(Message::Binary(encrypted.into())).await?;
    Ok(())
}
```

### Почему AES-256-GCM?

- **Аутентификация** — GCM включает authentication tag (16 байт)
- **Быстрый** — аппаратное ускорение (AES-NI)
- **Стандартный** — используется в TLS 1.3, Signal, WireGuard
- **Безопасный** — нет известных атак при правильном использовании nonce

### Важность уникального nonce

Каждый nonce должен быть **уникальным** для данного ключа. Повторное использование nonce с тем же ключом = полная компрометация шифра.

**Наша защита:**
- Nonce генерируется через `OsRng` (криптографически стойкий RNG)
- Вероятность коллизии: 2^96 ≈ 7.9 × 10^28 (практически невозможно)

---

## 🔄 Фаза 5: Sync (Delta Changes)

### Назначение

Синхронизация только изменений, а не всей базы данных.

### Параметры

| Параметр | Значение |
|----------|----------|
| **Стратегия** | Delta sync (только изменения) |
| **Хранение изменений** | Таблица `sync_log` |
| **Разрешение конфликтов** | Last-write-wins |
| **Batch apply** | В транзакции SQLite |
| **Heartbeat** | Каждые 30 секунд |
| **Heartbeat timeout** | 90 секунд |
| **Auto-reconnect** | Каждые 5 секунд + exponential backoff |

### Таблица sync_log

```sql
CREATE TABLE sync_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    entity_type TEXT NOT NULL,    -- "event", "reminder"
    entity_id TEXT NOT NULL,      -- UUID сущности
    action TEXT NOT NULL,         -- "create", "update", "delete"
    timestamp INTEGER NOT NULL,   -- Unix timestamp
    synced INTEGER DEFAULT 0      -- 0 = не синхронизировано, 1 = синхронизировано
);

CREATE INDEX idx_sync_log_entity ON sync_log(entity_type, entity_id);
```

### SyncChange структура

```typescript
interface SyncChange {
  entity_type: "event" | "reminder";
  entity_id: string;
  action: "create" | "update" | "delete";
  timestamp: number;
  data?: unknown;  // JSON-сериализованная сущность (кроме delete)
}
```

### Поток синхронизации

```
Устройство A                          Устройство B
    │                                       │
    │  [Создание события]                   │
    │  [INSERT INTO events]                 │
    │  [INSERT INTO sync_log]               │
    │                                       │
    │  [Обнаружено устройство B]            │
    │                                       │
    │  ──WebSocket connect─────────────▶   │
    │  ──ECDH handshake────────────────▶   │
    │  ──Pairing verification──────────▶   │
    │                                       │
    │  ──sync_changes message──────────▶   │
    │  [SyncChange × N]                     │
    │                                       │
    │         [Применение изменений]        │
    │         [BEGIN TRANSACTION]           │
    │         [INSERT OR REPLACE]           │
    │         [COMMIT]                      │
    │                                       │
    │         ◀──sync_ack────────────────── │
    │                                       │
    │  [mark_as_synced]                     │
    │  [UPDATE sync_log SET synced=1]       │
    │                                       │
```

### Last-write-wins

```rust
// src-tauri/src/commands/sync.rs
fn apply_change_internal(conn: &Connection, change: SyncChange) -> Result<ApplyResult, String> {
    // Проверяем локальную версию
    let local_timestamp: Option<i64> = conn.query_row(
        "SELECT MAX(timestamp) FROM sync_log WHERE entity_type = ?1 AND entity_id = ?2",
        params![change.entity_type, change.entity_id],
        |row| row.get(0),
    ).unwrap_or(None);
    
    // Если локальная версия новее — конфликт
    if let Some(local_ts) = local_timestamp {
        if local_ts > change.timestamp {
            conn.execute(
                "INSERT INTO sync_log (entity_type, entity_id, action, timestamp, synced)
                 VALUES (?1, ?2, 'conflict', ?3, 0)",
                params![change.entity_type, change.entity_id, now],
            )?;
            return Ok(ApplyResult {
                status: "skipped_conflict",
                entity_id: change.entity_id,
                message: Some(format!("Local version is newer ({} vs {})", local_ts, change.timestamp)),
            });
        }
    }
    
    // Применяем изменение
    match change.entity_type.as_str() {
        "event" => apply_event_change(conn, &change)?,
        "reminder" => apply_reminder_change(conn, &change)?,
        other => return Err(format!("Unknown entity type: {}", other)),
    }
    
    // Записываем в sync_log
    conn.execute(
        "INSERT INTO sync_log (entity_type, entity_id, action, timestamp, synced)
         VALUES (?1, ?2, ?3, ?4, 1)",
        params![change.entity_type, change.entity_id, change.action, change.timestamp],
    )?;
    
    Ok(ApplyResult {
        status: "applied",
        entity_id: change.entity_id,
        message: None,
    })
}
```

### Batch apply (в транзакции)

```rust
pub async fn apply_remote_batch(
    db: State<'_, Database>,
    changes: Vec<SyncChange>,
) -> Result<BatchApplyResult, String> {
    db.run(move |conn| {
        conn.execute_batch("BEGIN TRANSACTION")?;
        
        for change in changes {
            match apply_change_internal(conn, change) {
                Ok(result) => { /* счётчики */ }
                Err(e) => { /* обработка ошибок */ }
            }
        }
        
        conn.execute_batch("COMMIT")?;
        Ok(BatchApplyResult { applied, skipped, errors, results })
    }).await
}
```

### Broadcast локальных изменений

```rust
pub async fn broadcast_local_changes(
    db: &Database,
    ws: &WsServer,
    entity_type: String,
    entity_id: String,
    action: String,
) -> Result<(), String> {
    // Получаем данные изменения
    let change = db.run(move |conn| {
        let data = match entity_type.as_str() {
            "event" => get_event_json(conn, &entity_id)?,
            "reminder" => get_reminder_json(conn, &entity_id)?,
            _ => None,
        };
        Ok(SyncChange { entity_type, entity_id, action, timestamp: now, data })
    }).await?;
    
    // Отправляем всем подключённым peer
    let sync_msg = WsMessage {
        msg_type: "sync_changes",
        payload: serde_json::to_string(&vec![change])?,
        timestamp: now,
        signature: None,
    };
    
    let sent = ws.broadcast(sync_msg).await?;
    log::info!("Broadcast {} change to {} peers", action, sent);
    Ok(())
}
```

---

## 💓 Heartbeat

### Назначение

Проверка живости соединения и обнаружение разрывов.

### Параметры

| Параметр | Значение |
|----------|----------|
| **Интервал** | 30 секунд |
| **Timeout** | 90 секунд (3 missed heartbeats) |
| **Формат** | `WsMessage { msg_type: "heartbeat", payload: "ping" }` |

### Реализация

```rust
// src-tauri/src/transport/websocket.rs
async fn send_heartbeats(&self) {
    let mut peers = self.peers.lock().await;
    let now = chrono::Utc::now().timestamp();
    let mut dead_peers = Vec::new();
    
    for (peer_id, peer) in peers.iter_mut() {
        // Проверяем timeout
        if now - peer.last_heartbeat > 90 {
            dead_peers.push(peer_id.clone());
            continue;
        }
        
        // Отправляем heartbeat
        if let Some(key) = peer.session_key {
            let heartbeat = WsMessage {
                msg_type: "heartbeat",
                payload: "ping",
                timestamp: now,
                signature: None,
            };
            let json = serde_json::to_vec(&heartbeat)?;
            let encrypted = aes::encrypt(&key, &json)?;
            peer.sender.send(Message::Binary(encrypted.into())).await?;
        }
    }
    
    // Удаляем мёртвые peer'ы
    for peer_id in dead_peers {
        log::warn!("Peer {} timed out", peer_id);
        peers.remove(&peer_id);
        // Помечаем для переподключения
        desired_connections.get_mut(&peer_id).is_connecting = false;
    }
}
```

### Обработка heartbeat на сервере

```rust
if ws_msg.msg_type == "heartbeat" {
    peer.last_heartbeat = chrono::Utc::now().timestamp();
    continue;  // Не передаём в handler
}
```

---

## 🔁 Auto-reconnect

### Назначение

Автоматическое переподключение при разрыве связи.

### Параметры

| Параметр | Значение |
|----------|----------|
| **Интервал проверки** | 5 секунд |
| **Backoff** | Exponential: 2^n секунд |
| **Максимальный backoff** | 30 секунд |
| **Хранение desired** | `desired_connections` HashMap |

### ConnectionTarget структура

```rust
struct ConnectionTarget {
    ip: String,
    port: u16,
    public_key: String,
    retry_count: u32,
    next_retry_at: i64,      // Unix timestamp
    is_connecting: bool,     // true = прямо сейчас идёт подключение
}
```

### Reconnect loop

```rust
async fn reconnect_loop(&self) {
    let now = chrono::Utc::now().timestamp();
    
    // Собираем peer'ов для переподключения
    let to_reconnect: Vec<(String, String, u16, String)> = {
        let desired = self.desired_connections.lock().await;
        let peers = self.peers.lock().await;
        
        desired.iter()
            .filter(|(peer_id, target)| {
                !peers.contains_key(peer_id)           // Не в активных
                && !target.is_connecting                // Не идёт подключение
                && target.next_retry_at <= now          // Время наступило
            })
            .map(|(peer_id, target)| {
                (peer_id.clone(), target.ip.clone(), target.port, target.public_key.clone())
            })
            .collect()
    };
    
    // Пытаемся переподключиться
    for (peer_id, ip, port, public_key) in to_reconnect {
        match self.do_connect(&peer_id, &ip, port, &public_key).await {
            Ok(_) => {
                target.retry_count = 0;  // Сброс при успехе
            }
            Err(e) => {
                target.retry_count += 1;
                let backoff = std::cmp::min(30, 2i64.pow(target.retry_count));
                target.next_retry_at = now + backoff;
            }
        }
    }
}
```

### Exponential backoff

```
Попытка #1: 2^1 = 2 секунды
Попытка #2: 2^2 = 4 секунды
Попытка #3: 2^3 = 8 секунд
Попытка #4: 2^4 = 16 секунд
Попытка #5+: 30 секунд (максимум)
```

### Разница между disconnect_peer и disconnect_ws_peer

```rust
// disconnect_peer — полное отключение (удаляет из desired_connections)
pub async fn disconnect_peer(&self, peer_id: &str) {
    self.peers.lock().await.remove(peer_id);
    self.desired_connections.lock().await.remove(peer_id);  // ← НЕ будет переподключаться
}

// disconnect_ws_peer — только WS (остаётся в desired_connections)
pub async fn disconnect_ws_peer(&self, peer_id: &str) {
    self.peers.lock().await.remove(peer_id);
    // desired_connections НЕ трогаем ← будет переподключаться
}
```

---

## 🛡 Безопасность

### Защита от MITM

**Атака:** Злоумышленник перехватывает соединение и подменяет публичные ключи.

**Защита:** 6-значный код при pairing.

```
Устройство A: "123456"
Устройство B: "123456"  ← Пользователь визуально сравнивает

Если коды не совпадают → MITM-атака → отменить pairing
```

### Защита от brute force

**Атака:** Перебор 6-значных кодов (1 000 000 комбинаций).

**Защита:**
- Максимум 3 попытки
- Блокировка на 30 секунд после 3 неудач
- HMAC constant-time comparison

**Время взлома:**
- Без блокировки: 1 000 000 попыток × 1 мс = 1000 секунд ≈ 17 минут
- С блокировкой: 333 333 блокировки × 30 сек = 10 000 000 секунд ≈ 115 дней

### Защита от replay

**Атака:** Злоумышленник записывает зашифрованное сообщение и отправляет его позже.

**Защита:**
- Уникальный nonce в каждом сообщении (12 байт, OsRng)
- Timestamp в каждом сообщении
- AES-GCM authentication tag (16 байт)

### Защита от tampering

**Атака:** Злоумышленник изменяет зашифрованное сообщение.

**Защита:** AES-256-GCM включает authentication tag. Любое изменение ciphertext → расшифровка падает с ошибкой.

### Хранение ключей

| Ключ | Где хранится | Время жизни |
|------|--------------|-------------|
| **Static key pair** | В памяти (при старте генерируется) | До перезапуска приложения |
| **Session key** | В памяти (`ActiveConnections`) | До disconnect |
| **Public keys peers** | В БД (`peers.public_key`) | Постоянно |
| **6-digit codes** | В памяти (`PairingManager.sessions`) | До verification или cancel |

**Ключи НИКОГДА не записываются на диск** (кроме public keys peers).

---

## 📊 Диаграммы последовательности

### Полный поток синхронизации

```
Устройство A                          Устройство B
    │                                       │
    │  [Старт приложения]                   │
    │  [Генерация key_pair]                 │
    │                                       │
    │  ──mDNS announce (каждые 30 сек)──▶  │
    │                                       │
    │         ◀──mDNS announce──            │
    │                                       │
    │  [Обнаружено устройство B]            │
    │                                       │
    │  ──TCP connect:8080──────────────▶   │
    │  ──WebSocket upgrade─────────────▶   │
    │                                       │
    │  ──HandshakeMessage (pub_key_A)──▶   │
    │         ◀──HandshakeMessage (pub_key_B)
    │                                       │
    │  [Вычисление shared_secret]           │
    │  [HKDF → session_key]                 │
    │                                       │
    │  [Генерация кода: "123456"]           │
    │                                       │
    │  ──Показать код пользователю──        │
    │                                       │
    │         ◀──Пользователь вводит код──  │
    │                                       │
    │  [HMAC verification]                  │
    │  [Сохранение peer в БД]               │
    │  [Сохранение session_key в памяти]    │
    │                                       │
    │  ──sync_changes message──────────▶   │
    │  [SyncChange × N]                     │
    │                                       │
    │         [Применение изменений]        │
    │         [BEGIN TRANSACTION]           │
    │         [INSERT OR REPLACE]           │
    │         [COMMIT]                      │
    │                                       │
    │         ◀──sync_ack────────────────── │
    │                                       │
    │  [mark_as_synced]                     │
    │                                       │
    │  ──heartbeat (каждые 30 сек)──▶      │
    │         ◀──heartbeat──                │
    │                                       │
    │  [Разрыв соединения]                  │
    │                                       │
    │  [Reconnect loop (каждые 5 сек)]      │
    │  [Exponential backoff]                │
    │                                       │
    │  ──TCP connect:8080──────────────▶   │
    │  ──WebSocket upgrade─────────────▶   │
    │  ──HandshakeMessage──────────────▶   │
    │         ◀──HandshakeMessage           │
    │                                       │
    │  [Соединение восстановлено]           │
    │                                       │
```

---

## 📚 Связанные документы

- [`ARCHITECTURE.md`](./ARCHITECTURE.md) — общая архитектура проекта
- [`CRYPTO.md`](./CRYPTO.md) — детальное описание криптографии
- [`API.md`](./API.md) — документация Tauri команд
- [`USAGE.md`](./USAGE.md) — как пользоваться приложением

---

<div align="center">
*© 2026 ByteWizard*
</div>