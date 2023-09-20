let render_type (t : Gen_types.Types.t) =
  Gen_types.Gen_documentation.render_type t ~type_namespace:""

let gen_endpoint_doc (route : Types.route) =
  let meth, url_params, query_params, input_type, output_type, _error_type =
    match route.shape with
    | Get { url_params; query_param_type; output_type } ->
        ("GET", url_params, query_param_type, Types.None, output_type, None)
    | Post { url_params; query_param_type; input_type; output_type; error_type }
      ->
        ( "POST",
          url_params,
          query_param_type,
          input_type,
          output_type,
          error_type )
    | Delete { url_params; output_type; error_type } ->
        ("DELETE", url_params, Types.None, Types.None, output_type, error_type)
  in
  let url_params =
    match url_params with
    | None -> []
    | Some fs ->
        [
          "URL params:\n  "
          ^ String.concat "\n  "
              ([ "|name|type|"; "|-|-|" ]
              @ List.map
                  (fun (p : Types.url_param) ->
                    Format.sprintf "|%s|%s|" p.name (render_type p.t))
                  fs);
        ]
  in
  let query_params =
    match query_params with
    | None -> []
    | Fields fs ->
        [
          "Query Parameters:\n  "
          ^ String.concat "\n  "
              ([ "|name|type|"; "|-|-|" ]
              @ List.map
                  (fun (p : Gen_types.Types.field) ->
                    Format.sprintf "|%s|%s|" p.field_name
                      (render_type p.field_t))
                  fs);
        ]
    | _ -> failwith "not implemented"
  in
  let input_type =
    match input_type with
    | None -> []
    | Fields fs ->
        [
          "Input body:\n  "
          ^ String.concat "\n  "
              ([ "|name|type|"; "|-|-|" ]
              @ List.map
                  (fun (p : Gen_types.Types.field) ->
                    Format.sprintf "|%s|%s|" p.field_name
                      (render_type p.field_t))
                  fs);
        ]
    | Structs _ -> failwith "not implemented"
  in

  let output_type =
    match output_type with
    | None -> []
    | Fields fs ->
        [
          "Response body:\n  "
          ^ String.concat "\n  "
              ([ "|name|type|"; "|-|-|" ]
              @ List.map
                  (fun (p : Gen_types.Types.field) ->
                    Format.sprintf "|%s|%s|" p.field_name
                      (render_type p.field_t))
                  fs);
        ]
    | Structs _ -> failwith "not implemented"
  in
  let docs = url_params @ query_params @ input_type @ output_type in

  Format.sprintf "## %s\n\n%s\n\n%s %s\n\n%s"
    (Gen_types.Gen_documentation.linkable_anchor route.name)
    route.docstring meth route.url
    (String.concat "\n\n" docs)

let gen_type_documentation (t : Types.type_declaration) ~type_namespace =
  match t with
  | BasicTypeDecl t ->
      Gen_types.Gen_documentation.gen_type_documentation ~type_namespace t
  | IdType name ->
      Format.sprintf "## %s\n\nis an ID type (String)"
        (Gen_types.Utils.to_pascal_case name)
  | CursorType name ->
      Format.sprintf "## %s\n\nis a Cursor type (Integer)"
        (Gen_types.Utils.to_pascal_case name)

let gen_docs ~t ~it ~ot (routes : Types.route list) =
  String.concat "\n\n"
    ([ "# Types" ]
    @ List.map (gen_type_documentation ~type_namespace:"") t
    @ List.map (gen_type_documentation ~type_namespace:"") it
    @ List.map (gen_type_documentation ~type_namespace:"") ot
    @ [ "# Endpoints" ]
    @ List.map gen_endpoint_doc routes)
