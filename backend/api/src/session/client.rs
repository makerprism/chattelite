use crate::errors::ApiError;
use serde::{Serialize, Deserialize};

#[derive(Debug, Serialize, Deserialize)]
pub struct Session {
    pub account_id: db::AccountId,
    pub username: String,
}

impl Session {
    pub fn encode(
        self,
        secret: &[u8],
        duration_in_secs: u64,
    ) -> Result<String, jsonwebtoken::errors::Error> {
        super::ExpiringClaim::encode(self, secret, duration_in_secs)
    }

    pub fn decode(token: &str, secret: &[u8]) -> Result<Session, jsonwebtoken::errors::Error> {
        super::ExpiringClaim::decode(token, secret)
    }
}


impl actix_web::FromRequest for Session {
    type Error = ApiError<()>;
    type Future = futures_util::future::Ready<Result<Self, Self::Error>>;

    fn from_request(
        req: &actix_web::HttpRequest,
        _payload: &mut actix_web::dev::Payload,
    ) -> Self::Future {
        let pool = req
            .app_data::<actix_web::web::Data<sqlx::PgPool>>()
            .unwrap()
            .as_ref()
            .clone();

        let s = req.headers().get("X-Access-Token");

        if s.is_none() {
            return futures_util::future::err(ApiError::BadRequest {
                detail: "failed to find session token".to_string(),
            })
        }

        let jwt = match s.unwrap().to_str() {
            Ok(token) => {
                Session::decode(token, &crate::CLIENT_JWT_SECRET)
            }
            Err(_) => return futures_util::future::err(ApiError::BadRequest { detail: "failed to decode token".to_string() })
        };

        match jwt {
            Err(e) => futures_util::future::err(ApiError::NotAuthenticated { detail: "token is invalid".to_string() } ),
            Ok(session) => futures_util::future::ok(session)
        }
    }
}
