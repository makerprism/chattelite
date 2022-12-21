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
        name: "create_conversation",
        url: "/conversations",
        method: Method.Post,
        input_body_type: [
            Field("participants", Vec(t.Username)),
        ],
        output_body_type: [
            Field("conversation_id", t.ConversationId),
        ],
    },
];
