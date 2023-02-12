use actix_web::web;

use crate::errors::ApiError;
use crate::generated::client_types::*;
use crate::realtime::broadcast::{BroadcastConversationEvent, Broadcaster};
use crate::session::client::Session;

pub async fn get_conversations(
    session: Session,
    pool: web::Data<sqlx::PgPool>,
    _broadcaster: web::Data<Broadcaster>,
) -> Result<GetConversationsOutput, ApiError<()>> {
    let db_conversations = sqlx::query!(
        r#"
        SELECT 
            conversation.id,
            conversation.updated_at,
            COUNT (line.id) as unread
        FROM conversation_participant
        INNER JOIN users ON users.id = conversation_participant.user_id
        INNER JOIN conversation ON conversation.id = conversation_participant.conversation_id
        LEFT JOIN line ON line.conversation_id = conversation.id
            AND (line.created_at > conversation_participant.lines_seen_until)
        WHERE users.public_facing_id = $1
            AND conversation_participant.deleted = FALSE
        GROUP BY conversation.id
        ORDER BY conversation.updated_at DESC
        LIMIT 20
        "#,
        session.public_facing_id
    )
    .fetch_all(pool.get_ref())
    .await?;

    let newest_lines = sqlx::query!(
        r#"
        SELECT DISTINCT ON (line.conversation_id)
            line.id,
            line.conversation_id,
            line.created_at,
            line.updated_at,
            line.message,
            line.data,
            users.public_facing_id,
            users.display_name
        FROM line
        LEFT OUTER JOIN users ON line.sender_user_id = users.id
        WHERE line.conversation_id = ANY($1)
        ORDER BY line.conversation_id, line.created_at DESC
        "#,
        &db_conversations
            .iter()
            .map(|c| c.id)
            .collect::<Vec<db::ConversationId>>()
    )
    .fetch_all(pool.get_ref())
    .await?;

    let mut newest_line_lookup = std::collections::HashMap::new();
    for m in newest_lines {
        newest_line_lookup.insert(m.conversation_id, m);
    }

    let conversations = db_conversations
        .iter()
        .map(|c| {
            let m = newest_line_lookup.get(&c.id);

            Conversation {
                conversation_id: c.id.into(),
                timestamp: c.updated_at.to_string(),
                number_of_unread_messages: c.unread.unwrap_or(0) as i32,
                newest_line: if let Some(m) = m {
                    Some(Line {
                        line_id: m.id.into(),
                        timestamp: m.created_at.to_string(),
                        from: User {
                            id: m.public_facing_id.to_string(),
                            display_name: m.display_name.to_string(),
                        },
                        message: m.message.to_string(),
                        data: m.data.clone(),
                        reply_to_line: None, // Note: intentionally empty, even if the message is a reply
                    })
                } else {
                    None
                },
            }
        })
        .collect();

    Ok(GetConversationsOutput { conversations })
}

pub async fn get_conversation_messages(
    session: Session,
    params: web::Path<GetConversationMessagesParams>,
    pool: web::Data<sqlx::PgPool>,
    _broadcaster: web::Data<Broadcaster>,
) -> Result<GetConversationMessagesOutput, ApiError<()>> {
    let row = sqlx::query!(
        r#"
        SELECT 
            EXISTS(
                SELECT * FROM conversation_participant
                INNER JOIN users ON users.id = conversation_participant.user_id AND conversation_participant.deleted = FALSE
                WHERE conversation_id = $1 AND users.public_facing_id = $2)
            as "is_participant!: bool"
        "#,
        params.conversation_id.to_db_id(),
        session.public_facing_id
    )
    .fetch_one(pool.get_ref())
    .await?;

    if !row.is_participant {
        return Err(ApiError::BadRequest {
            detail: "User is not a participant in this conversation!".to_string(),
        });
    }

    let db_lines = sqlx::query!(
        r#"
        SELECT 
            line.id,
            line.created_at,
            line.updated_at,
            line.deleted,
            line.conversation_id,
            line.thread_line_id,
            line.reply_to_line_id,
            line.sender_user_id as "sender_user_id?:db::UsersId",
            line.message,
            line.data,
            u.public_facing_id as "user_id?: String",
            u.display_name as "display_name?: String",

            parent.id as "parent_id?: db::LineId",
            parent.updated_at as "parent_timestamp?",
            parent.deleted as "parent_deleted?: bool",
            parent.message as "parent_message?: String",
            parent.data as "parent_data?: serde_json::Value",
            parent_user.public_facing_id as "parent_user_id?: String",
            parent_user.display_name as "parent_user_display_name?: String"

        FROM line
        LEFT OUTER JOIN users u ON u.id = line.sender_user_id

        LEFT OUTER JOIN line parent ON parent.id = line.reply_to_line_id
        LEFT OUTER JOIN users parent_user ON parent_user.id = parent.sender_user_id

        WHERE line.conversation_id = $1
        ORDER BY line.created_at DESC
        LIMIT 20
        "#,
        params.conversation_id.to_db_id(),
    )
    .fetch_all(pool.get_ref())
    .await?;

    // TODO MAKE USE OF PARENT MESSAGE

    let lines = db_lines
        .into_iter()
        .map(|row| 
            match row.sender_user_id {
                Some(sender_user_id) => Line {
                    line_id: row.id.into(),
                    timestamp: row.created_at.to_string(),
                    from: User {
                        id: row.user_id.expect("missing user_id"),
                        display_name: row.display_name.expect("missing display_name"),
                    },
                    message: row.message,
                    data: row.data,
                    reply_to_line: if let Some(parent_id) = &row.parent_id {
                        Some(ParentLine {
                            line_id: parent_id.into(),
                            timestamp: row.parent_timestamp.expect("impossible").to_string(),
                            from: User {
                                id: row.parent_user_id.expect("impossible"),
                                display_name: row.parent_user_display_name.expect("impossible"),
                            },
                            message: row.parent_message.expect("impossible"),
                            data: row.parent_data.expect("impossible"),
                        })
                    } else {
                        None
                    },
                },

                None => {
                    todo!("syste message")
                }
        })
        .rev()
        .collect();

    Ok(GetConversationMessagesOutput { lines })
}

pub async fn get_conversation_threads(
    session: Session,
    params: web::Path<GetConversationThreadsParams>,
    pool: web::Data<sqlx::PgPool>,
    _broadcaster: web::Data<Broadcaster>,
) -> Result<GetConversationThreadsOutput, ApiError<()>> {
    todo!("not implemented")
}

pub async fn send_message(
    session: Session,
    params: web::Path<SendMessageParams>,
    json: web::Json<SendMessageInput>,
    pool: web::Data<sqlx::PgPool>,
    broadcaster: web::Data<Broadcaster>,
) -> Result<NoOutput, ApiError<()>> {
    if json.message.is_empty() {
        return Err(ApiError::BadRequest {
            detail: "'content' field cannot be empty".to_string(),
        });
    }

    let parent: Option<(db::LineId, ParentLine)> = if let Some(reply_to_line_id) = &json.reply_to_line_id
    {
        let r = sqlx::query!(
            r#"
        SELECT
            line.id,
            line.updated_at,
            line.thread_line_id,
            line.message,
            line.data,

            users.public_facing_id as "public_facing_id?: String",
            users.display_name as "display_name?: String"
        FROM line
        LEFT OUTER JOIN users ON users.id = line.sender_user_id
        WHERE line.id = $1
        "#,
            reply_to_line_id.to_db_id()
        )
        .fetch_one(pool.get_ref())
        .await?;

        let parent = ParentLine {
            line_id: r.id.into(),
            timestamp: r.updated_at.to_string(),
            from: User {
                id: r.public_facing_id.unwrap_or("ERROR".to_string()),
                display_name: r.display_name.unwrap_or("ERROR".to_string()),
            },
            message: r.message,
            data: r.data
        };

        Some((
            r
            .thread_line_id
            .unwrap_or(reply_to_line_id.to_db_id()),
            parent)
        )
    } else {
        None
    };

    let mut transaction = pool.begin().await?;

    let row = sqlx::query!(
        r#"
        SELECT users.id as "user_id", conversation.id
        FROM conversation
        INNER JOIN conversation_participant ON conversation_participant.conversation_id = conversation.id AND conversation_participant.deleted = FALSE
        INNER JOIN users ON users.id = conversation_participant.user_id
        WHERE
            conversation.id = $1 
            AND users.public_facing_id = $2
        "#,
        params.conversation_id.to_db_id(),
        session.public_facing_id,
    ).fetch_one(&mut transaction).await?;

    let line = db::Line::insert(
        &mut transaction,
        db::InsertLine {
            conversation_id: params.conversation_id.to_db_id(),
            thread_line_id: parent.as_ref().map(|p| p.0),
            reply_to_line_id: json.reply_to_line_id.as_ref().map(|i| i.to_db_id()),

            sender_user_id: Some(row.user_id),
            message: &json.message,
            data: json.data.clone(),
        },
    )
    .await?;

    sqlx::query!(
        r#"
        UPDATE conversation
        SET
            updated_at = NOW()
        WHERE conversation.id = $1 
        "#,
        params.conversation_id.to_db_id(),
    )
    .execute(&mut transaction)
    .await?;

    transaction.commit().await?;

    broadcaster
        .broadcast_to_conversation(
            params.conversation_id.to_db_id(),
            BroadcastConversationEvent::Message {
                line_id: line.id,
                timestamp: line.created_at,
                user: User {
                    id: session.public_facing_id,
                    display_name: session.display_name,
                },
                message: json.message.to_string(),
                data: json.data.clone(),
                reply_to_line: parent.as_ref().map(|p| p.1.clone())
            },
        )
        .await;

    Ok(NoOutput {})
}

pub async fn start_typing(
    session: Session,
    params: web::Path<StartTypingParams>,
    pool: web::Data<sqlx::PgPool>,
    broadcaster: web::Data<Broadcaster>,
) -> Result<NoOutput, ApiError<()>> {
    // check that the user is a participant of the conversation
    let _ = db::ConversationParticipant::get_by_pk(
        pool.get_ref(),
        (session.id, params.conversation_id.to_db_id()),
    )
    .await?;

    broadcaster
        .broadcast_to_conversation(
            params.conversation_id.to_db_id(),
            BroadcastConversationEvent::StartTyping {
                user: User {
                    id: session.public_facing_id,
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
    // check that the user is a participant of the conversation
    let _ = db::ConversationParticipant::get_by_pk(
        pool.get_ref(),
        (session.id, params.conversation_id.to_db_id()),
    )
    .await?;

    broadcaster
        .broadcast_to_conversation(
            params.conversation_id.to_db_id(),
            BroadcastConversationEvent::EndTyping {
                user: User {
                    id: session.public_facing_id,
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
        INNER JOIN conversation_participant ON conversation_participant.conversation_id = conversation.id AND conversation_participant.deleted = FALSE
        INNER JOIN line ON line.conversation_id = conversation.id
        INNER JOIN users ON users.id = conversation_participant.user_id
        WHERE
            conversation.id = $1 
            AND users.public_facing_id = $2
            AND line.id = $3
        "#,
        json.conversation_id.to_db_id(),
        session.public_facing_id,
        json.line_id.to_db_id(),
    ).fetch_one(&mut transaction).await?;

    db::ConversationParticipant::update(
        &mut transaction,
        db::UpdateConversationParticipant {
            user_id: r.user_id,
            conversation_id: json.conversation_id.to_db_id(),
            lines_seen_until: Some(&r.created_at),
            deleted: None,
        },
    )
    .await?;

    transaction.commit().await?;

    Ok(NoOutput {})
}
