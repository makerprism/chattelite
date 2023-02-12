use actix_web::web;

use crate::errors::ApiError;
use crate::generated::client_types::User;
use crate::generated::server_types::*;
use crate::realtime::broadcast::{BroadcastConversationEvent, Broadcaster};
use crate::session::app::Session;

pub async fn create_user(
    _session: Session,
    json: web::Json<CreateUserInput>,
    pool: web::Data<sqlx::PgPool>,
    _broadcaster: web::Data<Broadcaster>,
) -> Result<NoOutput, ApiError<()>> {
    let mut transaction = pool.begin().await?;

    db::Users::insert(
        &mut transaction,
        db::InsertUsers {
            public_facing_id: &json.id,
            display_name: &&json.display_name,
            data: json.data.clone(),
        },
    )
    .await?;

    transaction.commit().await?;

    Ok(NoOutput {})
}

pub async fn update_user(
    _session: Session,
    params: web::Path<UpdateUserParams>,
    json: web::Json<UpdateUserInput>,
    pool: web::Data<sqlx::PgPool>,
    _broadcaster: web::Data<Broadcaster>,
) -> Result<NoOutput, ApiError<()>> {
    let mut transaction = pool.begin().await?;

    let user = sqlx::query!(
        r#"
        SELECT id FROM users
        WHERE public_facing_id = $1"#,
        params.user_id,
    )
    .fetch_one(&mut transaction)
    .await?;

    db::Users::update(
        &mut transaction,
        db::UpdateUsers {
            id: user.id,
            deleted: None,

            public_facing_id: json.id.as_ref(),
            display_name: json.display_name.as_ref(),
            data: json.data.clone(),
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

    let user = sqlx::query!(
        r#"
        SELECT id FROM users
        WHERE public_facing_id = $1"#,
        params.user_id,
    )
    .fetch_one(&mut transaction)
    .await?;

    db::Users::update(
        &mut transaction,
        db::UpdateUsers {
            id: user.id,
            deleted: Some(true),

            public_facing_id: None,
            display_name: None,
            data: None,
        },
    )
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
    let user = sqlx::query!(
        r#"
        SELECT public_facing_id, display_name FROM users
        WHERE public_facing_id = $1
        "#,
        json.user_id
    )
    .fetch_one(pool.get_ref())
    .await?;

    let jwt = crate::session::client::JWTSession {
        user_id: user.public_facing_id,
        display_name: user.display_name,
    }
    .encode(&crate::config::CONFIG.client_jwt_secret, 36000) // 10 hours
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
        SELECT id FROM users WHERE public_facing_id = ANY ($1)
        "#,
        &json.user_ids
    )
    .fetch_all(&mut transaction)
    .await?;

    if participants.len() != json.user_ids.len() {
        return Err(ApiError::BadRequest {
            detail: format!("not all of these users seem to exist"),
        });
    }

    let conversation_id = db::Conversation::insert_returning_pk(
        &mut transaction,
        db::InsertConversation {
            data: json.data.clone(),
        },
    )
    .await?;

    for participant in participants {
        db::ConversationParticipant::insert_returning_pk(
            &mut transaction,
            db::InsertConversationParticipant {
                conversation_id,
                user_id: participant.id,
            },
        )
        .await?;

        // TODO: allow a system message to be posted together with adding someone to a Conversation
    }

    transaction.commit().await?;

    Ok(CreateConversationOutput {
        conversation_id: conversation_id.into(),
    })
}

pub async fn update_conversation(
    _session: Session,
    params: web::Path<UpdateConversationParams>,
    json: web::Json<UpdateConversationInput>,
    pool: web::Data<sqlx::PgPool>,
    _broadcaster: web::Data<Broadcaster>,
) -> Result<NoOutput, ApiError<()>> {
    let mut transaction = pool.begin().await?;

    db::Conversation::update(
        &mut transaction,
        db::UpdateConversation {
            id: params.conversation_id.to_db_id(),
            data: Some(json.data.clone()),
        },
    )
    .await?;

    transaction.commit().await?;

    Ok(NoOutput {})
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
        SELECT id, public_facing_id, display_name FROM users WHERE public_facing_id = ANY ($1)
        "#,
        &json.user_ids
    )
    .fetch_all(&mut transaction)
    .await?;

    let rejoining_participants: Vec<db::UsersId> = sqlx::query!(
        r#"
        SELECT user_id FROM conversation_participant WHERE conversation_id = $1 AND user_id = ANY ($2)
        "#,
        params.conversation_id.to_db_id(),
        &participants.iter().map(|p| p.id).collect::<Vec<db::UsersId>>(),
    ).fetch_all(&mut transaction).await?.iter().map(|r| r.user_id).collect();

    if participants.len() != json.user_ids.len() {
        return Err(ApiError::BadRequest {
            detail: format!("not all of these users seem to exist"),
        });
    }

    let conversation =
        db::Conversation::get_by_pk(&mut transaction, params.conversation_id.to_db_id()).await?;

    let mut join_lines: Vec<(chrono::DateTime<chrono::Utc>, String, String)> = vec![];

    for participant in participants {
        let timestamp = if rejoining_participants.contains(&participant.id) {
            db::ConversationParticipant::update(
                &mut transaction,
                db::UpdateConversationParticipant {
                    conversation_id: conversation.id,
                    user_id: participant.id,
                    deleted: Some(false),
                    lines_seen_until: None,
                },
            )
            .await?
        } else {
            db::ConversationParticipant::insert(
                &mut transaction,
                db::InsertConversationParticipant {
                    conversation_id: conversation.id,
                    user_id: participant.id,
                },
            )
            .await?.updated_at
        };

        // TODO: implement INSERT ON CONFLICT for history models
        /* TODO: allow posting a system message together with the adding of a user */

        join_lines.push((
            timestamp,
            participant.public_facing_id,
            participant.display_name,
        ));
    }

    db::Conversation::update(
        &mut transaction,
        db::UpdateConversation {
            id: conversation.id,
            data: None,
        },
    )
    .await?;

    transaction.commit().await?;

    for (timestamp, id, display_name) in join_lines {
        broadcaster
            .broadcast_to_conversation(
                params.conversation_id.to_db_id(),
                BroadcastConversationEvent::Join {
                    timestamp,
                    user: User { id, display_name },
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
        SELECT users.id, users.public_facing_id, users.display_name
        FROM users 
        INNER JOIN conversation_participant ON conversation_participant.user_id = users.id AND conversation_participant.deleted = FALSE
        WHERE public_facing_id = ANY ($1)
            AND conversation_participant.conversation_id = $2
        "#,
        &json.user_ids,
        params.conversation_id.to_db_id()
    )
    .fetch_all(&mut transaction)
    .await?;

    if participants.len() != json.user_ids.len() {
        return Err(ApiError::BadRequest {
            detail: format!("not all of these users seem to exist in this conversation"),
        });
    }

    let mut leavers: Vec<(String, String, chrono::DateTime<chrono::Utc>)> = vec![];

    for participant in participants {
        // TODO: implement bulk update with history

        /* TODO: allow system message on every leave? */

        let timestamp = db::ConversationParticipant::update(
            &mut transaction,
            db::UpdateConversationParticipant {
                user_id: participant.id,
                conversation_id: params.conversation_id.to_db_id(),
                lines_seen_until: None,
                deleted: Some(true),
            },
        )
        .await?;

        leavers.push((
            participant.public_facing_id,
            participant.display_name,
            timestamp,
        ));
    }

    let conversation =
        db::Conversation::get_by_pk(&mut transaction, params.conversation_id.to_db_id()).await?;

    db::Conversation::update(
        &mut transaction,
        db::UpdateConversation {
            id: conversation.id,
            data: None,
        },
    )
    .await?;

    transaction.commit().await?;

    for (public_facing_id, display_name, timestamp) in leavers {
        broadcaster
            .broadcast_to_conversation(
                params.conversation_id.to_db_id(),
                BroadcastConversationEvent::Leave {
                    timestamp,
                    user: User {
                        id: public_facing_id,
                        display_name,
                    },
                },
            )
            .await;
    }

    Ok(NoOutput {})
}
