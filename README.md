# chattelite - self-hostable chat API with strictly-typed SDKs (where possible)


BIG WARNING: THIS IS HIGHLY EXPERIMENTAL, DON'T USE THIS - yes, learn from it, mess with it, build something from this, whatever you want, but don't assume that it works!

Also, I may be rewriting this to OCaml.


If you have ever wanted to add in-app chat to you application or site, you might have tried one or more chat API providers (e.g. Vonage/Nexmo, PubNub, Ably, etc.).

This is a basic prototype of a chat-"microservice" (create/delete users, create conversations, sending text messages, join/leave events, as well as a typing indicator within conversation). It
can be self-hosted (will be installable in the future as a .deb package or compiled from source), and
comes with typed API-bindings / SDKs (WIP TypeScript bindings, Go upcoming).

Goals:
1. work out-of-the box with minimal configuration (install .deb package and set up database)
2. client SDKs should come with precise types (to the extent of the expressibility of the target language)
3. client SDKs should be lightweight / low-dependency

Non-Goals:
- horizontal scalability / distributed setup - this project is intended for apps/sites whose chat needs can be serviced by a single machine

More details:
The current implementation uses Server-Sent-Events for realtime updates from server to client. All communication from client to server goes via HTTP. This seems to be the simplest setup to benefit from the strictly typed API endpoints immediately.

Stack: 
- backend (chat service): Rust, actix_web, sqlx, PostgreSQL
- api codegen (generates types, endpoint wrappers for client SDKs and chat service): TypeScript
- db codegen (generates sql schema for the database, and sqlx-based input/update types and functions for all tables): TypeScript
- client SDKs: TypeScript / Go / future additions

Websockets could be added, however, then, in the client libs, we will need to make sure to provice a Futures-/Promise-based API, in order to expose the response type-guarantees at call-site.

