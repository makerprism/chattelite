let t =
  Gen_types.Types.
    [
      struct_union "Test"
        [
          struct_union_variant "Success" [ field "id" (TypeLiteral Str) ];
          struct_union_variant "Error" [ field "message" (TypeLiteral Str) ];
        ];
      struct_ "NiceStruct" [ field "id" (TypeLiteral Str) ];
      string_enum "Entity" [ "Post"; "User"; "Message" ];
    ]

let it = []
let ot = []

let endpoints =
  [
    Gen_endpoints.Types.
      {
        name = "create_user";
        url = "/users";
        shape =
          Gen_endpoints.Types.Post
            {
              url_params = None;
              input_body_type = Gen_types.Types.(Fields [ field "test" (t "User")]);
              query_param_type = None;
              output_body_type = None;
              error_type = None;
            };
        server_req = false;
      };
  ]

let gen_code () =
  let bindings = Gen_endpoints.Gen_ts_bindings.gen_routes ~type_namespace:"" endpoints in
  let types_result =
    [ Gen_endpoints.Gen_ts_bindings.gen_types ~type_namespace:"" ~t ~it ~ot ]
    @ List.map Gen_types.Gen_ocaml.gen_type_declaration it
    @ ["// ENDPOINTS"; bindings]
  in
  print_endline (String.concat "\n\n" types_result)

let () = gen_code ()
