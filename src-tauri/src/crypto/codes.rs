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
    let mut mac = HmacSha256::new_from_slice(secret).expect("HMAC can take key of any size");
    mac.update(code.as_bytes());
    let result = mac.finalize();
    hex::encode(result.into_bytes())
}

/// Constant-time HMAC verification — защита от Timing Attack
/// Используем verify_slice, который внутри сравнивает байты за фиксированное время
pub fn verify_hmac(secret: &[u8], code: &str, expected_hmac: &str) -> bool {
    // Декодируем ожидаемый HMAC из hex
    let expected_bytes = match hex::decode(expected_hmac) {
        Ok(b) => b,
        Err(_) => return false,
    };

    // Пересоздаём MAC и используем verify_slice (constant-time)
    let mut mac = match HmacSha256::new_from_slice(secret) {
        Ok(m) => m,
        Err(_) => return false,
    };
    mac.update(code.as_bytes());

    // verify_slice внутри использует constant-time сравнение
    mac.verify_slice(&expected_bytes).is_ok()
}

pub fn is_valid_code(code: &str) -> bool {
    code.len() == 6 && code.chars().all(|c| c.is_ascii_digit())
}

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
