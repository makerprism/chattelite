import { Field, Str, Vec } from 'gen-types';
import { Method, Route } from '../endpoint_types';
import { t } from './type_names';

export let routes: Route[] = [
    {
        name: "create_user",
        url: "/users",
        method: Method.Post,
        input_body_type: [
            Field("username", Str),
        ],
    },
    {
        name: "delete_user",
        url: "/user/{username}",
        method: Method.Delete,
        url_params: [
            {
                name: "username",
                type: Str,
            }
        ],
    },
    {
        name: "generate_client_jwt",
        url: "/gen-client-jwt",
        method: Method.Post,
        input_body_type: [
            Field("username", Str),
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
            Field("users", Vec(t.Username)),
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
            Field("users", Vec(t.Username)),
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
            Field("users", Vec(t.Username)),
        ],
    },
];
