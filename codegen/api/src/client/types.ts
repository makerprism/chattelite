import { TypeAlias, Str, Struct, Field, StructUnion, I32, Nullable, Optional, Vec } from 'gen-types';
import { IdType } from '../id_types';
import { TypeDeclaration } from '../types';
import { it, ot, t } from './type_names';

export let shared_types: TypeDeclaration[] = [
    TypeAlias(t.UserId, Str),
    IdType(t.ConversationId, "CON"),
    IdType(t.LineId, "LINE"),

    TypeAlias(t.DateTime, Str),
];

export let input_types: TypeDeclaration[] = [
    
];

const Message = Struct(ot.Message, [
    Field("line_id", t.LineId),
    Field("timestamp", t.DateTime),
    Field("from", ot.User),
    Field("content", Str),
    Field("reply_to_line", Optional(ot.ParentLine)),
]);

const Join = Struct("Join", [
    Field("line_id", t.LineId),
    Field("timestamp", t.DateTime),
    Field("from", ot.User),
]);

const Leave = Struct("Leave", [
    Field("line_id", t.LineId),
    Field("timestamp", t.DateTime),
    Field("from", ot.User),
]);

export let output_types: TypeDeclaration[] = [
    Struct(ot.User, [
        Field("id", t.UserId),
        Field("display_name", Str),
    ]),

    Message,

    Struct(ot.Conversation, [
        Field("conversation_id", t.ConversationId),
        Field("timestamp", t.DateTime),
        Field("number_of_unread_messages", I32),
        Field("newest_message", Nullable(ot.Message)),
    ]),

    StructUnion(ot.ParentLine, [
        Struct("Message", [
            Field("line_id", t.LineId),
            Field("timestamp", t.DateTime),
            Field("from", ot.User),
            Field("content", Str),
        ]),
        Join,
        Leave,
    ]),

    StructUnion(ot.Line, [
        Message,
        Join,
        Leave,
    ]),

    Struct(ot.Thread, [
        Field("line", ot.Line),
        Field("replies", Vec(ot.Line)),
    ]),

    StructUnion(ot.ConversationEvent, [
        Struct("NewLine", [
            Field("line", ot.Line),
        ]),

        Struct("StartTyping", [
            Field("timestamp", t.DateTime),
            Field("from", ot.User),
        ]),

        Struct("EndTyping", [
            Field("timestamp", t.DateTime),
            Field("from", ot.User),
        ]),
    ]),
];
