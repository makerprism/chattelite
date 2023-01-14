import { TypeAlias, Str, Struct, Field, NStruct, StructUnion, I32 } from 'gen-types';
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

export let output_types: TypeDeclaration[] = [
    Struct(ot.User, [
        Field("id", t.UserId),
        Field("display_name", Str),
    ]),

    Struct(ot.Conversation, [
        Field("conversation_id", t.ConversationId),
        Field("timestamp", t.DateTime),
        Field("number_of_unread_messages", I32),
        Field("newest_message_from", ot.User),
        Field("newest_message_synopsis", Str),
    ]),

    StructUnion(ot.Line, [
        Struct("Message", [
            Field("line_id", t.LineId),
            Field("timestamp", t.DateTime),
            Field("from", ot.User),
            Field("content", Str),
        ]),

        Struct("Join", [
            Field("line_id", t.LineId),
            Field("timestamp", t.DateTime),
            Field("from", ot.User),
        ]),
    
        Struct("Leave", [
            Field("line_id", t.LineId),
            Field("timestamp", t.DateTime),
            Field("from", ot.User),
        ]),
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
