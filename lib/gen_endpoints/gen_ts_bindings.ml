let gen_type_declaration_for_api_type ~type_namespace
    (decl : Gen_types.Types.type_declaration) =
  Gen_types.Gen_typescript.gen_type_declaration ~type_namespace decl

let gen_types ~(t : Gen_types.Types.type_declaration list)
    ~(it : Gen_types.Types.type_declaration list)
    ~(ot : Gen_types.Types.type_declaration list) ~type_namespace =
  Format.sprintf
    "// API input and output types\n\
     %s\n\n\
     // API input types\n\
     %s\n\n\
     // API output types\n\
     %s"
    (String.concat "\n\n"
       (List.map (gen_type_declaration_for_api_type ~type_namespace) t))
    (String.concat "\n\n"
       (List.map (gen_type_declaration_for_api_type ~type_namespace) it))
    (String.concat "\n\n"
       (List.map (gen_type_declaration_for_api_type ~type_namespace) ot))

(* input body type *)

let input_body_type_name ~route_name ~type_namespace =
  Format.sprintf "%sInput"
    (type_namespace ^ Gen_types.Utils.to_pascal_case route_name)

let gen_input_body_type ~route_name (route_params : Types.route_params)
    ~type_namespace =
  match route_params with
  | Fields fields ->
      gen_type_declaration_for_api_type ~type_namespace
        (Gen_types.Types.struct_
           (input_body_type_name ~type_namespace ~route_name)
           fields)
  | Structs structs ->
      gen_type_declaration_for_api_type ~type_namespace
        (Gen_types.Types.struct_union
           (input_body_type_name ~type_namespace ~route_name)
           structs)
  | None -> ""

(* query param type *)

let query_param_type_name ~route_name ~type_namespace =
  Format.sprintf "%sQuery"
    (type_namespace ^ Gen_types.Utils.to_pascal_case route_name)

let gen_route_params_type ~name (route_params : Types.route_params)
    ~type_namespace =
  match route_params with
  | Fields fields ->
      gen_type_declaration_for_api_type ~type_namespace
        (Gen_types.Types.struct_ name fields)
  | Structs structs ->
      gen_type_declaration_for_api_type ~type_namespace
        (Gen_types.Types.struct_union name structs)
  | None -> Format.sprintf "export type %s = {}" (type_namespace ^ name)

let output_type_name ~route_name ~type_namespace =
  Format.sprintf "%sOutput"
    (type_namespace ^ Gen_types.Utils.to_pascal_case route_name)

let response_type_name ~route_name ~type_namespace =
  Format.sprintf "%sResponse"
    (type_namespace ^ Gen_types.Utils.to_pascal_case route_name)

let gen_response_type ~route_name ~type_namespace =
  Format.sprintf "export type %s = utils.ApiResponse<%s, %s>;"
    (response_type_name ~route_name ~type_namespace)
    (output_type_name ~route_name ~type_namespace)
    "ResponseError"
(*(error_type_name  ~route_name ~type_namespace)*)

type route_param = { name : string; t : string }

let route_params (route : Types.route) ~type_namespace =
  let params_of_url_params (url_params : Types.url_param list option) =
    List.map
      (fun ({ name; t } : Types.url_param) ->
        { name; t = Gen_types.Gen_typescript.render_type t ~type_namespace })
      (Option.value ~default:[] url_params)
  in

  let params_of_query_param_type (query_param_type : Types.route_params) =
    match query_param_type with
    | None -> []
    | _ ->
        [
          {
            name = "q";
            t = query_param_type_name ~route_name:route.name ~type_namespace;
          };
        ]
  in
  match route.shape with
  | Get { url_params; query_param_type; _ } ->
      params_of_url_params url_params
      @ params_of_query_param_type query_param_type
  | Post { url_params; input_body_type; query_param_type; _ } ->
      params_of_url_params url_params
      @ params_of_query_param_type query_param_type
      @
      if input_body_type != None then
        [
          {
            name = "body";
            t = input_body_type_name ~route_name:route.name ~type_namespace;
          };
        ]
      else []
  | Delete { url_params; _ } -> params_of_url_params url_params

let gen_route_function_body (route : Types.route) ~type_namespace =
  let url =
    let re = Str.regexp "{" in
    Str.global_replace re "${" route.url
  in
  let url =
    match route.shape with
    | Get { query_param_type; _ } ->
        if query_param_type != None then url ^ "${utils.stringify_query(q)}"
        else url
    | Post { query_param_type; _ } ->
        if query_param_type != None then url ^ "${utils.stringify_query(q)}"
        else url
    | _ -> url
  in
  let params =
    [ Format.sprintf "`%s`" url ]
    @ List.map (fun { name; _ } -> name) (route_params route ~type_namespace)
  in
  match route.shape with
  | Get _ -> Format.sprintf "return utils.get(%s);" (String.concat ", " params)
  | Post _ ->
      Format.sprintf "return utils.post(%s);" (String.concat ", " params)
  | Delete _ ->
      Format.sprintf "return utils.del(%s);" (String.concat ", " params)

type route_result = { types : string; code : string }

let gen_route_types ~type_namespace (route : Types.route) =
  match route.shape with
  | Get s ->
      let output_t =
        gen_route_params_type
          ~name:(output_type_name ~route_name:route.name ~type_namespace)
          s.output_body_type ~type_namespace
      in
      let query_t =
        if s.query_param_type != None then
          [
            gen_route_params_type
              ~name:
                (query_param_type_name ~route_name:route.name ~type_namespace)
              s.query_param_type ~type_namespace;
          ]
        else []
      in
      query_t @ [ output_t ]
  | Post s ->
      let input_t =
        gen_route_params_type
          ~name:(input_body_type_name ~route_name:route.name ~type_namespace)
          s.input_body_type ~type_namespace
      in
      let output_t =
        gen_route_params_type
          ~name:(output_type_name ~route_name:route.name ~type_namespace)
          s.output_body_type ~type_namespace
      in
      [ input_t; output_t ]
  | Delete s ->
      let output_t =
        gen_route_params_type
          ~name:(output_type_name ~route_name:route.name ~type_namespace)
          s.output_body_type ~type_namespace
      in
      [ output_t ]

let gen_route ~type_namespace (route : Types.route) =
  let params =
    List.map
      (fun { name; t } -> Format.sprintf "%s: %s" name t)
      (route_params route ~type_namespace)
  in

  let types =
    gen_route_types route ~type_namespace
    @ [ gen_response_type ~route_name:route.name ~type_namespace ]
  in
  let code =
    Format.sprintf "export function %s (%s): Promise<%s> { %s }" route.name
      (String.concat ",\n    " params)
      (response_type_name ~route_name:route.name ~type_namespace)
      (gen_route_function_body route ~type_namespace)
  in

  String.concat "\n" types ^ "\n" ^ code

let gen_routes ~type_namespace (routes : Types.route list) =
  let endpoints = List.map (gen_route ~type_namespace) routes in

  String.concat "\n\n" endpoints
