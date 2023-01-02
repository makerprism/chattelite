use std::{sync::Arc, time::Duration};

use actix_web::rt::time::interval;
use actix_web_lab::sse::{self, ChannelStream, Sse};
use futures_util::future;
use parking_lot::Mutex;
use serde::Serialize;


pub struct Broadcaster {
    inner: Mutex<BroadcasterInner>,
}

#[derive(Debug, Clone, Default)]
struct BroadcasterInner {
    clients: Vec<sse::Sender>,
}

impl Broadcaster {
    pub fn create() -> Arc<Self> {
        let this = Arc::new(Broadcaster {
            inner: Mutex::new(BroadcasterInner::default()),
        });

        Broadcaster::spawn_ping(Arc::clone(&this));

        this
    }

    fn spawn_ping(this: Arc<Self>) {
        actix_web::rt::spawn(async move {
            let mut interval = interval(Duration::from_secs(15));

            loop {
                interval.tick().await;
                this.ping_and_remove_stale_clients().await;
            }
        });
    }

    async fn ping_and_remove_stale_clients(&self) {
        let clients = self.inner.lock().clients.clone();

        let mut ok_clients = Vec::new();

        for client in clients {
            if client
                .send(sse::Event::Comment("ping".into()))
                .await
                .is_ok()
            {
                ok_clients.push(client.clone());
            }
        }

        self.inner.lock().clients = ok_clients;
    }

    pub async fn new_client(&self) -> Sse<ChannelStream> {
        let (tx, rx) = sse::channel(10);

        tx.send(sse::Data::new("connected")).await.unwrap();

        self.inner.lock().clients.push(tx);

        rx
    }

    pub async fn broadcast<Data: Serialize>(&self, data: &Data) {
        let clients = self.inner.lock().clients.clone();

        let send_futures = clients
            .iter()
            .map(|client| client.send(sse::Data::new(
                serde_json::to_string(&data).expect("failed to serialize JSON for broadcast")
            )));

        // try to send to all clients, ignoring failures
        // disconnected clients will get swept up by `ping_and_remove_stale_clients`
        let _ = future::join_all(send_futures).await;
    }
}
