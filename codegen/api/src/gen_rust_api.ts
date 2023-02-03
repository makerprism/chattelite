import * as fs from 'fs';

import { Method, Route, UrlParam } from './endpoint_types';
import { TypeDeclaration } from './types';

import { routes as app_routes } from './server/endpoints';
import { input_types as app_input_types, output_types as app_output_types, shared_types as app_shared_types } from './server/types';

import { routes as client_routes } from './client/endpoints';
import { input_types as client_input_types, output_types as client_output_types, shared_types as client_shared_types } from './client/types';
import { ID_TYPE_DECLARATIONS } from './id_types';
import { Field, flatten_type_declaration, gen_rust, NestedField, NStruct, Struct, StructUnion, T, to_pascal_case, Type } from 'gen-types';


function gen_type_declaration_for_api_type(decl: TypeDeclaration, derives: string[]): string {
    switch (decl.tag) {
        case "validation_errors_type":
            switch (decl.fields_or_variants[0].tag) {
                case "field":
                    return `${gen_rust.gen_type_declaration(Struct(decl.name, decl.fields_or_variants as Field[]), [...derives, "Default", "PartialEq"])}
        
impl ${decl.name} {
pub fn is_valid(&self) -> bool {
    *self == Self::default()
}
}`;
                case "struct":
                    return `${gen_rust.gen_type_declaration(StructUnion(decl.name, decl.fields_or_variants as Struct[]), [...derives, "Default", "PartialEq"])}
        
impl ${decl.name} {
fn is_valid(&self) -> bool {
    *self == Self::default()
}
}`;
            }
        case "id_type":
            return `#[derive(Clone,Debug)]
pub struct ${decl.name}(i64);
impl Serialize for ${decl.name} {
    fn serialize<S>(&self, s: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        s.serialize_str(&id_type(&self.0, "${decl.prefix}"))
    }
}
impl<'de> Deserialize<'de> for ${decl.name}
{
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: Deserializer<'de>,
    {
        let s: &str = serde::de::Deserialize::deserialize(deserializer)?;
        from_id_type(s, "${decl.prefix}").map(${decl.name}).map_err(serde::de::Error::custom)
    }
}
impl From<i64> for ${decl.name} {
    fn from(item: i64) -> Self {
        ${decl.name}(item)
    }
}
impl From<&i64> for ${decl.name} {
    fn from(item: &i64) -> Self {
        ${decl.name}(*item)
    }
}
impl ${decl.name} {
    pub fn to_db_id(&self) -> i64 {
        self.0
    }
}`;
        default:
            break;
    }
    return flatten_type_declaration(decl).map((d) => gen_rust.gen_type_declaration(d, derives)).join("\n\n");
}
function gen_shared_type_declaration(decl: TypeDeclaration): string {
    return gen_type_declaration_for_api_type(decl, ["Deserialize", "Serialize", "Debug", "Clone"]);
}

function gen_output_type_declaration(decl: TypeDeclaration): string {
    return gen_type_declaration_for_api_type(decl, ["Serialize", "Debug", "Clone"]);
}

function gen_input_type_declaration(decl: TypeDeclaration): string {
    return gen_type_declaration_for_api_type(decl, ["Deserialize", "Debug"]);
}


export function gen_types(t: TypeDeclaration[], it: TypeDeclaration[], ot: TypeDeclaration[]): string {
    return `// AUTOMATICALLY GENERATED, DO NOT EDIT!!
use serde::{Serialize, Deserialize, Deserializer, Serializer};

${ID_TYPE_DECLARATIONS}
${gen_rust.NULLABLE_SERIALIZE_DESERIALIZE}

#[derive(Debug, Serialize)]
pub struct NoOutput {}

pub trait RouteError {
    fn title(&self) -> &'static str;
    fn status_code(&self) -> u16;
}

impl RouteError for () {
    fn title(&self) -> &'static str {
        "Never happens!"
    }
    fn status_code(&self) -> u16 {
        500
    }
}

// API input and output types
${t.map(gen_shared_type_declaration).join("\n\n")}

// API input types
${it.map(gen_input_type_declaration).join("\n\n")}

// API output types
${ot.map(gen_output_type_declaration).join("\n\n")}`;
}


// API endpoints

function get_url_params(endpoint: Route): UrlParam[] | null {
    if ("url_params" in endpoint && Array.isArray(endpoint.url_params) && endpoint.url_params.length != 0) {
        return endpoint.url_params;
    }
    return null;
}

function url_params_type_name(endpoint: Route): string {
    return to_pascal_case(endpoint.name) + "Params";
}

function gen_url_params_actix_path_type(endpoint: Route): string {
    let url_params = get_url_params(endpoint);
    if (url_params != null) {
        let url_params_type = Struct(url_params_type_name(endpoint),
            url_params.map((param) => Field(param.name, param.type))
        );
        return gen_rust.gen_type_declaration(url_params_type, ["Deserialize"]);
    }
    return "";
}

function gen_handler_query_param_type(endpoint: Route): string {
    if ("query_param_type" in endpoint && endpoint.query_param_type && endpoint.query_param_type.length > 0) {
        switch (endpoint.query_param_type[0].tag) {
            case "field":
                return gen_input_type_declaration(Struct(query_param_type_name(endpoint), endpoint.query_param_type as Field[]));
            case "struct":
                return gen_input_type_declaration(StructUnion(query_param_type_name(endpoint), endpoint.query_param_type as Struct[]));
            default:
                throw "not implemented!";
        }
    }
    return "";
}

function gen_handler_input_body_type(endpoint: Route): string {
    if ("input_body_type" in endpoint && endpoint.input_body_type && endpoint.input_body_type.length > 0) {
        switch (endpoint.input_body_type[0].tag) {
            case "field":
                return gen_input_type_declaration(Struct(input_body_type_name(endpoint), endpoint.input_body_type as Field[]));
            case "struct":
                return gen_input_type_declaration(StructUnion(input_body_type_name(endpoint), endpoint.input_body_type as Struct[]));
            case "nested_field":
                return gen_input_type_declaration(NStruct(input_body_type_name(endpoint), endpoint.input_body_type as NestedField[]));
            default:
                throw "not implemented!";
        }
    }
    return "";
}

function gen_handler_output_body_type(endpoint: Route): string {
    if (endpoint.output_body_type && endpoint.output_body_type.length > 0) {
        switch (endpoint.output_body_type[0].tag) {
            case "field":
                return gen_output_type_declaration(Struct(output_type_name(endpoint), endpoint.output_body_type as Field[]));
            case "struct":
                return gen_output_type_declaration(StructUnion(output_type_name(endpoint), endpoint.output_body_type as Struct[]));
            case "nested_field":
                return gen_output_type_declaration(NStruct(output_type_name(endpoint), endpoint.output_body_type as NestedField[]));
            default:
                throw "not implemented!";
        }
    }
    return "";

}

function gen_handler_error_type(endpoint: Route): string {
    if (endpoint.error_type) {
        return `${gen_output_type_declaration({
            tag: "struct_union",
            name: error_type_name(endpoint),
            variants: endpoint.error_type.map((e) => e.variant),
        })}
        
impl RouteError for ${error_type_name(endpoint)} {
    fn status_code(&self) -> u16 {
        match self {
${endpoint.error_type.map((e) => `            Self::${e.variant.name} {..} => ${e.status_code},`)}
        }
    }
    fn title(&self) -> &'static str {
        match self {
${endpoint.error_type.map((e) => `            Self::${e.variant.name} {..} => "${e.title}",`)}
        }
    }
}`;
    }
    return "";
}

// endpoint handler parameters
type HandlerParam = {
    name: string,
    declaration: string;
};

function add_query_param(acc: HandlerParam[], query_param_type?: Type): HandlerParam[] {
    if (query_param_type) {
        acc.push({ name: "q", declaration: `web::Query<${gen_rust.render_type(query_param_type)}>` });
    }
    return acc;
}

function add_url_params(acc: HandlerParam[], endpoint: Route): HandlerParam[] {
    if (get_url_params(endpoint) != null) {
        acc.push({ name: "params", declaration: `web::Path<${url_params_type_name(endpoint)}>` });
    }
    return acc;
}

function add_req_param(acc: HandlerParam[], server_req: boolean | undefined): HandlerParam[] {
    if (server_req) {
        acc.push({ name: "req", declaration: `actix_web::HttpRequest` });
    }
    return acc;
}

function add_session_param(acc: HandlerParam[]): HandlerParam[] {
    acc.push({ name: "session", declaration: "Session" });

    return acc;
}

function add_input_body_param(acc: HandlerParam[], input_body_type: Type | undefined): HandlerParam[] {
    if (input_body_type)
        acc = [...acc, { name: "json", declaration: `web::Json<${gen_rust.render_type(input_body_type)}>` }];
    return acc;
}

function add_default_params(acc: HandlerParam[]) {
    acc.push({ name: "pool", declaration: "web::Data<sqlx::PgPool>" });
    acc.push({ name: "broadcaster", declaration: "web::Data<Broadcaster>" });
    return acc;
}

function gen_handler_params(endpoint: Route): HandlerParam[] {
    let params: HandlerParam[] = [];
    switch (endpoint.method) {
        case Method.Get:
            params = add_req_param(params, endpoint.server_req);
            params = add_session_param(params);
            params = add_url_params(params, endpoint);
            if (query_param_type_name(endpoint) != "") {
                params = add_query_param(params, T(query_param_type_name(endpoint)));
            }
            params = add_default_params(params);
            break;
        case Method.Post:
            params = add_req_param(params, endpoint.server_req);
            params = add_session_param(params);
            params = add_url_params(params, endpoint);
            if (input_body_type_name(endpoint) != "") {
                params = add_input_body_param(params, T(input_body_type_name(endpoint)));
            }
            params = add_default_params(params);
            break;
        case Method.Delete:
            params = add_req_param(params, endpoint.server_req);
            params = add_session_param(params);
            params = add_url_params(params, endpoint);
            params = add_default_params(params);
            break;
    }
    return params;
}

function error_type_name(endpoint: Route): string {
    if (endpoint.error_type && endpoint.error_type.length > 0) {
        return to_pascal_case(endpoint.name) + "Errors";
    }
    return "()";
}

function query_param_type_name(endpoint: Route): string {
    if ("query_param_type" in endpoint && endpoint.query_param_type && endpoint.query_param_type.length > 0) {
        return to_pascal_case(endpoint.name) + "Query";
    }
    return "";
}


function input_body_type_name(endpoint: Route): string {
    if ("input_body_type" in endpoint && endpoint.input_body_type && endpoint.input_body_type.length > 0) {
        return to_pascal_case(endpoint.name) + "Input";
    }
    return "";
}

function output_type_name(endpoint: Route): string {
    if (endpoint.output_body_type && endpoint.output_body_type.length > 0) {
        return to_pascal_case(endpoint.name) + "Output";
    }
    return "NoOutput";
}

function gen_handler_types(endpoint: Route): string {
    return [gen_url_params_actix_path_type(endpoint),
    gen_handler_query_param_type(endpoint),
    gen_handler_input_body_type(endpoint),
    gen_handler_error_type(endpoint),
    gen_handler_output_body_type(endpoint),
    ].join("\n")
}

function gen_handler_body(endpoint: Route, handler_params: HandlerParam[]): string {
    let ok_result_response = "Ok(r) => Ok(HttpResponse::Ok().json(&r))";

    return `let result: Result<${output_type_name(endpoint)}, ApiError<${error_type_name(endpoint)}>>
    = crate::handlers::${endpoint.name}(
        ${handler_params.map((p) => p.name).join(", ")}
    ).await;
match result {
    ${ok_result_response},
    Err(e) => Err(e),
}`;
}

function gen_handler(endpoint: Route): string {
    let handler_params = gen_handler_params(endpoint);
    return `async fn ${endpoint.name} (
    ${handler_params.map((p) => `${p.name}: ${p.declaration}`).join(",\n    ")}
) -> impl Responder {
    ${gen_handler_body(endpoint, handler_params)}
}`;
}

function gen_route(endpoint: Route): string {
    return `.route("${endpoint.url}", web::${endpoint.method}().to(${endpoint.name}))`;
}

export function gen_server_endpoints(): [string, string] {
    return [`// THIS FILE HAS BEEN AUTOMATICALLY GENERATED BY codegen/maker_database_api_types/src/api/endpoints.ts. DO NOT EDIT!
use crate::session::app::Session;
use crate::errors::ApiError;
use actix_web::{web, Responder, HttpResponse};
use super::app_types::*;
use crate::realtime::broadcast::Broadcaster;

${app_routes.map(gen_handler).join("\n\n")}

pub fn routes(cfg: &mut web::ServiceConfig) {
    cfg
    ${app_routes.map((route) => gen_route(route)).join("\n    ")};
}`, app_routes.map(gen_handler_types).join("\n\n")];
}

export function gen_client_endpoints(): [string, string] {
    return [`// THIS FILE HAS BEEN AUTOMATICALLY GENERATED BY codegen/maker_database_api_types/src/api/endpoints.ts. DO NOT EDIT!
use crate::session::client::Session;
use crate::errors::ApiError;
use actix_web::{web, Responder, HttpResponse};
use super::client_types::*;
use crate::realtime::broadcast::Broadcaster;

${client_routes.map(gen_handler).join("\n\n")}

pub fn routes(cfg: &mut web::ServiceConfig) {
    cfg
    ${client_routes.map((route) => gen_route(route)).join("\n    ")};
}`, client_routes.map(gen_handler_types).join("\n\n")];
}


export function gen() {
    // app
    let app_rust_types = gen_types(app_shared_types, app_input_types, app_output_types);
    let [app_rust_endpoints, app_endpoint_param_types] = gen_server_endpoints();

    if (!fs.existsSync("./../../backend/api/src/generated")) fs.mkdirSync("./../../backend/api/src/generated");
    fs.writeFileSync('./../../backend/api/src/generated/server_types.rs', app_rust_types + "\n\n" + app_endpoint_param_types);
    fs.writeFileSync('./../../backend/api/src/generated/server_endpoints.rs', app_rust_endpoints);


    // client

    let client_rust_types = gen_types(client_shared_types, client_input_types, client_output_types);
    let [client_rust_endpoints, client_endpoint_param_types] = gen_client_endpoints();

    if (!fs.existsSync("./../../backend/api/src/generated")) fs.mkdirSync("./../../backend/api/src/generated");
    fs.writeFileSync('./../../backend/api/src/generated/client_types.rs', client_rust_types + "\n\n" + client_endpoint_param_types);
    fs.writeFileSync('./../../backend/api/src/generated/client_endpoints.rs', client_rust_endpoints);
}
