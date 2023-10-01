(* TODO: NONE OF THIS WORKS BECAUSE the yojson pxx does not generate the same structure as Rust's serde did*)

(* names of generated types *)

let input_type_name ~route_name =
  Format.sprintf "%sInput" (Gen_types.Utils.to_pascal_case route_name)

let query_param_type_name ~route_name =
  Format.sprintf "%sQuery" (Gen_types.Utils.to_pascal_case route_name)

let output_type_name ~route_name =
  Format.sprintf "%sOutput" (Gen_types.Utils.to_pascal_case route_name)

let response_type_name ~route_name =
  Format.sprintf "%sResponse" (Gen_types.Utils.to_pascal_case route_name)

module Api_types = struct
  let gen_type_declaration_for_api_type ~type_namespace
      (decl : Types.type_declaration) =
    match decl with
    | BasicTypeDecl decl ->
        Gen_types.Gen_typescript.gen_type_declaration ~type_namespace decl
    | IdType name ->
        Gen_types.(
          Gen_typescript.gen_type_declaration ~type_namespace
            Types.(alias (t name) str))
    | CursorType name ->
        Gen_types.(
          Gen_typescript.gen_type_declaration ~type_namespace
            Types.(alias (t name) str))

  let gen_types ~(t : Types.type_declaration list)
      ~(it : Types.type_declaration list) ~(ot : Types.type_declaration list)
      ~type_namespace =
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
end

let gen_types = Api_types.gen_types

module Route_types = struct
  let gen_input_type ~route_name (route_params : Types.route_params)
      ~type_namespace =
    match route_params with
    | Fields fields ->
        Api_types.gen_type_declaration_for_api_type ~type_namespace
          (Types.struct_ (input_type_name ~route_name) fields)
    | Structs structs ->
        Api_types.gen_type_declaration_for_api_type ~type_namespace
          (Types.struct_union (input_type_name ~route_name) structs)
    | None -> ""

  let gen_route_params_type ~name (route_params : Types.route_params)
      ~type_namespace =
    match route_params with
    | Fields fields ->
        Api_types.gen_type_declaration_for_api_type ~type_namespace
          (Types.struct_ name fields)
    | Structs structs ->
        Api_types.gen_type_declaration_for_api_type ~type_namespace
          (Types.struct_union name structs)
    | None -> Format.sprintf "export type %s = {}" name

  let gen_response_type ~route_name =
    Format.sprintf "export type %s = utils.ApiResponse<%s, %s>;"
      (response_type_name ~route_name)
      (output_type_name ~route_name)
      "ResponseError"

  let gen_route_types ~type_namespace (route : Types.route) =
    match route.shape with
    | Get s ->
        let output_t =
          gen_route_params_type
            ~name:(output_type_name ~route_name:route.name)
            s.output_type ~type_namespace
        in
        let query_t =
          if s.query_param_type != None then
            [
              gen_route_params_type
                ~name:(query_param_type_name ~route_name:route.name)
                s.query_param_type ~type_namespace;
            ]
          else []
        in
        query_t @ [ output_t ]
    | Post s ->
        let input_t =
          gen_route_params_type
            ~name:(input_type_name ~route_name:route.name)
            s.input_type ~type_namespace
        in
        let output_t =
          gen_route_params_type
            ~name:(output_type_name ~route_name:route.name)
            s.output_type ~type_namespace
        in
        [ input_t; output_t ]
    | Delete s ->
        let output_t =
          gen_route_params_type
            ~name:(output_type_name ~route_name:route.name)
            s.output_type ~type_namespace
        in
        [ output_t ]
end

module Route_code = struct
  type route_param = { name : string; t : string }

  let signature_route_params (route : Types.route) ~type_namespace =
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
              t = type_namespace ^ query_param_type_name ~route_name:route.name;
            };
          ]
    in
    match route.shape with
    | Get { url_params; query_param_type; _ } ->
        params_of_url_params url_params
        @ params_of_query_param_type query_param_type
    | Post { url_params; input_type; query_param_type; _ } ->
        params_of_url_params url_params
        @ params_of_query_param_type query_param_type
        @
        if input_type != None then
          [
            {
              name = "body";
              t = type_namespace ^ input_type_name ~route_name:route.name;
            };
          ]
        else []
    | Delete { url_params; _ } -> params_of_url_params url_params

  let utils_call_route_params (route : Types.route) =
    match route.shape with
    | Get _ -> []
    | Post { input_type; _ } -> if input_type != None then [ "body" ] else []
    | Delete _ -> []

  let gen_route_function_body (route : Types.route) =
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
      [ Format.sprintf "`%s`" url ] @ utils_call_route_params route
    in
    match route.shape with
    | Get _ ->
        Format.sprintf "return utils.get(%s);" (String.concat ", " params)
    | Post _ ->
        Format.sprintf "return utils.post(%s);" (String.concat ", " params)
    | Delete _ ->
        Format.sprintf "return utils.del(%s);" (String.concat ", " params)
end

type gen_route_result = { types : string list; code : string }

let gen_route ~type_namespace (route : Types.route) =
  let types =
    Route_types.gen_route_types route ~type_namespace
    @ [ Route_types.gen_response_type ~route_name:route.name ]
  in

  let params =
    List.map
      (fun Route_code.{ name; t } -> Format.sprintf "%s: %s" name t)
      (Route_code.signature_route_params route ~type_namespace)
  in
  let code =
    Format.sprintf "export function %s (%s): Promise<%s> { %s }" route.name
      (String.concat ",\n    " params)
      (type_namespace ^ response_type_name ~route_name:route.name)
      (Route_code.gen_route_function_body route)
  in

  { types; code }

let gen_routes ~type_namespace (routes : Types.route list) =
  let result =
    List.fold_left
      (fun { types; code } route ->
        let result = gen_route ~type_namespace route in
        {
          types = List.concat [ types; result.types ];
          code = code ^ "\n\n" ^ result.code;
        })
      { types = []; code = "" } routes
  in
  result
