let gen_type_declaration_for_api_type ~type_namespace ~ppxes
    (decl : Types.type_declaration) =
  match decl with
  | BasicTypeDecl decl ->
      Gen_types.Gen_ocaml.gen_type_declaration ~type_namespace decl ~ppxes
  | IdType name ->
      Format.sprintf
        "module %s = struct\n  type t = string [@@@@deriving yojson]\n\nend"
        (Gen_types.Utils.to_pascal_case name)
  | CursorType name ->
      Format.sprintf
        "module %s = struct\n\
         type t = int64\n\n\
         let string_of_t = Int64.to_string\n\n\
         let t_of_string = Int64.of_string\n\n\
         let yojson_of_t v = `String (string_of_t v)\n\n\
        \ \n\
        \          let t_of_yojson v = match v with\n\
         | `String s -> t_of_string s\n\
         | _ -> raise (Invalid_argument \"Could not parse cursor value\") \n\n\
         end"
        (Gen_types.Utils.to_pascal_case name)

(* input body type *)

let input_type_name ~route_name ~type_namespace =
  Format.sprintf "%sInput"
    (type_namespace ^ Gen_types.Utils.to_pascal_case route_name)

let gen_input_type ~route_name (route_params : Types.route_params)
    ~type_namespace =
  match route_params with
  | Fields fields ->
      gen_type_declaration_for_api_type ~type_namespace ~ppxes:[ "yojson" ]
        (Types.struct_ (input_type_name ~type_namespace ~route_name) fields)
  | Structs structs ->
      gen_type_declaration_for_api_type ~type_namespace ~ppxes:[ "yojson" ]
        (Types.struct_union
           (input_type_name ~type_namespace ~route_name)
           structs)
  | None -> ""

(* query param type *)

let query_param_type_name ~route_name ~type_namespace =
  Format.sprintf "%sQuery"
    (type_namespace ^ Gen_types.Utils.to_pascal_case route_name)

let gen_route_params_type ~name (route_params : Types.route_params)
    ~type_namespace ~ppxes =
  match route_params with
  | Fields fields ->
      gen_type_declaration_for_api_type ~type_namespace ~ppxes
        (Types.struct_ name fields)
  | Structs structs ->
      gen_type_declaration_for_api_type ~type_namespace ~ppxes
        (Types.struct_union name structs)
  | None ->
      gen_type_declaration_for_api_type ~type_namespace ~ppxes
        Types.(alias (t name) unit)

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
  | Post { url_params; input_type; query_param_type; _ } ->
      ({ name = "req"; t = "Dream.request" } :: params_of_url_params url_params)
      @ params_of_query_param_type query_param_type
      @
      if input_type != None then
        [
          {
            name = "body";
            t = input_type_name ~route_name:route.name ~type_namespace;
          };
        ]
      else []
  | Delete { url_params; _ } ->
      { name = "req"; t = "Dream.request" } :: params_of_url_params url_params

let gen_endpoint_function_body (route : Types.route) ~type_namespace
    ~handler_namespace =
  let gen_deserialize_query (query_param_type : Types.route_params) =
    match query_param_type with
    | None -> []
    | Fields _ ->
        [
          Format.sprintf
            "match %s.parse_query req with\n\
            \  | Error msg -> %sbad_request msg\n\
            \  | Ok query -> \n"
            (query_param_type_name ~route_name:route.name ~type_namespace)
            handler_namespace;
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
    | Post { query_param_type; url_params; input_type; _ } ->
        gen_deserialize_query query_param_type
        @ params_of_url_params url_params
        @
        if input_type != None then
          [
            "let* body = Dream.body req in";
            Format.sprintf
              "let body = %s.t_of_yojson (Yojson.Safe.from_string body) in"
              (input_type_name ~route_name:route.name ~type_namespace);
          ]
        else []
    | Delete { url_params; _ } -> params_of_url_params url_params
  in
  String.concat "\n  "
    (body
    @ [
        Format.sprintf
          "let* result : (%s.t, Dream.response Lwt.t) result = %s%s %s in\n\
          \  match result with\n\
          \    | Ok result -> result |> %s.yojson_of_t |> \
           Yojson.Safe.to_string |> Dream.json\n\
          \    | Error response -> response"
          (output_type_name ~route_name:route.name ~type_namespace)
          handler_namespace route.name (String.concat " " params)
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
        if s.query_param_type != None then
          gen_route_params_type
            ~name:(query_param_type_name ~route_name:route.name ~type_namespace)
            s.query_param_type ~type_namespace ~ppxes:[ "yojson"; "query" ]
        else ""
      in
      let output_t =
        gen_route_params_type
          ~name:(output_type_name ~route_name:route.name ~type_namespace)
          s.output_type ~type_namespace ~ppxes:[ "yojson" ]
      in
      [ query_t; output_t ]
  | Post s ->
      let input_t =
        gen_route_params_type
          ~name:(input_type_name ~route_name:route.name ~type_namespace)
          s.input_type ~type_namespace ~ppxes:[ "yojson" ]
      in
      let output_t =
        gen_route_params_type
          ~name:(output_type_name ~route_name:route.name ~type_namespace)
          s.output_type ~type_namespace ~ppxes:[ "yojson" ]
      in
      [ input_t; output_t ]
  | Delete s ->
      let output_t =
        gen_route_params_type
          ~name:(output_type_name ~route_name:route.name ~type_namespace)
          s.output_type ~type_namespace ~ppxes:[ "yojson" ]
      in
      [ output_t ]

let gen_route ~type_namespace ~handler_namespace (route : Types.route) =
  let params =
    List.map (fun { name; t } -> Format.sprintf "(%s: %s)" name t) route_params
  in
  let code =
    Format.sprintf "let %s %s =\n  %s" route.name (String.concat " " params)
      (gen_endpoint_function_body route ~type_namespace ~handler_namespace)
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

let gen_routes ~type_namespace ~handler_namespace (routes : Types.route list) =
  let endpoints =
    List.map (gen_route ~type_namespace ~handler_namespace) routes
  in

  let route_declarations =
    Format.sprintf "let routes = [\n  %s\n]"
      (String.concat ";\n  " (List.map gen_route_declaration routes))
  in

  String.concat "\n\n"
    ([ "open Lwt.Syntax" ] @ endpoints @ [ route_declarations ])

let gen_types ~(t : Types.type_declaration list)
    ~(it : Types.type_declaration list) ~(ot : Types.type_declaration list)
    ~type_namespace (routes : Types.route list) =
  let gen_declarations ~ppxes =
    List.map (gen_type_declaration_for_api_type ~type_namespace ~ppxes)
  in
  Format.sprintf
    "(* API input and output types *)\n\
     %s\n\n\
     (* API input types *)\n\
     %s\n\n\
     (* API output types *)\n\
     %s\n\n\
     (* endpoint types *)\n\
     %s"
    (String.concat "\n\n" (gen_declarations ~ppxes:[ "yojson" ] t))
    (String.concat "\n\n" (gen_declarations ~ppxes:[ "yojson" ] it))
    (String.concat "\n\n" (gen_declarations ~ppxes:[ "yojson" ] ot))
    (String.concat "\n\n"
       (List.flatten (List.map (gen_route_types ~type_namespace) routes)))
