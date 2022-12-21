use actix_web::web;

use crate::errors::ApiError;
use crate::generated::client_types::*;
use crate::session::client::Session;

pub async fn get_messages (
    session: Session,
    params: web::Path<GetMessagesParams>,
    pool: web::Data<sqlx::PgPool>
) -> Result<GetMessagesOutput, ApiError<()>> {
    todo!()
}

pub async fn send_message (
    session: Session,
    params: web::Path<SendMessageParams>,
    json: web::Json<SendMessageInput>,
    pool: web::Data<sqlx::PgPool>
) -> Result<NoOutput, ApiError<()>> {
    todo!()
}

pub async fn conversation_start_typing (
    session: Session,
    params: web::Path<ConversationStartTypingParams>,
    pool: web::Data<sqlx::PgPool>
) -> Result<NoOutput, ApiError<()>> {
    todo!()
}

pub async fn conversation_stop_typing (
    session: Session,
    params: web::Path<ConversationStopTypingParams>,
    pool: web::Data<sqlx::PgPool>
) -> Result<NoOutput, ApiError<()>> {
    todo!()
}
