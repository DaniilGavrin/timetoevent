use x25519_dalek::{EphemeralSecret, PublicKey, SharedSecret, StaticSecret};
use rand::rngs::OsRng;

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

pub fn generate_ephemeral() -> (EphemeralSecret, PublicKey) {
    let secret = EphemeralSecret::random_from_rng(OsRng);
    let public = PublicKey::from(&secret);
    (secret, public)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_key_exchange() {
        let alice = KeyPair::generate();
        let bob = KeyPair::generate();

        let alice_shared = alice
            .compute_shared_secret(&bob.public_key_base64())
            .unwrap();
        let bob_shared = bob
            .compute_shared_secret(&alice.public_key_base64())
            .unwrap();

        assert_eq!(alice_shared, bob_shared);
    }
}