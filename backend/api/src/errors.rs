use actix_web::{error::ResponseError, http::StatusCode, HttpResponse};
use serde::Serialize;
use std::fmt::Debug;

#[derive(Debug, Serialize, Clone)]
pub enum ApiError<R> {
    NotFound { detail: String },
    NotAuthenticated { detail: String },
    Forbidden { detail: String },
    BadRequest { detail: String },
    InternalError { detail: String },
    RouteError(R),
}

impl std::fmt::Display for BaseErrorTag {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{:?}", self)
    }
}

impl<R: Debug> std::fmt::Display for ApiError<R> {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{:?}", self)
    }
}

impl<R: Debug> std::fmt::Display for ErrorResponse<R> {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{:?}", self)
    }
}

#[derive(Debug, Serialize, Clone)]
#[serde(tag = "type")]
pub enum BaseErrorTag {
    NotFound,
    NotAuthenticated,
    Forbidden,
    BadRequest,
    InternalError,
}

#[derive(Debug, Serialize)]
// https://blog.codecentric.de/2019/09/rest-standardisierte-fehlermeldungen-mittels-rfc-7807-problem-details/
#[serde(untagged)]
pub enum ErrorResponse<R> {
    BaseError {
        status: i32,
        title: String,
        detail: String,
        #[serde(flatten)]
        error: BaseErrorTag,
    },
    RouteError {
        status: i32,
        title: String,
        detail: String,
        #[serde(flatten)]
        error: R,
    },
}

impl<R: Clone + crate::generated::server_types::RouteError> ApiError<R> {
    fn title(&self) -> &'static str {
        match self {
            Self::NotFound { .. } => "Not found",
            Self::NotAuthenticated { .. } => "Not authorized",
            Self::Forbidden { .. } => "Forbidden",
            Self::BadRequest { .. } => "Bad request",
            Self::InternalError { .. } => "Internal error",
            Self::RouteError(e) => e.title(),
        }
    }

    fn detail(&self) -> String {
        match self {
            Self::NotFound { detail } => {
                detail.to_owned()
            }
            Self::NotAuthenticated { detail } => detail.to_owned(),
            Self::Forbidden { detail } => detail.to_owned(),
            Self::BadRequest { detail } => detail.to_owned(),
            Self::InternalError { detail } => {
                detail.to_owned()
            }
            Self::RouteError(e) => e.title().to_string(),
        }
    }

    fn status_code(&self) -> StatusCode {
        match self {
            Self::NotFound { .. } => StatusCode::NOT_FOUND,
            Self::NotAuthenticated { .. } => StatusCode::UNAUTHORIZED,
            Self::Forbidden { .. } => StatusCode::FORBIDDEN,
            Self::BadRequest { .. } => StatusCode::BAD_REQUEST,
            Self::InternalError { .. } => StatusCode::INTERNAL_SERVER_ERROR,
            Self::RouteError(e) => StatusCode::from_u16(e.status_code()).unwrap(),
        }
    }

    fn response_body(&self) -> ErrorResponse<R> {
        let status = self.status_code().as_u16() as i32;
        let title = self.title().to_string();
        let detail = self.detail();

        fn error<R>(
            t: BaseErrorTag,
            status: i32,
            title: String,
            detail: String,
        ) -> ErrorResponse<R> {
            ErrorResponse::BaseError {
                status,
                title,
                detail,
                error: t,
            }
        }

        match self {
            Self::NotFound { .. } => error(BaseErrorTag::NotFound, status, title, detail),
            Self::NotAuthenticated { .. } => {
                error(BaseErrorTag::NotAuthenticated, status, title, detail)
            }
            Self::Forbidden { .. } => error(BaseErrorTag::Forbidden, status, title, detail),
            Self::BadRequest { .. } => error(BaseErrorTag::BadRequest, status, title, detail),
            Self::InternalError { .. } => error(BaseErrorTag::InternalError, status, title, detail),
            Self::RouteError(e) => ErrorResponse::RouteError {
                status,
                title,
                detail,
                error: e.clone(),
            },
        }
    }
}

impl<R: Debug + Serialize + Clone + crate::generated::server_types::RouteError> ResponseError
    for ApiError<R>
{
    fn error_response(&self) -> HttpResponse {
        let status_code = self.status_code();

        HttpResponse::build(status_code).json(self.response_body())
    }
}

impl<R> std::convert::From<sqlx::Error> for ApiError<R> {
    fn from(err: sqlx::Error) -> Self {
        let e = err.to_string();
        match err {
            sqlx::Error::PoolTimedOut => ApiError::InternalError { detail: e },

            sqlx::Error::PoolClosed => ApiError::InternalError { detail: e },
            sqlx::Error::Protocol(_) => ApiError::InternalError { detail: e },
            sqlx::Error::Tls(_) => ApiError::InternalError { detail: e },
            sqlx::Error::WorkerCrashed => ApiError::InternalError { detail: e },
            sqlx::Error::Io(_) => ApiError::InternalError { detail: e },

            sqlx::Error::ColumnNotFound(_) => ApiError::InternalError { detail: e },
            sqlx::Error::ColumnDecode { .. } => ApiError::InternalError { detail: e },
            sqlx::Error::ColumnIndexOutOfBounds { .. } => ApiError::InternalError { detail: e },
            sqlx::Error::Configuration(_) => ApiError::InternalError { detail: e },
            sqlx::Error::Decode(_) => ApiError::InternalError { detail: e },
            sqlx::Error::TypeNotFound { .. } => ApiError::InternalError { detail: e },
            sqlx::Error::Migrate(_) => ApiError::InternalError { detail: e },
            sqlx::Error::Database(_) => ApiError::InternalError { detail: e },

            sqlx::Error::RowNotFound => ApiError::NotFound { detail: e },

            _ => ApiError::InternalError { detail: e },
        }
    }
}
