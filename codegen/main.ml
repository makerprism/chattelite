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
let user_id = Gen_types.Types.str

let endpoints =
  Gen_types.Types.(
    Gen_endpoints.Types.
      [
        {
          name = "create_user";
          url = "/users";
          docstring = "create a new user";
          shape =
            Post
              {
                url_params = None;
                input_body_type =
                  Fields [ field "display_name" str; field "user_id" user_id ];
                query_param_type = None;
                output_body_type = Fields [ field "user_id" user_id ];
                error_type = None;
              };
          server_req = false;
        };
        {
          name = "users";
          url = "/users";
          docstring = "list users";
          shape =
            Get
              {
                url_params = None;
                query_param_type = Fields [ field "name" str ];
                output_body_type = Fields [ field "users" (vec (t "User")) ];
                (*error_type = None;*)
              };
          server_req = false;
        };
        {
          name = "get_user";
          url = "/user/{user_id}";
          docstring = "get user by id";
          shape =
            Get
              {
                url_params = Some [ { name = "user_id"; t = user_id } ];
                query_param_type = None;
                output_body_type = Fields [ field "user" (t "User") ];
                (*error_type = None;*)
              };
          server_req = false;
        };
        {
          name = "delete_user";
          url = "/user/{user_id}";
          docstring = "delete user by id";
          shape =
            Delete
              {
                url_params = Some [ { name = "user_id"; t = user_id } ];
                output_body_type = None;
                error_type = None;
              };
          server_req = false;
        };
      ])

let gen_code () =
  let bindings =
    Gen_endpoints.Gen_ts_bindings.gen_routes ~type_namespace:"" endpoints
  in
  let types_result =
    [ Gen_endpoints.Gen_ts_bindings.gen_types ~type_namespace:"" ~t ~it ~ot ]
    @ List.map Gen_types.Gen_ocaml.gen_type_declaration it
    @ [ "// ENDPOINTS"; bindings ]
  in
  print_endline (String.concat "\n\n" types_result)

let () = gen_code ()
