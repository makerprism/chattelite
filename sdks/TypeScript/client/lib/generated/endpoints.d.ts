import * as T from "@types";
import * as utils from "@utils";
export type GetConnectionEventsResponse = utils.ApiResponse<T.GetConnectionEventsOutput, void>;
export declare function get_connection_events(opts: {
    session_token: string;
}): Promise<GetConnectionEventsResponse>;
export type GetConversationEventsResponse = utils.ApiResponse<T.GetConversationEventsOutput, void>;
export declare function get_conversation_events(opts: {
    session_token: string;
}, conversation_id: T.ConversationId): Promise<GetConversationEventsResponse>;
export type SendMessageResponse = utils.ApiResponse<{}, void>;
export declare function send_message(opts: {
    session_token: string;
}, conversation_id: T.ConversationId, body: T.SendMessageInput): Promise<SendMessageResponse>;
export type StartTypingResponse = utils.ApiResponse<{}, void>;
export declare function start_typing(opts: {
    session_token: string;
}, conversation_id: T.ConversationId, body: {}): Promise<StartTypingResponse>;
export type StopTypingResponse = utils.ApiResponse<{}, void>;
export declare function stop_typing(opts: {
    session_token: string;
}, conversation_id: T.ConversationId, body: {}): Promise<StopTypingResponse>;
export type MarkReadResponse = utils.ApiResponse<{}, void>;
export declare function mark_read(opts: {
    session_token: string;
}, body: T.MarkReadInput): Promise<MarkReadResponse>;
