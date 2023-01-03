use actix_web::web;

use crate::errors::ApiError;
use crate::generated::app_types::*;
use crate::generated::client_types::ConversationEvent;
use crate::realtime::broadcast::{BroadcastConversationEvent, Broadcaster};
use crate::session::app::Session;

pub async fn create_user(
    _session: Session,
    json: web::Json<CreateUserInput>,
    pool: web::Data<sqlx::PgPool>,
    _broadcaster: web::Data<Broadcaster>,
) -> Result<NoOutput, ApiError<()>> {
    let mut transaction = pool.begin().await?;

    db::Account::insert(
        &mut transaction,
        db::InsertAccount {
            username: &json.username,
        },
    )
    .await?;

    transaction.commit().await?;

    Ok(NoOutput {})
}

pub async fn delete_user(
    _session: Session,
    params: web::Path<DeleteUserParams>,
    pool: web::Data<sqlx::PgPool>,
    _broadcaster: web::Data<Broadcaster>,
) -> Result<NoOutput, ApiError<()>> {
    let mut transaction = pool.begin().await?;

    sqlx::query!(
        r#"
        DELETE from account
        WHERE username = $1"#,
        params.username,
    )
    .execute(&mut transaction)
    .await?;

    transaction.commit().await?;

    Ok(NoOutput {})
}

pub async fn generate_client_jwt(
    _session: Session,
    json: web::Json<GenerateClientJwtInput>,
    pool: web::Data<sqlx::PgPool>,
    _broadcaster: web::Data<Broadcaster>,
) -> Result<GenerateClientJwtOutput, ApiError<()>> {
    let account = sqlx::query!(
        r#"
        SELECT id FROM account
        WHERE username = $1
        "#,
        json.username
    )
    .fetch_one(pool.get_ref())
    .await?;

    let jwt = crate::session::client::Session {
        account_id: account.id,
        username: json.username.to_string(),
    }
    .encode(&crate::CLIENT_JWT_SECRET, 3600)
    .map_err(|_| ApiError::InternalError {
        detail: "failed to encode client JWT".to_string(),
    })?;

    Ok(GenerateClientJwtOutput { jwt })
}

pub async fn create_conversation(
    _session: Session,
    json: web::Json<CreateConversationInput>,
    pool: web::Data<sqlx::PgPool>,
    _broadcaster: web::Data<Broadcaster>,
) -> Result<CreateConversationOutput, ApiError<()>> {
    let mut transaction = pool.begin().await?;

    let participants = sqlx::query!(
        r#"
        SELECT id FROM account WHERE username = ANY ($1)
        "#,
        &json.users
    )
    .fetch_all(&mut transaction)
    .await?;

    if participants.len() != json.users.len() {
        return Err(ApiError::BadRequest {
            detail: format!("not all of these users seem to exist"),
        });
    }

    let conversation_id = db::Conversation::insert_returning_pk(&mut transaction).await?;

    for participant in participants {
        db::ConversationParticipant::insert_returning_pk(
            &mut transaction,
            db::InsertConversationParticipant {
                conversation_id,
                account_id: participant.id,
            },
        )
        .await?;

        let line_id = db::Line::insert_returning_pk(
            &mut transaction,
            db::InsertLine {
                conversation_id,
                thread_line_id: None,
                reply_to_line_id: None,
            },
        )
        .await?;

        db::SystemEvent::insert(
            &mut transaction,
            db::InsertSystemEvent {
                line_id,
                kind: db::SystemEventKind::Join,
                account_id: Some(participant.id),
            },
        )
        .await?;
    }

    transaction.commit().await?;

    Ok(CreateConversationOutput {
        conversation_id: conversation_id.into(),
    })
}

pub async fn add_users_to_conversation(
    _session: Session,
    params: web::Path<AddUsersToConversationParams>,
    json: web::Json<AddUsersToConversationInput>,
    pool: web::Data<sqlx::PgPool>,
    broadcaster: web::Data<Broadcaster>,
) -> Result<NoOutput, ApiError<()>> {
    let mut transaction = pool.begin().await?;

    let participants = sqlx::query!(
        r#"
        SELECT id, username FROM account WHERE username = ANY ($1)
        "#,
        &json.users
    )
    .fetch_all(&mut transaction)
    .await?;

    if participants.len() != json.users.len() {
        return Err(ApiError::BadRequest {
            detail: format!("not all of these users seem to exist"),
        });
    }

    let conversation =
        db::Conversation::get_by_pk(&mut transaction, params.conversation_id.to_db_id()).await?;

    let mut join_lines: Vec<(db::Line, String)> = vec![];

    for participant in participants {
        db::ConversationParticipant::insert_returning_pk(
            &mut transaction,
            db::InsertConversationParticipant {
                conversation_id: conversation.id,
                account_id: participant.id,
            },
        )
        .await?;
        /* IMPROVE: it would be ok if we add users that are already in the conversation,
        but then we don't need to add a line of them being added.  */

        let line = db::Line::insert(
            &mut transaction,
            db::InsertLine {
                conversation_id: conversation.id,
                thread_line_id: None,
                reply_to_line_id: None,
            },
        )
        .await?;

        db::SystemEvent::insert(
            &mut transaction,
            db::InsertSystemEvent {
                line_id: line.id,
                kind: db::SystemEventKind::Join,
                account_id: Some(participant.id),
            },
        )
        .await?;

        join_lines.push((line, participant.username));
    }

    db::Conversation::update(
        &mut transaction,
        db::UpdateConversation {
            id: conversation.id,
        },
    )
    .await?;

    transaction.commit().await?;

    for (line, username) in join_lines {
        broadcaster
            .broadcast_to_conversation(
                params.conversation_id.to_db_id(),
                BroadcastConversationEvent::Join {
                    timestamp: line.created_at,
                    username: username,
                },
            )
            .await;
    }

    Ok(NoOutput {})
}

pub async fn remove_users_from_conversation(
    _session: Session,
    params: web::Path<RemoveUsersFromConversationParams>,
    json: web::Json<RemoveUsersFromConversationInput>,
    pool: web::Data<sqlx::PgPool>,
    broadcaster: web::Data<Broadcaster>,
) -> Result<NoOutput, ApiError<()>> {
    let mut transaction = pool.begin().await?;

    let participants = sqlx::query!(
        r#"
        SELECT account.id, account.username
        FROM account 
        INNER JOIN conversation_participant ON conversation_participant.account_id = account.id
        WHERE username = ANY ($1)
            AND conversation_participant.conversation_id = $2
        "#,
        &json.users,
        params.conversation_id.to_db_id()
    )
    .fetch_all(&mut transaction)
    .await?;

    if participants.len() != json.users.len() {
        return Err(ApiError::BadRequest {
            detail: format!("not all of these users seem to exist in this conversation"),
        });
    }

    let account_ids: Vec<db::AccountId> = participants.iter().map(|r| r.id).collect();

    sqlx::query!(
        r#"
        DELETE FROM conversation_participant
        WHERE account_id = ANY ($1)
            AND conversation_id = $2
        "#,
        &account_ids,
        params.conversation_id.to_db_id()
    )
    .execute(&mut transaction)
    .await?;

    let conversation =
        db::Conversation::get_by_pk(&mut transaction, params.conversation_id.to_db_id()).await?;

    let mut leave_lines: Vec<(db::Line, String)> = vec![];

    for participant in participants {
        let line = db::Line::insert(
            &mut transaction,
            db::InsertLine {
                conversation_id: conversation.id,
                thread_line_id: None,
                reply_to_line_id: None,
            },
        )
        .await?;

        db::SystemEvent::insert(
            &mut transaction,
            db::InsertSystemEvent {
                line_id: line.id,
                kind: db::SystemEventKind::Leave,
                account_id: Some(participant.id),
            },
        )
        .await?;

        leave_lines.push((line, participant.username));
    }

    db::Conversation::update(
        &mut transaction,
        db::UpdateConversation {
            id: conversation.id,
        },
    )
    .await?;

    transaction.commit().await?;

    for (line, username) in leave_lines {
        broadcaster
            .broadcast_to_conversation(
                params.conversation_id.to_db_id(),
                BroadcastConversationEvent::Leave {
                    timestamp: line.created_at,
                    username,
                },
            )
            .await;
    }

    Ok(NoOutput {})
}
