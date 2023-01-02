extern crate actix_web;
extern crate chrono;
extern crate dotenv;
extern crate rand;
extern crate uuid;

#[macro_use]
extern crate lazy_static;

mod realtime;
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
    pub static ref APP_API_KEY: String = std::env::var("APP_API_KEY")
        .expect("APP_API_KEY must be set");
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    dotenv::dotenv().ok();
    env_logger::init_from_env(env_logger::Env::new().default_filter_or("info"));

    let bind = std::env::var("BIND").expect("BIND must be set");

    let database_url =
        std::env::var("DATABASE_URL").expect("DATABASE_URL must be set");
    let db_pool = sqlx::PgPool::connect(&database_url)
        .await
        .expect("Failed to connect to Postgres.");
    println!("db_pool: {:?}", db_pool);

    let broadcaster = realtime::broadcast::Broadcaster::create();

    HttpServer::new(move || {
        let cors = actix_cors::Cors::permissive();

        
/*        actix_cors::Cors::default()
        //.allowed_origin("127.0.0.1")
        .allow_any_origin() 
        .send_wildcard()
        /*.allowed_methods(vec!["GET", "POST"])
        .allowed_headers(vec![actix_web::http::header::AUTHORIZATION, actix_web::http::header::ACCEPT])
        .allowed_header(actix_web::http::header::CONTENT_TYPE)
         */
        .max_age(3600);
         */

        App::new()
            .wrap(cors)
            .wrap(actix_web::middleware::Logger::default())

            .app_data(actix_web::web::Data::new(db_pool.clone()))
            // https://stackoverflow.com/questions/64291039/how-to-return-the-error-description-in-a-invalid-json-request-body-to-the-client
            // make actix return our custom error when JSON deserialization fails
            .app_data(web::JsonConfig::default().error_handler(|err, _req| {
                let e: errors::ApiError<()> = errors::ApiError::BadRequest {
                    detail: format!(r#"{}"#, err),
                };
                actix_web::Error::from(e)
            }))
            .app_data(web::Data::from(std::sync::Arc::clone(&broadcaster)))

            .configure(generated::app_endpoints::routes)
            .configure(generated::client_endpoints::routes)

            .service(realtime::event_stream)

            .default_service(web::route().to(not_found))
    })
    .bind(bind.to_owned())?
    .run()
    .await
}
