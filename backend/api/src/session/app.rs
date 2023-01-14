use crate::errors::ApiError;
use serde::{Serialize, Deserialize};

#[derive(Debug, Serialize, Deserialize)]
pub struct Session {
}

impl actix_web::FromRequest for Session {
    type Error = ApiError<()>;
    type Future = futures_util::future::Ready<Result<Self, Self::Error>>;

    fn from_request(
        req: &actix_web::HttpRequest,
        _payload: &mut actix_web::dev::Payload,
    ) -> Self::Future {
        /*let pool = req
            .app_data::<actix_web::web::Data<sqlx::PgPool>>()
            .unwrap()
            .as_ref()
            .clone();*/

        log::info!("{:?}", req.headers());

        match req.headers().get("X-Access-Token") {
            None => return futures_util::future::err(ApiError::BadRequest {
                detail: "failed to find API key".to_string(),
            }),
            Some(h) => {
                if h.to_str().expect("X-Access-Token header couldn't be converted to string") == crate::config::CONFIG.app_api_key {
                    futures_util::future::ok(Session {})
                } else {
                futures_util::future::err(ApiError::NotAuthenticated { detail: "provided API KEY is invalid".to_string() } )
                }
            }
        }
    }
}
