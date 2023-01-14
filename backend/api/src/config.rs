use serde::{Deserialize, Deserializer};

#[derive(Deserialize)]
pub struct Config {
    pub bind: String,
    pub database_url: String,
    #[serde (deserialize_with = "deserialize_client_jwt")]
    pub client_jwt_secret: Vec<u8>,
    pub app_api_key: String,
}

fn deserialize_client_jwt<'de, D>(deserializer: D) -> Result<Vec<u8>, D::Error> where D: Deserializer<'de> {
    let s: String = serde::de::Deserialize::deserialize(deserializer)?;
    Ok(s.into_bytes())
}

lazy_static! {
    pub static ref CONFIG: Config = load_config().unwrap();
}

fn load_config() -> Result<Config, String> {
    let content = match std::fs::read_to_string("/etc/chattelite/chattelite-server.toml") {
        Ok(c) => c,
        Err(_) => std::fs::read_to_string("chattelite-server.toml").expect("config file wasn't found: neither at /etc/chattelite/chattelite-server.toml nor in the current directory!")
    };
    toml::from_str(&content).map_err(|e| format!("failed to parse configuration file: {}", e.to_string()))
}
