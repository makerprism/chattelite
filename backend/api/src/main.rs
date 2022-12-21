extern crate actix_web;
extern crate chrono;
extern crate dotenv;
extern crate rand;
extern crate uuid;

#[macro_use]
extern crate lazy_static;

mod generated;
mod errors;
mod handlers;
mod session;

use actix_web::{web, App, HttpResponse, HttpServer};
use errors::ApiError;

async fn not_found() -> Result<HttpResponse, ApiError<()>> {
    Err(ApiError::NotFound { detail: "Not found".to_string() })
}

lazy_static! {
    pub static ref EMPTY_STRING: String = "".to_string();
}

lazy_static! {
    pub static ref CLIENT_JWT_SECRET: Vec<u8> = std::env::var("CLIENT_JWT_SECRET")
        .expect("CLIENT_JWT_SECRET must be set")
        .into_bytes();
}

lazy_static! {
    pub static ref APP_JWT_SECRET: Vec<u8> = std::env::var("APP_JWT_SECRET")
        .expect("APP_JWT_SECRET must be set")
        .into_bytes();
}


#[actix_web::main]
async fn main() -> std::io::Result<()> {
    use crate::actix_web::dev::Service;
    use futures_util::future::FutureExt;

    env_logger::init();

    dotenv::dotenv().ok();

    let bind = std::env::var("BIND").expect("BIND must be set");

    let database_url =
        std::env::var("DATABASE_URL").expect("DATABASE_URL must be set");
    let db_pool = sqlx::PgPool::connect(&database_url)
        .await
        .expect("Failed to connect to Postgres.");
    println!("db_pool: {:?}", db_pool);

    HttpServer::new(move || {
        App::new()
            .app_data(actix_web::web::Data::new(db_pool.clone()))
            // https://stackoverflow.com/questions/64291039/how-to-return-the-error-description-in-a-invalid-json-request-body-to-the-client
            // make actix return our custom error when JSON deserialization fails
            .app_data(web::JsonConfig::default().error_handler(|err, _req| {
                let e: errors::ApiError<()> = errors::ApiError::BadRequest {
                    detail: format!(r#"{}"#, err),
                };
                actix_web::Error::from(e)
            }))
            .service(
                web::scope("/api")
                    .wrap_fn(|req, srv| {
                        // check for HTTPS proxy header that nginx uses to tell us that the request came by https
                        let is_https = req
                            .headers()
                            .get("SOMEONE_TRUSTWORTHY_HAS_CHECKED_HTTPS")
                            .is_some();

                        if !is_https {
                            let e: errors::ApiError<()> = errors::ApiError::BadRequest {
                                detail: "not a https request!".to_string(),
                            };
                            return futures_util::future::Either::Right(futures_util::future::err(
                                actix_web::Error::from(e),
                            ));
                        }

                        futures_util::future::Either::Left(srv.call(req).map(move |res| res))
                    })
                    .wrap_fn(|req, srv| {
                        println!("Request: {:?}", req);

                        srv.call(req).map(move |res| {
                            println!("Response: {:?}", res);
                            res
                        })
                    })
                    .configure(generated::app_endpoints::routes)
                    .configure(generated::client_endpoints::routes)
                    .default_service(web::to(not_found)),
            )
            .default_service(web::route().to(not_found))
    })
    .bind(bind.to_owned())?
    .run()
    .await
}
