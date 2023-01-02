use serde::{Serialize, Deserialize};
use serde::de::DeserializeOwned;

pub mod app;
pub mod client;


#[derive(Debug, Serialize, Deserialize)]
pub struct ExpiringClaim<C> {
    exp: u64,
    content: C,
}

impl<C: Serialize + DeserializeOwned> ExpiringClaim<C> {
    pub fn encode(
        content: C,
        secret: &[u8],
        duration_in_secs: u64,
    ) -> Result<String, jsonwebtoken::errors::Error> {
        jsonwebtoken::encode(
            &jsonwebtoken::Header::default(),
            &ExpiringClaim {
                content,
                exp: std::time::SystemTime::now()
                    .duration_since(std::time::UNIX_EPOCH)
                    .expect("Time went backwards")
                    .as_secs()
                    + duration_in_secs,
            },
            &jsonwebtoken::EncodingKey::from_secret(secret),
        )
    }

    pub fn decode(token: &str, secret: &[u8]) -> Result<C, jsonwebtoken::errors::Error> {
        jsonwebtoken::decode::<ExpiringClaim<C>>(
            token,
            &jsonwebtoken::DecodingKey::from_secret(secret),
            &jsonwebtoken::Validation::new(jsonwebtoken::Algorithm::HS256),
        )
        .map(|t| t.claims.content)
    }
}
