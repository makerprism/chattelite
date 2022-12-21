import { Type, Struct, Field, Str, NestedField, NestedStruct } from "gen-types";

export enum Method {
    Get = "get",
    Post = "post",
    Delete = "delete",
}

export type UrlParam = {
    name: string,
    type: Type,
}

// the error type of a route is a StructUnion of all the different error types
export type ErrorVariant = {
    variant: Struct,
    status_code: number,
    title: string,
};

export function ValidationError(t: Type): ErrorVariant {
    return { 
        variant: 
            Struct("ValidationError", [
                Field("detail", Str),
                Field("field_errors", t),
            ]),
        status_code: 400,
        title: "Some fields failed to validate!"
    }
}

export type GetRoute = {
    method: Method.Get,

    name: string,
    url: string,

    url_params?: UrlParam[],
    query_param_type?: Field[] | NestedField[] | Struct[] | NestedStruct[],
    output_body_type?: Field[] | Struct[],
    error_type?: ErrorVariant[],

    server_req?: boolean, // if true, on the server, the handler will be able to inspect the HttpRequest
}

export type PostRoute = {
    method: Method.Post,

    name: string,
    url: string,

    url_params?: UrlParam[],
    input_body_type?: Field[] | NestedField[] | Struct[] | NestedStruct[],
    output_body_type?: Field[] | NestedField[] | Struct[] | NestedStruct[],
    error_type?: ErrorVariant[],

    server_req?: boolean, // if true, on the server, the handler will be able to inspect the HttpRequest
}


export type DeleteRoute = {
    method: Method.Delete,

    name: string,
    url: string,

    url_params?: UrlParam[],
    output_body_type?: Field[] | Struct[] | NestedStruct[] | NestedField[],
    error_type?: ErrorVariant[],

    server_req?: boolean, // if true, on the server, the handler will be able to inspect the HttpRequest
}


export type Route = GetRoute | PostRoute | DeleteRoute
