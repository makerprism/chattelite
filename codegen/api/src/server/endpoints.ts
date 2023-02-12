import { Field, Json, Nullable, Str, Vec } from 'gen-types';
import { Method, Route } from '../endpoint_types';
import { t } from './type_names';

export let routes: Route[] = [
    {
        name: "create_user",
        url: "/_/users",
        method: Method.Post,
        input_body_type: [
            Field("id", Str),
            Field("display_name", Str),
            Field("data", Json),
        ],
    },
    {
        name: "update_user",
        url: "/_/user/{user_id}",
        method: Method.Post,
        url_params: [
            {
                name: "user_id",
                type: Str,
            }
        ],
        input_body_type: [
            Field("id", Nullable(Str)),
            Field("display_name", Nullable(Str)),
            Field("data", Nullable(Json)),
        ],
    },
    {
        name: "delete_user",
        url: "/_/user/{user_id}",
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
        url: "/_/gen-client-jwt",
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
        url: "/_/conversations",
        method: Method.Post,
        input_body_type: [
            Field("data", Json),
            Field("user_ids", Vec(t.UserId)),
        ],
        output_body_type: [
            Field("conversation_id", t.ConversationId),
        ],
    },

    {
        name: "update_conversation",
        url: "/_/conversation/{conversation_id}",
        method: Method.Post,
        url_params: [
            {
                name: "conversation_id",
                type: t.ConversationId,
            }
        ],
        input_body_type: [
            Field("data", Json),
        ],
    },

    {
        name: "add_users_to_conversation",
        url: "/_/conversation/{conversation_id}/add-users",
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
        url: "/_/conversation/{conversation_id}/remove-users",
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
