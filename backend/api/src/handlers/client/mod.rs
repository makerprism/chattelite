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
            COUNT (message.line_id) as unread
        FROM conversation_participant
        INNER JOIN users ON users.id = conversation_participant.user_id
        INNER JOIN conversation ON conversation.id = conversation_participant.conversation_id
        LEFT JOIN line ON line.conversation_id = conversation.id
        LEFT JOIN message ON
            message.line_id = line.id
            AND (line.created_at > conversation_participant.lines_seen_until)
        WHERE users.public_facing_id = $1
        GROUP BY conversation.id
        ORDER BY conversation.updated_at DESC
        LIMIT 20
        "#,
        session.public_facing_id
    )
    .fetch_all(pool.get_ref())
    .await?;

    let newest_messages = sqlx::query!(
        r#"
        SELECT DISTINCT ON (line.conversation_id)
            line.id,
            line.conversation_id,
            line.created_at,
            line.updated_at,
            users.public_facing_id,
            users.display_name,
            message.content
        FROM line
        INNER JOIN message ON message.line_id = line.id
        INNER JOIN users ON message.created_by = users.id
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

    let mut newest_message_lookup = std::collections::HashMap::new();
    for m in newest_messages {
        newest_message_lookup.insert(m.conversation_id, m);
    }

    let conversations = db_conversations
        .iter()
        .map(|c| {
            let m = newest_message_lookup.get(&c.id);

            Conversation {
                conversation_id: c.id.into(),
                timestamp: c.updated_at.to_string(),
                number_of_unread_messages: c.unread.unwrap_or(0) as i32,
                newest_message: if let Some(m) = m {
                    Some(Message {
                        line_id: m.id.into(),
                        timestamp: m.created_at.to_string(),
                        from: User {
                            id: m.public_facing_id.to_string(),
                            display_name: m.display_name.to_string(),
                        },
                        content: m.content.to_string(),
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
                INNER JOIN users ON users.id = conversation_participant.user_id
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
            system_event.kind as "kind?: db::SystemEventKind",

            u1.public_facing_id as "user_id1?: String",
            u1.display_name as "display_name1?: String",

            u2.public_facing_id as "user_id2?: String",
            u2.display_name as "display_name2?: String",
            message.content as "content?: String",

            parent.id as "parent_id?: db::LineId",
            parent.updated_at as "parent_timestamp",
            parent.deleted as "parent_deleted?: bool",
            parent_user.public_facing_id as "parent_user_id?: String",
            parent_user.display_name as "parent_user_display_name?: String",
            parent_message.content as "parent_message_content?: String"

        FROM line
        LEFT OUTER JOIN system_event ON system_event.line_id = line.id
        LEFT OUTER JOIN message ON message.line_id = line.id
        LEFT OUTER JOIN users u1 ON u1.id = system_event.user_id
        LEFT OUTER JOIN users u2 ON u2.id = message.created_by

        LEFT OUTER JOIN line parent ON parent.id = line.reply_to_line_id
        LEFT OUTER JOIN message parent_message ON parent_message.line_id = parent.id
        LEFT OUTER JOIN users parent_user ON parent_user.id = parent_message.created_by

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
        .map(|row| match row.kind {
            Some(db::SystemEventKind::Join) => Line::Join {
                line_id: row.id.into(),
                timestamp: row.created_at.to_string(),
                from: User {
                    id: row.user_id1.expect("missing user_id"),
                    display_name: row.display_name1.expect("missing display_name"),
                },
            },

            Some(db::SystemEventKind::Leave) => Line::Leave {
                line_id: row.id.into(),
                timestamp: row.created_at.to_string(),
                from: User {
                    id: row.user_id1.expect("missing user_id"),
                    display_name: row.display_name1.expect("missing display_name"),
                },
            },

            None => match row.content {
                Some(content) => Line::Message {
                    line_id: row.id.into(),
                    timestamp: row.created_at.to_string(),
                    from: User {
                        id: row.user_id2.expect("missing user_id"),
                        display_name: row.display_name2.expect("missing display_name"),
                    },
                    content: content,
                    reply_to_line: if let Some(parent_id) = &row.parent_id {
                        Some(ParentLine::Message {
                            line_id: parent_id.into(),
                            timestamp: row.parent_timestamp.to_string(),
                            from: User {
                                id: row.parent_user_id.expect("impossible"),
                                display_name: row.parent_user_display_name.expect("impossible"),
                            },
                            content: row.parent_message_content.unwrap_or("".to_string()),
                        })
                    } else {
                        None
                    },
                },

                None => {
                    panic!("chat line is neither a system event nor a message")
                }
            },
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
    if json.content.is_empty() {
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

            message.content as "content?: String",

            users.public_facing_id as "public_facing_id?: String",
            users.display_name as "display_name?: String"
        FROM line
        LEFT OUTER JOIN message ON message.line_id = line.id
        LEFT OUTER JOIN users ON users.id = created_by
        WHERE line.id = $1
        "#,
            reply_to_line_id.to_db_id()
        )
        .fetch_one(pool.get_ref())
        .await?;

        let parent = ParentLine::Message { line_id: r.id.into(), timestamp: r.updated_at.to_string(), from: User {
            id: r.public_facing_id.unwrap_or("ERROR".to_string()),
            display_name: r.display_name.unwrap_or("ERROR".to_string()),
        }, content: r.content.unwrap_or("".to_string()) };

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
        INNER JOIN conversation_participant ON conversation_participant.conversation_id = conversation.id
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
                content: json.content.to_string(),
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
        INNER JOIN conversation_participant ON conversation_participant.conversation_id = conversation.id
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
        },
    )
    .await?;

    transaction.commit().await?;

    Ok(NoOutput {})
}
