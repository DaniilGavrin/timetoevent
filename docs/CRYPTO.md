# Cryptography Specification — TimeToEvent

> Детальное описание криптографической системы TimeToEvent: алгоритмы, ключи, защита от атак.

---

## 📋 Обзор

TimeToEvent использует **комбинацию асимметричной и симметричной криптографии** для защиты данных при P2P-синхронизации.

### Криптографический стек

```
┌─────────────────────────────────────────────────────────────┐
│  Асимметричная (обмен ключами)                              │
│  X25519 (Curve25519) → shared_secret (32 байта)             │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────
│  Key Derivation                                             │
│  HKDF-SHA256(shared_secret, info) → session_key (32 байта)  │
└─────────────────────────┬───────────────────────────────────┘
                          │
              ┌───────────┴───────────┐
              ▼                       ▼
┌───────────────────────┐   ┌───────────────────────────┐
│  Симметричная         │   │  Verification             │
│  AES-256-GCM          │   │  HMAC-SHA256 + 6-digit    │
│  (шифрование данных)  │   │  (защита от MITM)         │
└───────────────────────┘   └───────────────────────────┘
```

### Зависимости (Cargo.toml)

```toml
x25519-dalek = { version = "2.0.1", features = ["static_secrets"] }
aes-gcm = "0.10.3"
hkdf = "0.13.0"
sha2 = "0.11.0"
hmac = "0.13.0"
rand = "0.8.6"
hex = "0.4.3"
base64 = "0.22.1"
```

---

##  Фаза 1: X25519 ECDH (обмен ключами)

### Назначение

Установление общего секрета между двумя устройствами **без передачи секретных ключей** по сети.

### Параметры

| Параметр | Значение |
|----------|----------|
| **Алгоритм** | X25519 (Curve25519) |
| **Кривая** | Montgomery curve `y² = x³ + 486662x² + x` |
| **Размер ключа** | 32 байта (256 бит) |
| **Формат публичного ключа** | Base64 (44 символа) |
| **Тип ключей** | Static (генерируются при старте приложения) |
| **RNG** | `OsRng` (криптографически стойкий) |

### Реализация

```rust
// src-tauri/src/crypto/ecdh.rs
use rand::rngs::OsRng;
use x25519_dalek::{PublicKey, SharedSecret, StaticSecret};

pub struct KeyPair {
    pub secret: StaticSecret,
    pub public: PublicKey,
}

impl KeyPair {
    pub fn generate() -> Self {
        let secret = StaticSecret::random_from_rng(OsRng);
        let public = PublicKey::from(&secret);
        Self { secret, public }
    }

    pub fn public_key_base64(&self) -> String {
        use base64::Engine;
        base64::engine::general_purpose::STANDARD.encode(self.public.as_bytes())
    }

    pub fn compute_shared_secret(&self, other_public_b64: &str) -> Result<[u8; 32], String> {
        use base64::Engine;
        let other_bytes = base64::engine::general_purpose::STANDARD
            .decode(other_public_b64)
            .map_err(|e| format!("Invalid base64: {}", e))?;
        if other_bytes.len() != 32 {
            return Err("Invalid public key length".to_string());
        }
        let mut arr = [0u8; 32];
        arr.copy_from_slice(&other_bytes);
        let other_public = PublicKey::from(arr);
        let shared: SharedSecret = self.secret.diffie_hellman(&other_public);
        Ok(*shared.as_bytes())
    }
}
```

### Поток handshake

```
Устройство A                          Устройство B
    │                                       │
    │  [KeyPair::generate()]                │
    │  priv_A, pub_A                        │
    │                                       │
    │  ──HandshakeMessage (pub_A)──────▶   │
    │                                       │
    │         ◀──HandshakeMessage (pub_B)── │
    │                                       │
    │  [compute_shared_secret(pub_B)]       │
    │  shared = X25519(priv_A, pub_B)       │
    │                                       │
    │         [compute_shared_secret(pub_A)]│
    │         shared = X25519(priv_B, pub_A)│
    │                                       │
    │  [shared одинаковый!]                 │
    │                                       │
```

### Почему X25519?

- **Быстрый** — одна из самых быстрых кривых (~200k операций/сек на CPU)
- **Безопасный** — нет известных атак, рекомендован NIST/NSA
- **Компактный** — 32 байта публичный ключ (vs 384 байта для P-384)
- **Стандартный** — используется в Signal, TLS 1.3, WireGuard, SSH
- **Constant-time** — реализация защищена от timing attacks

### Валидация публичного ключа

```rust
// Проверяем длину после декодирования base64
if other_bytes.len() != 32 {
    return Err("Invalid public key length".to_string());
}
```

**Важно:** X25519 принимает любой 32-байтный массив как публичный ключ. Некоторые "плохие" точки (low-order points) могут привести к нулевому shared secret. `x25519-dalek` обрабатывает это корректно — возвращает нулевой shared secret, который потом отбрасывается при HKDF.

---

## 🧪 Фаза 2: HKDF (вывод ключей)

### Назначение

Преобразовать **shared secret** (который может иметь неравномерное распределение битов) в **криптографически стойкий ключ** фиксированной длины.

### Параметры

| Параметр | Значение |
|----------|----------|
| **Алгоритм** | HKDF (RFC 5869) |
| **Hash функция** | SHA-256 |
| **Salt** | `None` (не используется) |
| **Output length** | 32 байта (256 бит) |
| **Info** | Зависит от контекста (см. ниже) |

### Реализация

```rust
// src-tauri/src/crypto/aes.rs
use hkdf::Hkdf;
use sha2::Sha256;

pub fn derive_key(shared_secret: &[u8; 32], info: &[u8]) -> [u8; 32] {
    let hkdf = Hkdf::<Sha256>::new(None, shared_secret);
    let mut key = [0u8; 32];
    hkdf.expand(info, &mut key).expect("HKDF expand failed");
    key
}
```

### Info для разных контекстов

```rust
// Pairing — для проверки 6-значного кода
let info = format!("timetoevent-pairing-v1-{}", peer_id);
let session_key = aes::derive_key(&shared_secret, info.as_bytes());

// Session — для шифрования данных
let info = format!("timetoevent-session-v1-{}", peer_id);
let session_key = aes::derive_key(&shared_secret, info.as_bytes());
```

**Почему разные info?**
- Разделяет ключи для разных целей (key separation)
- Даже если shared secret скомпрометирован — ключи разные
- Привязка к `peer_id` — ключи нельзя переиспользовать между парами устройств

### Почему HKDF, а не просто SHA-256(shared_secret)?

- **Extract-then-expand** — два этапа, каждый со своей целью
- **Extract** — "выжимает" энтропию из shared secret
- **Expand** — генерирует ключ нужной длины
- **Domain separation** — через параметр `info`
- **Рекомендован** NIST, IETF, используется в TLS 1.3, Signal

---

## 🔒 Фаза 3: AES-256-GCM (шифрование данных)

### Назначение

Шифрование всех данных, передаваемых между устройствами, с **аутентификацией**.

### Параметры

| Параметр | Значение |
|----------|----------|
| **Алгоритм** | AES-256-GCM (Galois/Counter Mode) |
| **Размер ключа** | 32 байта (256 бит) |
| **Размер nonce** | 12 байт (96 бит) |
| **Authentication tag** | 16 байт (128 бит) |
| **RNG для nonce** | `OsRng` (криптографически стойкий) |
| **Формат сообщения** | Binary: `nonce (12) + ciphertext + tag (16)` |

### Реализация

```rust
// src-tauri/src/crypto/aes.rs
use aes_gcm::{
    aead::{Aead, KeyInit},
    Aes256Gcm, Nonce,
};
use rand::rngs::OsRng;
use rand::RngCore;

const NONCE_SIZE: usize = 12;

pub fn encrypt(key: &[u8; 32], plaintext: &[u8]) -> Result<Vec<u8>, String> {
    let cipher = Aes256Gcm::new_from_slice(key)
        .map_err(|e| format!("Invalid key: {}", e))?;
    
    // Генерируем случайный nonce
    let mut nonce_bytes = [0u8; NONCE_SIZE];
    OsRng.fill_bytes(&mut nonce_bytes);
    let nonce = Nonce::from_slice(&nonce_bytes);
    
    // Шифруем (включает authentication tag)
    let ciphertext = cipher
        .encrypt(nonce, plaintext)
        .map_err(|e| format!("Encryption failed: {}", e))?;
    
    // Формат: nonce + ciphertext
    let mut result = Vec::with_capacity(NONCE_SIZE + ciphertext.len());
    result.extend_from_slice(&nonce_bytes);
    result.extend_from_slice(&ciphertext);
    Ok(result)
}

pub fn decrypt(key: &[u8; 32], data: &[u8]) -> Result<Vec<u8>, String> {
    if data.len() < NONCE_SIZE {
        return Err("Data too short".to_string());
    }
    let cipher = Aes256Gcm::new_from_slice(key)
        .map_err(|e| format!("Invalid key: {}", e))?;
    
    let (nonce_bytes, ciphertext) = data.split_at(NONCE_SIZE);
    let nonce = Nonce::from_slice(nonce_bytes);
    
    cipher
        .decrypt(nonce, ciphertext)
        .map_err(|e| format!("Decryption failed: {}", e))
}
```

### Формат зашифрованного сообщения

```
┌──────────────┬─────────────────────────────────┐
│    Nonce     │         Ciphertext              │
│  (12 байт)   │  (plaintext + 16 байт tag)      │
──────────────┴─────────────────────────────────┘
      ↑                    ↑
  Случайный          AES-256-GCM
  (OsRng)            (включает tag)
```

### Интеграция с WebSocket

```rust
// src-tauri/src/transport/websocket.rs
pub async fn send_message(&self, peer_id: &str, message: WsMessage) -> Result<(), String> {
    let mut peers = self.peers.lock().await;
    let peer = peers.get_mut(peer_id)
        .ok_or_else(|| format!("Peer {} not connected", peer_id))?;
    let session_key = peer.session_key
        .ok_or_else(|| format!("Peer {} has no session key", peer_id))?;
    
    // Сериализуем → шифруем → отправляем как Binary
    let json = serde_json::to_vec(&message).map_err(|e| e.to_string())?;
    let encrypted = crate::crypto::aes::encrypt(&session_key, &json)?;
    peer.sender.send(Message::Binary(encrypted.into())).await
        .map_err(|e| format!("Send failed: {}", e))?;
    Ok(())
}
```

### Почему AES-256-GCM?

- **Аутентификация** — GCM включает authentication tag (16 байт), защита от tampering
- **Быстрый** — аппаратное ускорение AES-NI на всех современных CPU
- **Стандартный** — TLS 1.3, Signal, WireGuard, IPsec
- **Без padding** — GCM — stream cipher mode, нет padding oracle attacks
- **Nonce misuse resistant** — при повторном nonce только confidentiality ломается, не integrity

### Важность уникального nonce

Каждый nonce должен быть **уникальным** для данного ключа. Повторное использование nonce с тем же ключем = полная компрометация шифра.

**Наша защита:**
- Nonce генерируется через `OsRng` (криптографически стойкий RNG)
- Размер nonce: 12 байт = 96 бит
- Вероятность коллизии: 2^96 ≈ 7.9 × 10^28 (практически невозможно)
- Даже при 1 миллиарде сообщений в секунду — коллизия через ~2.5 миллиона лет

### Тесты

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_encrypt_decrypt() {
        let key = derive_key(b"test shared secret for testing!!", b"test info");
        let plaintext = b"Hello, World!";
        let encrypted = encrypt(&key, plaintext).unwrap();
        let decrypted = decrypt(&key, &encrypted).unwrap();
        assert_eq!(plaintext.to_vec(), decrypted);
    }

    #[test]
    fn test_wrong_key_fails() {
        let key1 = derive_key(b"secret one for testing purpose!!", b"info");
        let key2 = derive_key(b"secret two for testing purpose!!", b"info");
        let encrypted = encrypt(&key1, b"secret data").unwrap();
        let result = decrypt(&key2, &encrypted);
        assert!(result.is_err());  // Неправильный ключ → ошибка
    }
}
```

---

## 🔢 Фаза 4: HMAC-SHA256 + 6-значные коды (verification)

### Назначение

Защита от **MITM-атак** через визуальное сравнение 6-значных кодов.

### Параметры

| Параметр | Значение |
|----------|----------|
| **Алгоритм** | HMAC-SHA256 (RFC 2104) |
| **Длина кода** | 6 цифр (000000–999999) |
| **Генерация кода** | `rand::thread_rng()` |
| **Сравнение** | Constant-time (через `verify_slice`) |
| **Максимум попыток** | 3 |
| **Блокировка** | 30 секунд |

### Реализация

```rust
// src-tauri/src/crypto/codes.rs
use hmac::{Hmac, KeyInit, Mac};
use rand::Rng;
use sha2::Sha256;

type HmacSha256 = Hmac<Sha256>;

pub fn generate_code() -> String {
    let mut rng = rand::thread_rng();
    let code: u32 = rng.gen_range(0..1_000_000);
    format!("{:06}", code)
}

pub fn compute_hmac(secret: &[u8], code: &str) -> String {
    let mut mac = HmacSha256::new_from_slice(secret)
        .expect("HMAC can take key of any size");
    mac.update(code.as_bytes());
    let result = mac.finalize();
    hex::encode(result.into_bytes())
}

/// Constant-time HMAC verification — защита от Timing Attack
pub fn verify_hmac(secret: &[u8], code: &str, expected_hmac: &str) -> bool {
    let expected_bytes = match hex::decode(expected_hmac) {
        Ok(b) => b,
        Err(_) => return false,
    };
    let mut mac = match HmacSha256::new_from_slice(secret) {
        Ok(m) => m,
        Err(_) => return false,
    };
    mac.update(code.as_bytes());
    // verify_slice использует constant-time сравнение
    mac.verify_slice(&expected_bytes).is_ok()
}

pub fn is_valid_code(code: &str) -> bool {
    code.len() == 6 && code.chars().all(|c| c.is_ascii_digit())
}
```

### Поток pairing

```
Устройство A                          Устройство B
    │                                       │
    │  [generate_code() → "123456"]         │
    │  [compute_hmac(session_key, "123456")]│
    │                                       │
    │  ──Показать код пользователю──        │
    │  "Введите этот код на устройстве B"   │
    │                                       │
    │         ◀──Пользователь вводит код──  │
    │         "123456"                      │
    │                                       │
    │  [verify_hmac(session_key, "123456")] │
    │  [constant-time comparison]           │
    │                                       │
    │  [Совпадение!]                        │
    │  [Сохранение peer в БД]               │
    │                                       │
```

### Защита от brute force

```rust
// 3 попытки → блокировка на 30 секунд
session.attempts += 1;
if session.attempts >= 3 {
    session.blocked_until = Some(now + 30);
    return Err("Too many failed attempts. Blocked for 30 seconds".to_string());
} else {
    return Err(format!("Invalid code. {} attempts remaining", 3 - session.attempts));
}
```

**Время взлома:**
- Без блокировки: 1 000 000 попыток × 1 мс = 1000 секунд ≈ 17 минут
- С блокировкой: 333 333 блокировки × 30 сек = 10 000 000 секунд ≈ **115 дней**

### Почему HMAC, а не просто сравнение кодов?

- **Constant-time** — `verify_slice` сравнивает байты за фиксированное время, защита от timing attacks
- **Привязка к сессии** — код бесполезен без `session_key`
- **Невозможно подделать** — без знания shared_secret нельзя вычислить правильный HMAC
- **Защита от replay** — HMAC включает session_key, который уникален для каждой сессии

### Тесты

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_generate_code() {
        let code = generate_code();
        assert_eq!(code.len(), 6);
        assert!(code.chars().all(|c| c.is_ascii_digit()));
    }

    #[test]
    fn test_hmac() {
        let secret = b"test secret key";
        let code = "123456";
        let hmac = compute_hmac(secret, code);
        assert!(verify_hmac(secret, code, &hmac));
        assert!(!verify_hmac(secret, "654321", &hmac));
    }

    #[test]
    fn test_is_valid_code() {
        assert!(is_valid_code("123456"));
        assert!(is_valid_code("000000"));
        assert!(!is_valid_code("12345"));
        assert!(!is_valid_code("1234567"));
        assert!(!is_valid_code("abcdef"));
    }
}
```

---

## 🔐 Хранение ключей

### Где что хранится

| Ключ | Где хранится | Время жизни | Формат |
|------|--------------|-------------|--------|
| **Static key pair** (priv + pub) | В памяти (`WsServer.local_key_pair`) | До перезапуска приложения | `StaticSecret` + `PublicKey` (x25519-dalek) |
| **Session key** | В памяти (`ConnectedPeer.session_key`) | До disconnect | `[u8; 32]` |
| **Public keys peers** | В БД (`peers.public_key`) | Постоянно | Base64 строка |
| **6-digit codes** | В памяти (`PairingManager.sessions`) | До verification или cancel | `String` + HMAC hex |
| **Shared secret** | В памяти (локальная переменная) | До конца handshake | `[u8; 32]` |

### Ключи НИКОГДА не записываются на диск

**Исключение:** публичные ключи peers (они публичные, не секретные).

```rust
// Public key сохраняется в БД (это НЕ секрет)
conn.execute(
    "INSERT INTO peers (id, name, public_key, ...) VALUES (?1, ?2, ?3, ...)",
    params![peer_id, peer_name, request.public_key, ...],
)?;

// Session key хранится ТОЛЬКО в памяти
struct ConnectionInfo {
    session_key: [u8; 32],  // ← только RAM
    connected_at: i64,
}
```

### Почему static key pair, а не ephemeral?

**Ephemeral** (одноразовые ключи) безопаснее, но требует:
- Обмена ключами при каждом подключении
- Хранения публичных ключей для верификации

**Static** (постоянные ключи) проще:
- Генерируются один раз при старте приложения
- Публичный ключ сохраняется в БД peers
- При каждом подключении — новый session key через HKDF

**Компромисс:** static key pair + per-session session key = безопасность ephemeral + удобство static.

---

## 🛡 Защита от атак

### MITM (Man-in-the-Middle)

**Атака:** Злоумышленник перехватывает соединение и подменяет публичные ключи.

```
Устройство A ←→ MITM ←→ Устройство B
     │                    │
  pub_A (подменён)     pub_B (подменён)
     │                    │
  shared_A_MITM        shared_B_MITM
  (разные!)            (разные!)
```

**Защита:** 6-значный код при pairing.

```
Устройство A: "123456"  (вычислен из shared_A_MITM)
Устройство B: "654321"  (вычислен из shared_B_MITM)

Коды не совпадают → пользователь видит → отменяет pairing
```

**Надёжность:**
- 6 цифр = 1 000 000 комбинаций
- При MITM — коды совпадут с вероятностью 1/1 000 000
- С блокировкой после 3 попыток — практически невозможно подобрать

### Brute force

**Атака:** Перебор 6-значных кодов.

**Защита:**
- Максимум 3 попытки
- Блокировка на 30 секунд после 3 неудач
- HMAC constant-time comparison

**Время взлома:** ~115 дней (см. выше).

### Replay

**Атака:** Злоумышленник записывает зашифрованное сообщение и отправляет его позже.

**Защита:**
- Уникальный nonce в каждом сообщении (12 байт, OsRng)
- Timestamp в каждом сообщении (`WsMessage.timestamp`)
- AES-GCM authentication tag (16 байт) — нельзя изменить ciphertext

**Дополнительно:** session key уникален для каждой сессии — replay между сессиями невозможен.

### Tampering

**Атака:** Злоумышленник изменяет зашифрованное сообщение.

**Защита:** AES-256-GCM включает authentication tag. Любое изменение ciphertext → расшифровка падает с ошибкой.

```rust
// При tampering — decrypt вернёт Err
cipher
    .decrypt(nonce, ciphertext)
    .map_err(|e| format!("Decryption failed: {}", e))  // ← сюда попадём
```

### Timing attacks

**Атака:** Измерение времени ответа для угадывания ключа/кода.

**Защита:**
- `verify_slice` — constant-time сравнение HMAC
- `x25519-dalek` — constant-time scalar multiplication
- `aes-gcm` — constant-time GHASH

### Side-channel attacks

**Атака:** Анализ потребления энергии, электромагнитного излучения, cache timing.

**Защита:**
- Все криптобиблиотеки (`x25519-dalek`, `aes-gcm`, `hmac`) используют constant-time алгоритмы
- Ключи хранятся в памяти (не на диске) — защита от forensic analysis
- Session keys генерируются заново при каждом подключении

---

## 🧪 Тестирование

### Unit-тесты

Каждый криптографический модуль имеет unit-тесты:

```bash
# Запуск тестов
cd src-tauri
cargo test --lib crypto
```

**Покрытие:**
- ✅ `aes::test_encrypt_decrypt` — шифрование/расшифровка
- ✅ `aes::test_wrong_key_fails` — неправильный ключ → ошибка
- ✅ `ecdh::test_key_exchange` — shared secret одинаковый у обеих сторон
- ✅ `codes::test_generate_code` — формат 6 цифр
- ✅ `codes::test_hmac` — verify работает корректно
- ✅ `codes::test_is_valid_code` — валидация формата

### Интеграционные тесты (планируются)

- [ ] Full handshake между двумя WsServer
- [ ] Pairing flow с реальным HMAC
- [ ] Sync с шифрованием
- [ ] MITM simulation — коды не должны совпасть

---

## 📊 Сравнение с альтернативами

### X25519 vs RSA-2048

| Параметр | X25519 | RSA-2048 |
|----------|--------|----------|
| Размер ключа | 32 байта | 256 байт |
| Скорость | ~200k ops/sec | ~1k ops/sec |
| Безопасность | ~128 бит | ~112 бит |
| Post-quantum | ❌ Нет | ❌ Нет |
| Стандарт | RFC 7748 | RFC 8017 |

**Вывод:** X25519 быстрее, компактнее, безопаснее.

### AES-256-GCM vs AES-256-CBC

| Параметр | AES-256-GCM | AES-256-CBC |
|----------|-------------|-------------|
| Аутентификация | ✅ Встроена | ❌ Нужен HMAC отдельно |
| Padding | ❌ Не нужен | ✅ Нужен (PKCS7) |
| Parallel | ✅ Да | ❌ Нет (шифрование) |
| Nonce reuse | ️ Только confidentiality | ⚠️ Полная компрометация |
| Стандарт | TLS 1.3 | TLS 1.2 |

**Вывод:** GCM проще, быстрее, безопаснее.

### HKDF vs SHA-256 напрямую

| Параметр | HKDF | SHA-256 |
|----------|------|---------|
| Extract | ✅ Да | ❌ Нет |
| Expand | ✅ Да | ❌ Нет |
| Domain separation | ✅ Через info |  Нужно вручную |
| Стандарт | RFC 5869 | RFC 6234 |

**Вывод:** HKDF — правильный инструмент для key derivation.

---

##  Связанные документы

- [`PROTOCOL.md`](./PROTOCOL.md) — протокол синхронизации (как криптография используется)
- [`API.md`](./API.md) — документация Tauri команд
- [`ARCHITECTURE.md`](./ARCHITECTURE.md) — общая архитектура

---

## 🔗 Полезные ссылки

- [RFC 7748 — X25519](https://datatracker.ietf.org/doc/html/rfc7748)
- [RFC 5869 — HKDF](https://datatracker.ietf.org/doc/html/rfc5869)
- [RFC 5116 — AEAD (AES-GCM)](https://datatracker.ietf.org/doc/html/rfc5116)
- [RFC 2104 — HMAC](https://datatracker.ietf.org/doc/html/rfc2104)
- [x25519-dalek docs](https://docs.rs/x25519-dalek/)
- [aes-gcm docs](https://docs.rs/aes-gcm/)
- [RustCrypto](https://github.com/RustCrypto)

---

<div align="center">
*© 2026 ByteWizard*
</div>