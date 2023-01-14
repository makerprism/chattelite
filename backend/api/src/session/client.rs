use crate::errors::ApiError;
use serde::{Serialize, Deserialize};

pub struct Session {
    pub id: db::UsersId,
    pub public_facing_id: String,
    pub display_name: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct JWTSession {
    pub user_id: String,
    pub display_name: String,
}

impl JWTSession {
    pub fn encode(
        self,
        secret: &[u8],
        duration_in_secs: u64,
    ) -> Result<String, jsonwebtoken::errors::Error> {
        super::ExpiringClaim::encode(self, secret, duration_in_secs)
    }

    pub fn decode(token: &str, secret: &[u8]) -> Result<JWTSession, jsonwebtoken::errors::Error> {
        super::ExpiringClaim::decode(token, secret)
    }
}

impl actix_web::FromRequest for Session {
    type Error = ApiError<()>;
    type Future = std::pin::Pin<Box<dyn futures_util::Future<Output = Result<Self, Self::Error>>>>;


    fn from_request(
        req: &actix_web::HttpRequest,
        _payload: &mut actix_web::dev::Payload,
    ) -> Self::Future {
        let s = req.headers().get("X-Access-Token");

        if s.is_none() {
            return Box::pin(futures_util::future::err(ApiError::BadRequest {
                detail: "failed to find session token".to_string(),
            }))
        }

        let jwt = match s.unwrap().to_str() {
            Ok(token) => {
                JWTSession::decode(token, &crate::config::CONFIG.client_jwt_secret)
            }
            Err(_) => return Box::pin(futures_util::future::err(ApiError::BadRequest { detail: "failed to decode token".to_string() }))
        };

        match jwt {
            Err(_e) => Box::pin(futures_util::future::err(ApiError::NotAuthenticated { detail: "token is invalid".to_string() } )),
            Ok(session) => {
                let pool = req
                .app_data::<actix_web::web::Data<sqlx::PgPool>>()
                .unwrap()
                .as_ref()
                .clone();
                
                async fn f(
                    session: &JWTSession,
                    pool: sqlx::PgPool,
                ) -> Result<Session, ApiError<()>> {
                    let r = sqlx::query!(
                        r#"
                        SELECT id, display_name FROM users WHERE public_facing_id = $1
                        "#,
                        session.user_id
                    ).fetch_one(&mut pool.acquire().await?).await?;

                    Ok(Session {
                        id: r.id,
                        public_facing_id: session.user_id.to_string(),
                        display_name: r.display_name,
                    })
                }
            
                Box::pin(async move { f(&session, pool).await })
            }
        }
    }
}
