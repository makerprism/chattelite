use actix_web::{get, web, Responder};

pub mod broadcast;
use self::broadcast::Broadcaster;

#[get("/realtime")]
async fn event_stream(
    session: crate::session::client::Session,
    broadcaster: web::Data<Broadcaster>,
) -> impl Responder {
    log::info!("realtime");
    broadcaster.new_client().await
}
