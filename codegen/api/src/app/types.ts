import { TypeAlias, Str } from 'gen-types';
import { IdType } from '../id_types';
import { TypeDeclaration } from '../types';
import { it, ot, t } from './type_names';

export let shared_types: TypeDeclaration[] = [
    TypeAlias(t.UserId, Str),
    IdType(t.ConversationId, "CON"),

    //TypeAlias(t.DateTime, Str),

];

export let input_types: TypeDeclaration[] = [
    
];

export let output_types: TypeDeclaration[] = [

];
