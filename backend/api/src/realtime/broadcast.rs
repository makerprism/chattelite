use std::{sync::Arc, time::Duration};

use actix_web::rt::time::interval;
use actix_web_lab::sse::{self, ChannelStream, Sse};
use chrono::{DateTime, Utc};
use futures_util::future;
use parking_lot::Mutex;
use serde::Serialize;

use crate::generated::client_types::ConversationEvent;

pub struct Broadcaster {
    inner: Mutex<BroadcasterInner>,
}

#[derive(Debug, Clone, Default)]
struct Conversation {
    currently_typing: std::collections::HashMap<db::AccountId, DateTime<Utc>>,
    clients: Vec<sse::Sender>,
}

#[derive(Debug, Clone, Default)]
struct BroadcasterInner {
    conversations: std::collections::HashMap<db::ConversationId, Conversation>,
}

async fn broadcast<Data: Serialize>(clients: &[sse::Sender], data: &Data) {
    let send_futures = clients.iter().map(|client| {
        client.send(sse::Data::new(
            serde_json::to_string(&data).expect("failed to serialize JSON for broadcast"),
        ))
    });

    // try to send to all clients, ignoring failures
    // disconnected clients will get swept up by periodic housekeeping
    let _ = future::join_all(send_futures).await;
}

pub enum BroadcastConversationEvent {
    StartTyping {
        account_id: db::AccountId,
    },
    EndTyping {
        account_id: db::AccountId,
    },
    Join {
        username: String,
        timestamp: chrono::DateTime<chrono::Utc>,
    },
    Leave {
        username: String,
        timestamp: chrono::DateTime<chrono::Utc>,
    },
    Message {
        username: String,
        timestamp: chrono::DateTime<chrono::Utc>,
        content: String,
    },
}

impl Broadcaster {
    pub fn create() -> Arc<Self> {
        let this = Arc::new(Broadcaster {
            inner: Mutex::new(BroadcasterInner::default()),
        });

        Broadcaster::spawn_housekeeper(Arc::clone(&this));

        this
    }

    fn spawn_housekeeper(this: Arc<Self>) {
        actix_web::rt::spawn(async move {
            let mut interval = interval(Duration::from_secs(15));

            loop {
                interval.tick().await;
                this.housekeep().await;
            }
        });
    }

    async fn housekeep(&self) {
        let conversations = self.inner.lock().conversations.clone();

        let mut ok_conversations = std::collections::HashMap::new();

        for (id, conversation) in conversations {
            for client in conversation.clients {
                if client
                    .send(sse::Event::Comment("ping".into()))
                    .await
                    .is_ok()
                {
                    let ok_conversation = ok_conversations.entry(id).or_insert_with(|| {
                        let currently_typing = std::collections::HashMap::from_iter(
                            conversation.currently_typing.iter().filter_map(
                                |(username, timestamp)| {
                                    if chrono::Utc::now().timestamp_millis() - timestamp.timestamp_millis() < 15000
                                    {
                                        Some((username.clone(), timestamp.clone()))
                                    } else {
                                        None
                                    }
                                },
                            ),
                        );

                        Conversation {
                            currently_typing,
                            clients: vec![],
                        }
                    });
                    ok_conversation.clients.push(client.clone());
                }
            }
        }

        self.inner.lock().conversations = ok_conversations;
    }

    pub async fn add_client_to_conversation(
        &self,
        conversation_id: db::ConversationId,
    ) -> Sse<ChannelStream> {
        let (tx, rx) = sse::channel(10);

        tx.send(sse::Data::new("connected")).await.unwrap();

        {
            let mut l = self.inner.lock();
            let conversation = l
                .conversations
                .entry(conversation_id)
                .or_insert(Conversation {
                    currently_typing: std::collections::HashMap::new(),
                    clients: vec![],
                });
            conversation.clients.push(tx);
        }

        rx
    }

    pub async fn broadcast_to_conversation(
        &self,
        conversation_id: db::ConversationId,
        data: BroadcastConversationEvent,
    ) {
        let (clients, conversation_event) = {
            let mut l = self.inner.lock();
            let maybe_conversation = l.conversations.get_mut(&conversation_id);

            if maybe_conversation.is_none() {
                return;
            }

            let conversation: &mut Conversation = maybe_conversation.expect("impossible");

            let conversation_event = match data {
                BroadcastConversationEvent::StartTyping { account_id } => {
                    let now = chrono::Utc::now();

                    log::info!("1 start typing, currently_typing: {:?}", conversation.currently_typing);

                    let ce = match conversation.currently_typing.insert(account_id, now) {
                        None => {
                            ConversationEvent::StartTyping {
                                from: account_id.to_string(), // TODO
                                timestamp: now.to_string(),
                            }
                        }

                        Some(started_typing_timestamp) => {
                            log::info!("started_typing_timestamp: {:?}, now: {:?}, now-then:{:?}",
                            started_typing_timestamp.timestamp_millis(),
                            now.timestamp_millis(), 
                            now.timestamp_millis() - started_typing_timestamp.timestamp_millis()
                         );
                            if now.timestamp_millis() - started_typing_timestamp.timestamp_millis()
                                < 5000
                            {
                                return;
                            } else {
                                ConversationEvent::StartTyping {
                                    from: account_id.to_string(), //TODO
                                    timestamp: now.to_string(),
                                }
                            }
                        }
                    };
                    log::info!("2 start typing, currently_typing: {:?}", conversation.currently_typing);
                    ce

                }
                BroadcastConversationEvent::EndTyping { account_id } => {
                    let now = chrono::Utc::now();

                    conversation.currently_typing.remove(&account_id);
                    ConversationEvent::EndTyping {
                        from: account_id.to_string(), //TODO
                        timestamp: now.to_string(),
                    }
                }
                BroadcastConversationEvent::Join {
                    username,
                    timestamp,
                } => ConversationEvent::Join {
                    from: username,
                    timestamp: timestamp.to_string(),
                },
                BroadcastConversationEvent::Leave {
                    username,
                    timestamp,
                } => ConversationEvent::Leave {
                    from: username,
                    timestamp: timestamp.to_string(),
                },
                BroadcastConversationEvent::Message {
                    username,
                    timestamp,
                    content,
                } => ConversationEvent::Message {
                    from: username,
                    timestamp: timestamp.to_string(),
                    content,
                },
            };

            (&conversation.clients.clone(), conversation_event)
        };

        broadcast(&clients, &conversation_event).await;
    }
}
