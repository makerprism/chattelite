import { TypeAlias, Str, Struct, Field } from 'gen-types';
import { IdType } from '../id_types';
import { TypeDeclaration } from '../types';
import { it, ot, t } from './type_names';

export let shared_types: TypeDeclaration[] = [
    IdType(t.ConversationId, "CON"),

    TypeAlias(t.Username, Str),
    TypeAlias(t.DateTime, Str),
];

export let input_types: TypeDeclaration[] = [
    
];

export let output_types: TypeDeclaration[] = [
    Struct(ot.Message, [
        Field("created_at", t.DateTime),
        Field("created_by", t.Username),
        Field("content", Str),
    ]),
];
