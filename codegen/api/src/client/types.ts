import { TypeAlias, Str, Struct, Field, NStruct, StructUnion } from 'gen-types';
import { IdType } from '../id_types';
import { TypeDeclaration } from '../types';
import { it, ot, t } from './type_names';

export let shared_types: TypeDeclaration[] = [
    TypeAlias(t.UserId, Str),
    IdType(t.ConversationId, "CON"),
    IdType(t.LineId, "LINE"),

    TypeAlias(t.user_id, Str),
    TypeAlias(t.DateTime, Str),
];

export let input_types: TypeDeclaration[] = [
    
];

export let output_types: TypeDeclaration[] = [
    Struct(ot.User, [
        Field("id", t.UserId),
        Field("display_name", Str),
    ]),

    StructUnion(ot.ConnectionEvent, [
        Struct("UnreadMessage", [
            Field("timestamp", t.DateTime),
            Field("conversation_id", t.ConversationId),
            Field("from", ot.User),
        ]),
    ]),

    StructUnion(ot.ConversationEvent, [
        Struct("Message", [
            Field("timestamp", t.DateTime),
            Field("from", ot.User),
            Field("content", Str),
        ]),

        Struct("Join", [
            Field("timestamp", t.DateTime),
            Field("from", ot.User),
        ]),
    
        Struct("Leave", [
            Field("timestamp", t.DateTime),
            Field("from", ot.User),
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
