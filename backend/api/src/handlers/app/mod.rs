use actix_web::web;

use crate::errors::ApiError;
use crate::generated::app_types::*;
use crate::session::app::Session;

pub async fn create_user (
    _session: Session,
    json: web::Json<CreateUserInput>,
    pool: web::Data<sqlx::PgPool>
) -> Result<NoOutput, ApiError<()>> {
    let mut transaction = pool.begin().await?;

    db::Account::insert(&mut transaction, db::InsertAccount {
        username: &json.username,
    }).await?;

    transaction.commit().await?;

    Ok(NoOutput {  })
}

pub async fn delete_user (
    _session: Session,
    params: web::Path<DeleteUserParams>,
    pool: web::Data<sqlx::PgPool>
) -> Result<NoOutput, ApiError<()>> {
    let mut transaction = pool.begin().await?;

    sqlx::query!(r#"
        DELETE from account
        WHERE username = $1"#,
    params.username,
    ).execute(&mut transaction).await?;

    transaction.commit().await?;
    
    Ok(NoOutput {  })
}

pub async fn create_conversation (
    _session: Session,
    json: web::Json<CreateConversationInput>,
    pool: web::Data<sqlx::PgPool>
) ->  Result<CreateConversationOutput, ApiError<()>> {
    let mut transaction = pool.begin().await?;

    let participants = sqlx::query!(
        r#"
        SELECT id FROM account WHERE username = ANY ($1)
        "#,
        &json.participants
    ).fetch_all(&mut transaction).await?;

    if participants.len() != json.participants.len() {
        return Err(ApiError::BadRequest { detail: "not all of these users seem to exist".to_string() })
    }

    let conversation_id = db::Conversation::insert_returning_pk(&mut transaction, db::InsertConversation{}).await?;

    for participant in participants {
        db::ConversationParticipant::insert_returning_pk(&mut transaction, db::InsertConversationParticipant{
            conversation_id,
            account_id: participant.id,
        }).await?;
    }

    transaction.commit().await?;
    
    Ok(CreateConversationOutput { conversation_id: conversation_id.into() })
}
