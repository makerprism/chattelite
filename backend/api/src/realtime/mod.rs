use actix_web::{get, web, Responder};
use serde::Deserialize;

pub mod broadcast;
use self::broadcast::Broadcaster;

/*
#[get("/sse")]
async fn sse(
    session: crate::session::client::Session,
) -> impl Responder {
    log::info!("sse");
    broadcaster.new_client().await
}
 */

#[derive(Deserialize)]
struct SseConversationEventsParams {
    conversation_id: crate::generated::client_types::ConversationId
}

#[get("/conversation/{conversation_id}/sse")]
async fn sse_conversation_events(
    session: crate::session::client::Session,
    params: web::Path<SseConversationEventsParams>,
    broadcaster: web::Data<Broadcaster>
) -> impl Responder {
    log::info!("sse_conversation_events");
    broadcaster.add_client_to_conversation(params.conversation_id.to_db_id()).await
}
