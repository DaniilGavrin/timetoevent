use aes_gcm::{
    aead::{Aead, KeyInit},
    Aes256Gcm, Nonce,
};
use hkdf::Hkdf;
use rand::rngs::OsRng;
use rand::RngCore;
use sha2::Sha256;

const NONCE_SIZE: usize = 12;

pub fn derive_key(shared_secret: &[u8; 32], info: &[u8]) -> [u8; 32] {
    let hkdf = Hkdf::<Sha256>::new(None, shared_secret);
    let mut key = [0u8; 32];
    hkdf.expand(info, &mut key).expect("HKDF expand failed");
    key
}

pub fn encrypt(key: &[u8; 32], plaintext: &[u8]) -> Result<Vec<u8>, String> {
    let cipher = Aes256Gcm::new_from_slice(key).map_err(|e| format!("Invalid key: {}", e))?;

    let mut nonce_bytes = [0u8; NONCE_SIZE];
    OsRng.fill_bytes(&mut nonce_bytes);
    let nonce = Nonce::from_slice(&nonce_bytes);

    let ciphertext = cipher
        .encrypt(nonce, plaintext)
        .map_err(|e| format!("Encryption failed: {}", e))?;

    let mut result = Vec::with_capacity(NONCE_SIZE + ciphertext.len());
    result.extend_from_slice(&nonce_bytes);
    result.extend_from_slice(&ciphertext);

    Ok(result)
}

pub fn decrypt(key: &[u8; 32], data: &[u8]) -> Result<Vec<u8>, String> {
    if data.len() < NONCE_SIZE {
        return Err("Data too short".to_string());
    }

    let cipher = Aes256Gcm::new_from_slice(key).map_err(|e| format!("Invalid key: {}", e))?;

    let (nonce_bytes, ciphertext) = data.split_at(NONCE_SIZE);
    let nonce = Nonce::from_slice(nonce_bytes);

    cipher
        .decrypt(nonce, ciphertext)
        .map_err(|e| format!("Decryption failed: {}", e))
}

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

        assert!(result.is_err());
    }
}
