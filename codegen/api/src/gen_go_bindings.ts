import * as fs from 'fs';

import { Method, Route } from './endpoint_types';
import { TypeDeclaration } from './types';

import { routes as app_routes } from './app/endpoints';
import * as app from './app/types';

import { routes as client_routes } from './client/endpoints';
import * as client from './client/types';

import { Struct, Field, StructUnion, flatten_type_declaration, to_pascal_case, NStruct, NestedField, gen_go } from 'gen-types';


const type_namespace = "types.";

function gen_type_declaration_for_api_type(decl: TypeDeclaration): string {

    switch (decl.tag) {

        case "validation_errors_type":
            switch (decl.fields_or_variants[0].tag) {
                case "field":
                    return gen_go.gen_type_declaration(Struct(decl.name, decl.fields_or_variants as Field[]), "json");

                case "struct":
                    return gen_go.gen_type_declaration(StructUnion(decl.name, decl.fields_or_variants as Struct[]), "json");
            }
        case "id_type":
            return `type ${decl.name} string`;

        default:
            break;
    }

    return flatten_type_declaration(decl).map(d => gen_go.gen_type_declaration(d, "json")).join("\n\n");
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
function gen_route_function_body(route: Route, url: {str: string, arguments: string[]}): string {
    let params = [
        `fmt.Sprintf("${url.str}", ${url.arguments.join(", ")})`,
        ...route_params(route, false).map(p => p.name)
    ];
    switch (route.method) {
        case Method.Get:
            return `return utils.get(${params.join(", ")});`;
        case Method.Post:
            return `return utils.post(${params.join(", ")});`;
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
    return "error";
}

function gen_error_type(endpoint: Route): string {
    if (endpoint.error_type && endpoint.error_type.length > 0) {
        return `${gen_type_declaration_for_api_type({
            tag: "struct_union",
            name: error_type_name(endpoint),
            variants: endpoint.error_type.map((e) => e.variant),
        })}\n\n`;
    }
    return "";
}

function query_param_type_name(endpoint: Route, type_namespace?: string): string {
    if ("query_param_type" in endpoint && endpoint.query_param_type && endpoint.query_param_type.length > 0) {
        return (type_namespace || "")+to_pascal_case(endpoint.name) + "Query";
    }
    return "struct{}";
}


function input_body_type_name(endpoint: Route, type_namespace?: string): string {
    if ("input_body_type" in endpoint && endpoint.input_body_type && endpoint.input_body_type.length > 0) {
        return (type_namespace || "")+to_pascal_case(endpoint.name) + "Input";
    }
    return "struct{}";
}

function output_type_name(endpoint: Route, type_namespace?: string): string {
    if (endpoint.output_body_type && endpoint.output_body_type.length > 0) {
        return (type_namespace || "")+to_pascal_case(endpoint.name) + "Output";
    }
    return "NoOutput";
}

function gen_query_param_type(endpoint: Route): string {
    if ("query_param_type" in endpoint && endpoint.query_param_type && endpoint.query_param_type.length > 0) {
        switch (endpoint.query_param_type[0].tag) {
            case "field":
                return gen_type_declaration_for_api_type(Struct(query_param_type_name(endpoint), endpoint.query_param_type as Field[])) + "\n\n";
            case "struct":
                return gen_type_declaration_for_api_type(StructUnion(query_param_type_name(endpoint), endpoint.query_param_type as Struct[])) + "\n\n";
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
                return gen_type_declaration_for_api_type(Struct(input_body_type_name(endpoint), endpoint.input_body_type as Field[])) + "\n\n";
            case "struct":
                return gen_type_declaration_for_api_type(StructUnion(input_body_type_name(endpoint), endpoint.input_body_type as Struct[])) + "\n\n";
            case "nested_field":
                return gen_type_declaration_for_api_type(NStruct(input_body_type_name(endpoint), endpoint.input_body_type as NestedField[])) + "\n\n";
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
                return gen_type_declaration_for_api_type(Struct(output_type_name(endpoint), endpoint.output_body_type as Field[])) + "\n\n";
            case "struct":
                return gen_type_declaration_for_api_type(StructUnion(output_type_name(endpoint), endpoint.output_body_type as Struct[])) + "\n\n";
            case "nested_field":
                return gen_type_declaration_for_api_type(NStruct(output_type_name(endpoint), endpoint.output_body_type as NestedField[])) + "\n\n";
            default:
                throw "not implemented!";
        }
    }
    return "";
}

function gen_response_type(endpoint: Route): string {
    return `(result *${output_type_name(endpoint, type_namespace)}, err ${error_type_name(endpoint,type_namespace)})`;
}


function opts_decl(opts: { name: string, type: string; }[]): { name: string, type: string; } {
    return { name: "opts", type: `struct{ ${opts.map(o => `${o.name} ${o.type}`).join(", ")} }` };
}

function route_opts(route: Route): { name: string, type: string; }[] {
    let opts: { name: string, type: string; }[] = [];
    opts.push({ name: "session_token", type: "string" });

    return opts;
}

function route_params(route: Route, for_declaration: boolean): { name: string, type: string; }[] {
    let url_params = (route.url_params || []).map((p) => {
        return { name: p.name, type: gen_go.render_type(p.type, type_namespace) };
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
    let url: {
        str: string,
        arguments: string[]
     } = {
        str: route.url,
        arguments: [],
     };
    
    let args = route.url.match(/\{([a-zA-Z0-9_]+)\}/gm);
    if (args) {
        args.forEach(p => {
            url.arguments.push(p.slice(1, p.length-1));
        });
    }

    for (let a of url.arguments) {
        url.str = url.str.replace(`{${a}}`, "%s");
    }

    route.url.replace(/{/g, "${");
    let params: string[] = route_params(route, true).map(p => `${p.name} ${p.type},`);

    if (route.method == Method.Get) {
        if (route.query_param_type) {
            url.str += "%s";
            url.arguments.push("utils.stringify_query(q)");
        }
    }

    return {
        types: `// ${route.name}
${gen_query_param_type(route)}${gen_input_type(route)}${gen_output_type(route)}${gen_error_type(route)}`,
        code: `// ${route.name}
func ${to_pascal_case(route.name)} (
    ${params.join("\n    ")}
) ${gen_response_type(route)} {
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

    let client_endpoint_fns = gen_endpoints(client_routes);

    let client_go_types = `// AUTOMATICALLY GENERATED, DO NOT EDIT!!
package types

${gen_types(types.t, types.it, types.ot)}

// endpoint input/output types

${client_endpoint_fns.types}
`
    let client_endpoints_go_code = `// AUTOMATICALLY GENERATED, DO NOT EDIT!!
package endpoints

import (
    "rust-simple-chat-client-sdk/generated/types"
    "rust-simple-chat-client-sdk/utils"
    "fmt"
)

type NoOutput struct{}

${client_endpoint_fns.code}
`;

    if (!fs.existsSync(`${path}`)) fs.mkdirSync(path);
    if (!fs.existsSync(`${path}/types`)) fs.mkdirSync(`${path}/types`);
    if (!fs.existsSync(`${path}/endpoints`)) fs.mkdirSync(`${path}/endpoints`);
    fs.writeFileSync(`${path}/types/types.go`, client_go_types);
    fs.writeFileSync(`${path}/endpoints/endpoints.go`, client_endpoints_go_code)
}


export function gen() {
    gen_bindings("./../../sdks/Go/app/generated", {
        t: app.shared_types,
        it: app.input_types,
        ot: app.output_types,
    }, app_routes);

    gen_bindings("./../../sdks/Go/client/generated", {
        t: client.shared_types,
        it: client.input_types,
        ot: client.output_types,
    }, client_routes);
}
