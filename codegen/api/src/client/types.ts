import { TypeAlias, Str, Struct, Field, NStruct, StructUnion } from 'gen-types';
import { IdType } from '../id_types';
import { TypeDeclaration } from '../types';
import { it, ot, t } from './type_names';

export let shared_types: TypeDeclaration[] = [
    IdType(t.ConversationId, "CON"),
    IdType(t.LineId, "LINE"),

    TypeAlias(t.Username, Str),
    TypeAlias(t.DateTime, Str),
];

export let input_types: TypeDeclaration[] = [
    
];

export let output_types: TypeDeclaration[] = [

    StructUnion(ot.ConnectionEvent, [
        Struct("UnreadMessage", [
            Field("timestamp", t.DateTime),
            Field("conversation_id", t.ConversationId),
            Field("from", t.Username),
        ]),
    ]),

    StructUnion(ot.ConversationEvent, [
        Struct("Message", [
            Field("timestamp", t.DateTime),
            Field("from", t.Username),
            Field("content", Str),
        ]),

        Struct("Join", [
            Field("timestamp", t.DateTime),
            Field("from", t.Username),
        ]),
    
        Struct("Leave", [
            Field("timestamp", t.DateTime),
            Field("from", t.Username),
        ]),
    
        Struct("StartTyping", [
            Field("timestamp", t.DateTime),
            Field("from", t.Username),
        ]),

        Struct("EndTyping", [
            Field("timestamp", t.DateTime),
            Field("from", t.Username),
        ]),
    ]),
];
