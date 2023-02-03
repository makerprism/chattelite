import { Field, Optional, Str, Vec } from 'gen-types';
import { Method, Route } from '../endpoint_types';
import { ot, t } from './type_names';

export let routes: Route[] = [
    {
        name: "get_conversations",
        url: "/conversations",
        method: Method.Get,
        url_params: [
        ],
        output_body_type: [
            Field("conversations", Vec(ot.Conversation)),
        ],
    },

    {
        name: "get_conversation_messages",
        url: "/conversation/{conversation_id}",
        method: Method.Get,
        url_params: [
            {
                name: "conversation_id",
                type: t.ConversationId,
            },
        ],
        output_body_type: [
            Field("lines", Vec(ot.Line)),
        ],
    },

    {
        name: "get_conversation_threads",
        url: "/conversation/{conversation_id}/threads",
        method: Method.Get,
        url_params: [
            {
                name: "conversation_id",
                type: t.ConversationId,
            },
        ],
        output_body_type: [
            Field("threads", Vec(ot.Thread)),
        ],
    },

    {
        name: "send_message",
        url: "/conversation/{conversation_id}",
        method: Method.Post,
        url_params: [
            {
                name: "conversation_id",
                type: t.ConversationId,
            },
        ],
        input_body_type: [
            Field("content", Str),
            Field("reply_to_line_id", Optional(t.LineId)),
        ],
    },

    {
        name: "start_typing",
        url: "/conversation/{conversation_id}/start-typing",
        method: Method.Post,
        url_params: [
            {
                name: "conversation_id",
                type: t.ConversationId,
            },
        ],
        input_body_type: [ ],
    },
    {
        name: "stop_typing",
        url: "/conversation/{conversation_id}/stop-typing",
        method: Method.Post,
        url_params: [
            {
                name: "conversation_id",
                type: t.ConversationId,
            },
        ],
        input_body_type: [ ],
    },
    {
        name: "mark_read",
        url: "/read",
        method: Method.Post,
        input_body_type: [ 
            Field("conversation_id", t.ConversationId),
            Field("line_id", t.LineId),
        ],
    },
];
