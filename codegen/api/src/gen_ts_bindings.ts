import * as fs from 'fs';

//import { to_pascal_case } from 'gen-types/utils';

import { Method, Route } from './endpoint_types';
import { TypeDeclaration } from './types';

import { routes as app_routes } from './app/endpoints';
import * as app from './app/types';

import { routes as client_routes } from './client/endpoints';
import * as client from './client/types';
import { Field, flatten_type_declaration, gen_typescript, NestedField, NStruct, Struct, StructUnion, to_pascal_case } from 'gen-types';
import { render_type } from 'gen-types/lib/gen/rust';

const type_namespace = "T.";

function gen_type_declaration_for_api_type(decl: TypeDeclaration): string {

    switch (decl.tag) {

        case "validation_errors_type":
            switch (decl.fields_or_variants[0].tag) {
                case "field":
                    return gen_typescript.gen_type_declaration(Struct(decl.name, decl.fields_or_variants as Field[]));

                case "struct":
                    return gen_typescript.gen_type_declaration(StructUnion(decl.name, decl.fields_or_variants as Struct[]));
            }
        case "id_type":
            return `export type ${decl.name} = string;`;

        default:
            break;
    }

    return flatten_type_declaration(decl).map(gen_typescript.gen_type_declaration).join("\n\n");
}

function gen_types(t: TypeDeclaration[], it: TypeDeclaration[], ot: TypeDeclaration[]): string {
    return `// API input and output types
${t.map(gen_type_declaration_for_api_type).join("\n\n")}
    
// API input types
${it.map(gen_type_declaration_for_api_type).join("\n\n")}
    
// API output types
${ot.map(gen_type_declaration_for_api_type).join("\n\n")}
`;
}

// API endpoints
function gen_route_function_body(route: Route, url: string): string {
    let params = [
        `\`${url}\``,
        ...route_params(route, false).map(p => p.name)
    ];
    switch (route.method) {
        case Method.Get:
            return `return utils.get(${params.join(", ")});`;
            break;
        case Method.Post:
            return `return utils.post(${params.join(", ")});`;
            break;
        case Method.Delete:
            return `return utils.del(${params.join(", ")});`;
        default:
            throw ("not implemented!");
    }
}

function error_type_name(endpoint: Route, type_namespace?: string): string {
    if (endpoint.error_type && endpoint.error_type.length > 0) {
        return (type_namespace || "")+to_pascal_case(endpoint.name) + "Errors";
    }
    return "void";
}

function gen_error_type(endpoint: Route): string {
    if (endpoint.error_type && endpoint.error_type.length > 0) {
        return `${gen_type_declaration_for_api_type({
            tag: "struct_union",
            name: error_type_name(endpoint),
            variants: endpoint.error_type.map((e) => e.variant),
        })};\n\n`;
    }
    return "";
}

function query_param_type_name(endpoint: Route, type_namespace?: string): string {
    if ("query_param_type" in endpoint && endpoint.query_param_type && endpoint.query_param_type.length > 0) {
        return (type_namespace || "")+to_pascal_case(endpoint.name) + "Query";
    }
    return "{}";
}


function input_body_type_name(endpoint: Route, type_namespace?: string): string {
    if ("input_body_type" in endpoint && endpoint.input_body_type && endpoint.input_body_type.length > 0) {
        return (type_namespace || "")+to_pascal_case(endpoint.name) + "Input";
    }
    return "{}";
}

function output_type_name(endpoint: Route, type_namespace?: string): string {
    if (endpoint.output_body_type && endpoint.output_body_type.length > 0) {
        return (type_namespace || "")+to_pascal_case(endpoint.name) + "Output";
    }
    return "{}";
}

function gen_query_param_type(endpoint: Route): string {
    if ("query_param_type" in endpoint && endpoint.query_param_type && endpoint.query_param_type.length > 0) {
        switch (endpoint.query_param_type[0].tag) {
            case "field":
                return gen_type_declaration_for_api_type(Struct(query_param_type_name(endpoint), endpoint.query_param_type as Field[])) + ";\n\n";
            case "struct":
                return gen_type_declaration_for_api_type(StructUnion(query_param_type_name(endpoint), endpoint.query_param_type as Struct[])) + ";\n\n";
            case "nested_field":
                return gen_type_declaration_for_api_type(NStruct(query_param_type_name(endpoint), endpoint.query_param_type as NestedField[])) + ";\n\n";
            default:
                throw "not implemented!";
        }
    }
    return "";
}

function gen_input_type(endpoint: Route): string {
    if ("input_body_type" in endpoint && endpoint.input_body_type && endpoint.input_body_type.length > 0) {
        switch (endpoint.input_body_type[0].tag) {
            case "field":
                return gen_type_declaration_for_api_type(Struct(input_body_type_name(endpoint), endpoint.input_body_type as Field[])) + ";\n\n";
            case "struct":
                return gen_type_declaration_for_api_type(StructUnion(input_body_type_name(endpoint), endpoint.input_body_type as Struct[])) + ";\n\n";
            case "nested_field":
                return gen_type_declaration_for_api_type(NStruct(input_body_type_name(endpoint), endpoint.input_body_type as NestedField[])) + ";\n\n";
            default:
                throw "not implemented!";
        }
    }
    return "";
}

function gen_output_type(endpoint: Route): string {
    if (endpoint.output_body_type && endpoint.output_body_type.length > 0) {
        switch (endpoint.output_body_type[0].tag) {
            case "field":
                return gen_type_declaration_for_api_type(Struct(output_type_name(endpoint), endpoint.output_body_type as Field[])) + ";\n\n";
            case "struct":
                return gen_type_declaration_for_api_type(StructUnion(output_type_name(endpoint), endpoint.output_body_type as Struct[])) + ";\n\n";
            case "nested_field":
                return gen_type_declaration_for_api_type(NStruct(output_type_name(endpoint), endpoint.output_body_type as NestedField[])) + ";\n\n";
            default:
                throw "not implemented!";
        }
    }
    return "";
}

function response_type_name(endpoint: Route): string {
    return to_pascal_case(endpoint.name) + "Response";
}

function gen_response_type(endpoint: Route): string {
    return `export type ${response_type_name(endpoint)} = utils.ApiResponse<${output_type_name(endpoint, type_namespace)}, ${error_type_name(endpoint,type_namespace)}>;\n\n`;
}


function opts_decl(opts: { name: string, type: string; }[]): { name: string, type: string; } {
    return { name: "opts", type: `{ ${opts.map(o => `${o.name}: ${o.type}`).join(", ")}}` };
}

function route_opts(route: Route): { name: string, type: string; }[] {
    let opts: { name: string, type: string; }[] = [];
    opts.push({ name: "session_token", type: "string" });

    return opts;
}

function route_params(route: Route, for_declaration: boolean): { name: string, type: string; }[] {
    let url_params = (route.url_params || []).map((p) => {
        return { name: p.name, type: render_type(p.type, type_namespace) };
    });

    let params: { name: string, type: string; }[] = [];
    let opts = route_opts(route);
    switch (route.method) {
        case Method.Get:

            if (opts.length > 0) params.push(opts_decl(opts));
            if (for_declaration) { 
                params = [...params, ...url_params];
            }
            if (for_declaration) { 
                if (route.query_param_type) params.push({ name: "q", type: input_body_type_name(route, type_namespace) });
            }

            break;
        case Method.Post:
            if (opts.length > 0) params.push(opts_decl(opts));
            if (for_declaration) { 
                params = [...params, ...url_params];
            }
            if (route.input_body_type) params.push({ name: "body", type: input_body_type_name(route, type_namespace) });

            break;
        case Method.Delete:
            if (opts.length > 0) params.push(opts_decl(opts));
            if (for_declaration) { 
                params = [...params, ...url_params];
            }

            break;
        default:
            throw ("not implemented!");
    }
    return params;
}

function gen_route(route: Route): {types: string, code: string} {
    let url = route.url.replace(/{/g, "${");
    let params: string[] = route_params(route, true).map(p => `${p.name}: ${p.type}`);

    if (route.method == Method.Get) {
        if (route.query_param_type) {
            url += "${utils.stringify_query(q)}";
        }
    }

    return {
        types: `${gen_query_param_type(route)}${gen_input_type(route)}${gen_output_type(route)}${gen_error_type(route)}`,
        code: `${gen_response_type(route)}export function ${route.name} (
    ${params.join(",\n    ")}
): Promise<${response_type_name(route)}> {
    ${gen_route_function_body(route, url)}
}`};
}

function gen_endpoints(routes: Route[]): {types:string,code:string} {
    let r = routes.map((route) => gen_route(route));
    return {
        types: `${r.map((x) => x.types).join("\n\n")}`,
        code: `${r.map((x) => x.code).join("\n\n")}`
    };
}



// output ts files

function gen_bindings(path: string, types: {t: TypeDeclaration[], it: TypeDeclaration[], ot: TypeDeclaration[]}, routes: Route[]) {
    let endpoint_fns = gen_endpoints(routes);

    let ts_types = `// AUTOMATICALLY GENERATED, DO NOT EDIT!!
export namespace Types {
${gen_types(types.t, types.it, types.ot)}

${endpoint_fns.types}
}
`;
    let endpoints_ts_code = `// AUTOMATICALLY GENERATED, DO NOT EDIT!!
import type { Types as T } from "@types";
import * as utils from "@utils";

export namespace Endpoints {
${endpoint_fns.code}
}`;

    if (!fs.existsSync(`${path}`)) fs.mkdirSync(`${path}`);
    fs.writeFileSync(`${path}/types.ts`, ts_types);
    fs.writeFileSync(`${path}/endpoints.ts`, endpoints_ts_code);
}


export function gen() {
    gen_bindings("./../../sdks/TypeScript/app/src/generated", {
        t: app.shared_types,
        it: app.input_types,
        ot: app.output_types,
    }, app_routes);

    gen_bindings("./../../sdks/TypeScript/client/src/generated", {
        t: client.shared_types,
        it: client.input_types,
        ot: client.output_types,
    }, client_routes);
}
