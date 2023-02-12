import * as Types from "./generated/types";
import * as Endpoints from "./generated/endpoints";
import { API_URL, init, JWT } from "./config";
import EventSourceWithHeaders from "event-source-with-headers";

export type ConversationEventSource = {
    onerror: (evt: Event) => any;
    onmessage: (evt: MessageEvent) => any;
    onopen: (evt: Event) => any;
    close(): void;
}

function listen_to_conversation(conversation_id: Types.ConversationId): ConversationEventSource {
    if (!JWT) throw "JWT needs to be set via ChatteliteClient.init or ChatteliteClient.set_jwt";
    return new EventSourceWithHeaders(API_URL + "/conversation/" + conversation_id + "/sse", { headers: { "X-Access-Token": JWT } })
}

const ChatteliteClient = {
    init,
    listen_to_conversation,
    ...Types,
    ...Endpoints,
}

export default ChatteliteClient;
