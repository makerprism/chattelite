let gen_type_declaration_for_api_type ~type_namespace
    (decl : Gen_types.Types.type_declaration) =
  Gen_types.Gen_ocaml.gen_type_declaration ~type_namespace decl

(* input body type *)

let input_body_type_name ~route_name ~type_namespace =
  Format.sprintf "%sInput"
    (type_namespace ^ Gen_types.Utils.to_pascal_case route_name)

let gen_input_body_type ~route_name (route_params : Types.route_params)
    ~type_namespace =
  match route_params with
  | Fields fields ->
      gen_type_declaration_for_api_type ~type_namespace ~ppxes:[ "yojson" ]
        (Gen_types.Types.struct_
           (input_body_type_name ~type_namespace ~route_name)
           fields)
  | Structs structs ->
      gen_type_declaration_for_api_type ~type_namespace ~ppxes:[ "yojson" ]
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
      gen_type_declaration_for_api_type ~type_namespace ~ppxes:[ "yojson" ]
        (Gen_types.Types.struct_ name fields)
  | Structs structs ->
      gen_type_declaration_for_api_type ~type_namespace ~ppxes:[ "yojson" ]
        (Gen_types.Types.struct_union name structs)
  | None -> gen_type_declaration_for_api_type ~type_namespace ~ppxes:[ "yojson"]
    Gen_types.Types.(alias (t name) unit)

let output_type_name ~route_name ~type_namespace =
  Format.sprintf "%sOutput"
    (type_namespace ^ Gen_types.Utils.to_pascal_case route_name)

let response_type_name ~route_name ~type_namespace =
  Format.sprintf "%sResponse"
    (type_namespace ^ Gen_types.Utils.to_pascal_case route_name)

type route_param = { name : string; t : string }

let route_params = [ { name = "req"; t = "Dream.request" } ]

let handler_params (route : Types.route) ~type_namespace =
  let params_of_url_params (url_params : Types.url_param list option) =
    List.map
      (fun ({ name; t } : Types.url_param) ->
        { name; t = Gen_types.Gen_ocaml.render_type t ~type_namespace })
      (Option.value ~default:[] url_params)
  in

  let params_of_query_param_type (query_param_type : Types.route_params) =
    match query_param_type with
    | None -> []
    | _ ->
        [
          {
            name = "query";
            t = query_param_type_name ~route_name:route.name ~type_namespace;
          };
        ]
  in
  match route.shape with
  | Get { url_params; query_param_type; _ } ->
      ({ name = "req"; t = "Dream.request" } :: params_of_url_params url_params)
      @ params_of_query_param_type query_param_type
  | Post { url_params; input_body_type; query_param_type; _ } ->
      ({ name = "req"; t = "Dream.request" } :: params_of_url_params url_params)
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
  | Delete { url_params; _ } ->
      { name = "req"; t = "Dream.request" } :: params_of_url_params url_params

let gen_endpoint_function_body (route : Types.route) ~type_namespace =
  let gen_deserialize_query (query_param_type : Types.route_params) =
    let read_query_fields name t =
      match t with
      | Gen_types.Types.Option (TypeLiteral Str) ->
          Format.sprintf "let %s = Dream.query req \"%s\" in" name name
      | TypeLiteral Str ->
          Format.sprintf "let %s = Dream.query req \"%s\" |> Option.get in" name
            name
      | Option (TypeLiteral I32) ->
          Format.sprintf
            "let %s = try Dream.query req \"%s\" |> Option.map int_of_string \
             with _ -> raise (FailedToParseQuery \"%s\") in"
            name name name
      | TypeLiteral I32 ->
          Format.sprintf
            "let %s = try Dream.query req \"%s\" |> Option.get |> int_of_string with _ -> raise (FailedToParseQuery \"%s\")"
            name name name
      | _ -> failwith "not_implemented"
    in
    match query_param_type with
    | None -> []
    | Fields fs ->
        [
          Format.sprintf "let query =\n    %s\n    %s.{ %s }\n  in"
            (String.concat "\n    "
               (List.map
                  (fun (f : Gen_types.Types.field) ->
                    read_query_fields f.field_name f.field_t)
                  fs))
            (query_param_type_name ~route_name:route.name ~type_namespace)
            (String.concat "; "
               (List.map (fun (f : Gen_types.Types.field) -> f.field_name) fs));
        ]
    | Structs _ -> failwith "not_implemented"
  in
  let params_of_url_params (url_params : Types.url_param list option) =
    List.map
      (fun ({ name; _ } : Types.url_param) ->
        Format.sprintf "let %s = Dream.param req \"%s\" in" name name)
      (Option.value ~default:[] url_params)
  in
  let params =
    List.map (fun { name; _ } -> name) (handler_params route ~type_namespace)
  in
  let body =
    match route.shape with
    | Get { query_param_type; url_params; _ } ->
        gen_deserialize_query query_param_type @ params_of_url_params url_params
    | Post { query_param_type; url_params; input_body_type; _ } ->
        gen_deserialize_query query_param_type
        @ params_of_url_params url_params
        @
        if input_body_type != None then
          [
            "let* body = Dream.body req in";
            Format.sprintf
              "let body = %s.t_of_yojson (Yojson.Safe.from_string body) in"
              (input_body_type_name ~route_name:route.name ~type_namespace);
          ]
        else []
    | Delete { url_params; _ } -> params_of_url_params url_params
  in
  String.concat "\n  "
    (body
    @ [
        Format.sprintf "let* result : %s.t = Handler.%s %s in\n  result |> %s.yojson_of_t |> Yojson.Safe.to_string |> Dream.json"
          (output_type_name ~route_name:route.name ~type_namespace)
           route.name
          (String.concat " " params)
          (output_type_name ~route_name:route.name ~type_namespace);
      ])

type route_result = { types : string; code : string }

let url_of_route (route : Types.route) =
  let re = Str.regexp "{" in
  let re2 = Str.regexp "}" in
  Str.global_replace re2 "" (Str.global_replace re ":" route.url)

let gen_route_types ~type_namespace (route : Types.route) =
  match route.shape with
  | Get s ->
      let query_t =
        gen_route_params_type
          ~name:(query_param_type_name ~route_name:route.name ~type_namespace)
          s.query_param_type ~type_namespace
      in
      let output_t =
        gen_route_params_type
          ~name:(output_type_name ~route_name:route.name ~type_namespace)
          s.output_body_type ~type_namespace
      in
      [ query_t; output_t ]
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
    List.map (fun { name; t } -> Format.sprintf "(%s: %s)" name t) route_params
  in

  let code =
    Format.sprintf "let %s %s =\n  %s" route.name (String.concat " " params)
      (gen_endpoint_function_body route ~type_namespace)
  in

  code

let gen_route_declaration (route : Types.route) =
  match route.shape with
  | Get _ ->
      Format.sprintf "Dream.get \"%s\" %s" (url_of_route route) route.name
  | Post _ ->
      Format.sprintf "Dream.post \"%s\" %s" (url_of_route route) route.name
  | Delete _ ->
      Format.sprintf "Dream.delete \"%s\" %s" (url_of_route route) route.name

let gen_routes ~type_namespace (routes : Types.route list) =
  let endpoints = List.map (gen_route ~type_namespace) routes in

  let route_declarations =
    Format.sprintf "let routes = [\n  %s\n]"
      (String.concat ";\n  " (List.map gen_route_declaration routes))
  in

  String.concat "\n\n"
    ([ "open Lwt.Syntax" ]
    @ [ "exception FailedToParseQuery of string" ]
    @ endpoints @ [ route_declarations ])

let gen_types ~(t : Gen_types.Types.type_declaration list)
    ~(it : Gen_types.Types.type_declaration list)
    ~(ot : Gen_types.Types.type_declaration list) ~type_namespace
    (routes : Types.route list) =
  Format.sprintf
    "(* API input and output types *)\n\
     %s\n\n\
     (* API input types *)\n\
     %s\n\n\
     (* API output types *)\n\
     %s(* endpoint types *)\n\
     %s"
    (String.concat "\n\n"
       (List.map
          (gen_type_declaration_for_api_type ~type_namespace ~ppxes:[ "yojson" ])
          t))
    (String.concat "\n\n"
       (List.map
          (gen_type_declaration_for_api_type ~type_namespace ~ppxes:[ "yojson" ])
          it))
    (String.concat "\n\n"
       (List.map
          (gen_type_declaration_for_api_type ~type_namespace ~ppxes:[ "yojson" ])
          ot))
    (String.concat "\n\n"
       (List.flatten (List.map (gen_route_types ~type_namespace) routes)))