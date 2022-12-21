import { Field, Str, Vec } from 'gen-types';
import { Method, Route } from '../endpoint_types';
import { ot, t } from './type_names';

export let routes: Route[] = [
    {
        name: "get_messages",
        url: "/conversation/{conversation_id}/messages",
        method: Method.Get,
        url_params: [
            {
                name: "conversation_id",
                type: t.ConversationId,
            },
        ],
        output_body_type: [
            Field("messages", Vec(ot.Message)),
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
        ],
    },

    {
        name: "conversation_start_typing",
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
        name: "conversation_stop_typing",
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
];
