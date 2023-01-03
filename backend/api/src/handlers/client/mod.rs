use actix_web::web;

use crate::errors::ApiError;
use crate::generated::client_types::*;
use crate::realtime::broadcast::{BroadcastConversationEvent, Broadcaster};
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
                INNER JOIN users ON users.id = conversation_participant.user_id
                WHERE conversation_id = $1 AND users.public_facing_id = $2)
            as "is_participant!: bool"
        "#,
        params.conversation_id.to_db_id(),
        session.user_id
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

            u1.public_facing_id as "user_id1?: String",
            u1.display_name as "display_name1?: String",

            u2.public_facing_id as "user_id2?: String",
            u2.display_name as "display_name2?: String",
            message.content as "content?: String"
        FROM line
        LEFT OUTER JOIN system_event ON system_event.line_id = line.id
        LEFT OUTER JOIN message ON message.line_id = line.id
        LEFT OUTER JOIN users u1 ON u1.id = system_event.user_id
        LEFT OUTER JOIN users u2 ON u2.id = message.created_by
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
                from: User {
                    id: row.user_id1.expect("missing user_id"),
                    display_name: row.display_name1.expect("missing display_name"),
                },
            },
            Some(db::SystemEventKind::Leave) => ConversationEvent::Leave {
                timestamp: row.created_at.to_string(),
                from: User {
                    id: row.user_id1.expect("missing user_id"),
                    display_name: row.display_name1.expect("missing display_name"),
                },
            },
            None => match row.content {
                Some(content) => ConversationEvent::Message {
                    timestamp: row.created_at.to_string(),
                    from: User {
                        id: row.user_id2.expect("missing user_id"),
                        display_name: row.display_name2.expect("missing display_name"),
                    },
                    content: content,
                },
                None => {
                    panic!("chat line is neither a system event nor a message")
                }
            },
        })
        .rev()
        .collect();

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

    let row = sqlx::query!(
        r#"
        SELECT users.id as "user_id", conversation.id
        FROM conversation
        INNER JOIN conversation_participant ON conversation_participant.conversation_id = conversation.id
        INNER JOIN users ON users.id = conversation_participant.user_id
        WHERE
            conversation.id = $1 
            AND users.public_facing_id = $2
        "#,
        params.conversation_id.to_db_id(),
        session.user_id,
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
            created_by: row.user_id,
            content: &json.content,
        },
    )
    .await?;

    transaction.commit().await?;

    broadcaster
        .broadcast_to_conversation(
            params.conversation_id.to_db_id(),
            BroadcastConversationEvent::Message {
                timestamp: line.created_at,
                user: User {
                    id: session.user_id,
                    display_name: session.display_name,
                },
                content: json.content.to_string(),
            },
        )
        .await;

    Ok(NoOutput {})
}

pub async fn start_typing(
    session: Session,
    params: web::Path<StartTypingParams>,
    _pool: web::Data<sqlx::PgPool>,
    broadcaster: web::Data<Broadcaster>,
) -> Result<NoOutput, ApiError<()>> {
    broadcaster
        .broadcast_to_conversation(
            params.conversation_id.to_db_id(),
            BroadcastConversationEvent::StartTyping {
                user: User {
                    id: session.user_id,
                    display_name: session.display_name,
                },
            },
        )
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
        .broadcast_to_conversation(
            params.conversation_id.to_db_id(),
            BroadcastConversationEvent::EndTyping {
                user: User {
                    id: session.user_id,
                    display_name: session.display_name,
                },
            },
        )
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
        SELECT 
            users.id as "user_id",
            conversation.id,
            line.created_at
        FROM conversation
        INNER JOIN conversation_participant ON conversation_participant.conversation_id = conversation.id
        INNER JOIN line ON line.conversation_id = conversation.id
        INNER JOIN users ON users.id = conversation_participant.user_id
        WHERE
            conversation.id = $1 
            AND users.public_facing_id = $2
            AND line.id = $3
        "#,
        json.conversation_id.to_db_id(),
        session.user_id,
        json.line_id.to_db_id(),
    ).fetch_one(&mut transaction).await?;

    db::ConversationParticipant::update(
        &mut transaction,
        db::UpdateConversationParticipant {
            user_id: r.user_id,
            conversation_id: json.conversation_id.to_db_id(),
            lines_seen_until: Some(&r.created_at),
        },
    )
    .await?;

    transaction.commit().await?;

    Ok(NoOutput {})
}
