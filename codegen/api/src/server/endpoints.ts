import { Field, Str, Vec } from 'gen-types';
import { Method, Route } from '../endpoint_types';
import { t } from './type_names';

export let routes: Route[] = [
    {
        name: "create_user",
        url: "/users",
        method: Method.Post,
        input_body_type: [
            Field("id", Str),
            Field("display_name", Str),
        ],
    },
    {
        name: "delete_user",
        url: "/user/{user_id}",
        method: Method.Delete,
        url_params: [
            {
                name: "user_id",
                type: Str,
            }
        ],
    },
    {
        name: "generate_client_jwt",
        url: "/gen-client-jwt",
        method: Method.Post,
        input_body_type: [
            Field("user_id", Str),
        ],
        output_body_type: [
            Field("jwt", Str),
        ]
    },

    {
        name: "create_conversation",
        url: "/conversations",
        method: Method.Post,
        input_body_type: [
            Field("user_ids", Vec(t.UserId)),
        ],
        output_body_type: [
            Field("conversation_id", t.ConversationId),
        ],
    },

    {
        name: "add_users_to_conversation",
        url: "/conversation/{conversation_id}/add-users",
        method: Method.Post,
        url_params: [
            {
                name: "conversation_id",
                type: t.ConversationId,
            }
        ],
        input_body_type: [
            Field("user_ids", Vec(t.UserId)),
        ],
    },

    {
        name: "remove_users_from_conversation",
        url: "/conversation/{conversation_id}/remove-users",
        method: Method.Post,
        url_params: [
            {
                name: "conversation_id",
                type: t.ConversationId,
            }
        ],
        input_body_type: [
            Field("user_ids", Vec(t.UserId)),
        ],
    },
];
