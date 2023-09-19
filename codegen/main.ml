let paginate name obj_t =
  Gen_types.Types.(
    struct_ (u name)
      [
        field "next" (option str);
        field "prev" (option str);
        field "objs" (vec obj_t);
      ])

let t =
  Gen_types.Types.
    [
      alias T.user_id str;
      struct_ (u T.user) [ field "display_name" str; field "user_id" T.user_id ];
      paginate T.paginated_users T.user;
    ]

let it = []
let ot = []

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
                  Fields [ field "display_name" str; field "user_id" T.user_id ];
                query_param_type = None;
                output_body_type = Fields [ field "user_id" T.user_id ];
                error_type = None;
              };
        };
        {
          name = "users";
          url = "/users";
          docstring = "list users";
          shape =
            Get
              {
                url_params = None;
                query_param_type =
                  Fields
                    [
                      field "name" (option str);
                      field "next" (option str);
                      field "prev" (option str);
                      field "limit" (option i32);
                    ];
                output_body_type = Fields [ field "users" T.paginated_users ];
                (*error_type = None;*)
              };
        };
        {
          name = "get_user";
          url = "/user/{user_id}";
          docstring = "get user by id";
          shape =
            Get
              {
                url_params = Some [ { name = "user_id"; t = T.user_id } ];
                query_param_type = None;
                output_body_type = Fields [ field "user" T.user ];
                (*error_type = None;*)
              };
        };
        {
          name = "delete_user";
          url = "/user/{user_id}";
          docstring = "delete user by id";
          shape =
            Delete
              {
                url_params = Some [ { name = "user_id"; t = T.user_id } ];
                output_body_type = None;
                error_type = None;
              };
        };
      ])

let gen_code () =
  let ts_bindings =
    Gen_endpoints.Gen_ts_bindings.gen_routes ~type_namespace:"" endpoints
  in
  let ts_types_result =
    [ Gen_endpoints.Gen_ts_bindings.gen_types ~type_namespace:"" ~t ~it ~ot ]
    @ [ "// ENDPOINTS"; ts_bindings ]
  in
  let ocaml_types =
    Gen_endpoints.Gen_ocaml_endpoints.gen_types ~type_namespace:"" ~t ~it ~ot
      endpoints
  in
  let ocaml_endpoints =
    Gen_endpoints.Gen_ocaml_endpoints.gen_routes ~type_namespace:"Api_types."
      ~handler_namespace:"Handler." endpoints
  in
  let oc = open_out "frontend/generated_types.ts" in
  Printf.fprintf oc "%s\n" (String.concat "\n\n" ts_types_result);
  close_out oc;

  let oc = open_out "lib/api/generated_endpoints.ml" in
  Printf.fprintf oc "%s" ocaml_endpoints;
  close_out oc;

  let oc = open_out "lib/api/api_types.ml" in
  Printf.fprintf oc "%s" ocaml_types;
  close_out oc

let () = gen_code ()
