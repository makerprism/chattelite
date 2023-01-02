use actix_web::web;

use crate::errors::ApiError;
use crate::generated::client_types::*;
use crate::realtime::broadcast::Broadcaster;
use crate::session::client::Session;

pub async fn get_connection_events(
    session: Session,
    pool: web::Data<sqlx::PgPool>,
    _broadcaster: web::Data<Broadcaster>,
) -> Result<GetConnectionEventsOutput, ApiError<()>> {
    todo!()
}

pub async fn get_conversation_events(
    session: Session,
    params: web::Path<GetConversationEventsParams>,
    pool: web::Data<sqlx::PgPool>,
    _broadcaster: web::Data<Broadcaster>,
) -> Result<GetConversationEventsOutput, ApiError<()>> {
    let row = sqlx::query!(
        r#"
        SELECT 
            EXISTS(
                SELECT * FROM conversation_participant
                WHERE conversation_id = $1 AND account_id = $2)
            as "is_participant!: bool"
        "#,
        params.conversation_id.to_db_id(),
        session.account_id
    )
    .fetch_one(pool.get_ref())
    .await?;

    if !row.is_participant {
        return Err(ApiError::BadRequest {
            detail: "User is not a participant in this conversation!".to_string(),
        });
    }

    let lines = sqlx::query!(
        r#"
        SELECT 
            line.id,
            line.created_at,
            line.updated_at,
            line.deleted,
            line.conversation_id,
            line.thread_line_id,
            line.reply_to_line_id,
            system_event.kind as "kind?: db::SystemEventKind",
            system_event.account_id as "account_id?: db::AccountId",
            message.created_by as "created_by?: db::AccountId",
            message.content as "content?: String"
        FROM line
        LEFT OUTER JOIN system_event ON system_event.line_id = line.id
        LEFT OUTER JOIN message ON message.line_id = line.id
        WHERE conversation_id = $1
        ORDER BY line.created_at DESC
        LIMIT 20
        "#,
        params.conversation_id.to_db_id(),
    )
    .fetch_all(pool.get_ref())
    .await?;

    let events = lines
        .into_iter()
        .map(|row| match row.kind {
            Some(db::SystemEventKind::Join) => ConversationEvent::Join {
                timestamp: row.created_at.to_string(),
                from: row.account_id.expect("missing account_id").to_string(),
            },
            Some(db::SystemEventKind::Leave) => ConversationEvent::Leave {
                timestamp: row.created_at.to_string(),
                from: row.account_id.expect("missing account_id").to_string(),
            },
            None => match row.content {
                Some(content) => ConversationEvent::Message {
                    timestamp: row.created_at.to_string(),
                    from: row.created_by.expect("impossible").to_string(),
                    content: content,
                },
                None => {
                    panic!("chat line is neither a system event nor a message")
                }
            },
        })
        .rev().collect();

    Ok(GetConversationEventsOutput { events })
}

pub async fn send_message(
    session: Session,
    params: web::Path<SendMessageParams>,
    json: web::Json<SendMessageInput>,
    pool: web::Data<sqlx::PgPool>,
    broadcaster: web::Data<Broadcaster>,
) -> Result<NoOutput, ApiError<()>> {
    let mut transaction = pool.begin().await?;

    let _ = sqlx::query!(
        r#"
        SELECT conversation.id
        FROM conversation
        INNER JOIN conversation_participant ON conversation_participant.conversation_id = conversation.id
        WHERE
            conversation.id = $1 
            AND conversation_participant.account_id = $2
        "#,
        params.conversation_id.to_db_id(),
        session.account_id,
    ).fetch_one(&mut transaction).await?;

    let line = db::Line::insert(
        &mut transaction,
        db::InsertLine {
            conversation_id: params.conversation_id.to_db_id(),
            thread_line_id: None, // TODO
            reply_to_line_id: None,
        },
    )
    .await?;

    db::Message::insert_returning_pk(
        &mut transaction,
        db::InsertMessage {
            line_id: line.id,
            created_by: session.account_id,
            content: &json.content,
        },
    )
    .await?;

    transaction.commit().await?;

    // TODO: broadcast to the conversation, not globally
    broadcaster
        .broadcast(&ConversationEvent::Message {
            timestamp: line.created_at.to_string(),
            from: session.username,
            content: json.content.to_string(),
        })
        .await;

    Ok(NoOutput {})
}

pub async fn start_typing(
    session: Session,
    params: web::Path<StartTypingParams>, // TODO: broadcast to this conversation, not globally
    _pool: web::Data<sqlx::PgPool>,
    broadcaster: web::Data<Broadcaster>,
) -> Result<NoOutput, ApiError<()>> {
    broadcaster
        .broadcast(&ConversationEvent::StartTyping {
            timestamp: "TODO".to_string(),
            from: session.username,
        })
        .await;

    Ok(NoOutput {})
}

pub async fn stop_typing(
    session: Session,
    params: web::Path<StopTypingParams>,
    pool: web::Data<sqlx::PgPool>,
    broadcaster: web::Data<Broadcaster>,
) -> Result<NoOutput, ApiError<()>> {
    broadcaster
        .broadcast(&ConversationEvent::EndTyping {
            timestamp: "TODO".to_string(),
            from: session.username,
        })
        .await;

    Ok(NoOutput {})
}

pub async fn mark_read(
    session: Session,
    json: web::Json<MarkReadInput>,
    pool: web::Data<sqlx::PgPool>,
    _broadcaster: web::Data<Broadcaster>,
) -> Result<NoOutput, ApiError<()>> {
    let mut transaction = pool.begin().await?;

    let r = sqlx::query!(
        r#"
        SELECT conversation.id,
            line.created_at
        FROM conversation
        INNER JOIN conversation_participant ON conversation_participant.conversation_id = conversation.id
        INNER JOIN line ON line.conversation_id = conversation.id
        WHERE
            conversation.id = $1 
            AND conversation_participant.account_id = $2
            AND line.id = $3
        "#,
        json.conversation_id.to_db_id(),
        session.account_id,
        json.line_id.to_db_id(),
    ).fetch_one(&mut transaction).await?;

    db::ConversationParticipant::update(
        &mut transaction,
        db::UpdateConversationParticipant {
            account_id: session.account_id,
            conversation_id: json.conversation_id.to_db_id(),
            lines_seen_until: Some(&r.created_at),
        },
    )
    .await?;

    transaction.commit().await?;

    Ok(NoOutput {})
}
