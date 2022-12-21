import { Struct, Field, NestedTypeDeclaration, Optional } from "gen-types";
import * as id_type from "./id_types";

// validation type
export type ValidationErrorsType = {
    tag: "validation_errors_type",
    name: string,
    fields_or_variants: Struct[] | Field[],
};

export function ValidationErrorsType(name: string, fields_or_variants: Struct[] | Field[]): ValidationErrorsType {
    return {
        tag: "validation_errors_type",
        name: name,
        fields_or_variants: fields_or_variants,
    };
}

export type TypeDeclaration = NestedTypeDeclaration | ValidationErrorsType | id_type.IdType;

// turn a field into an optional field
export function optional(f: Field) {
    return {
        tag: f.tag,
        name: f.name,
        type: Optional(f.type),
    };
};
