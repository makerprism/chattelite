open T

let endpoints =
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
              input_type =
                Fields [ field "display_name" str; field "user_id" T.user_id ];
              query_param_type = None;
              output_type = Fields [ field "user_id" T.user_id ];
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
                    field "next" (option T.user_cursor);
                    field "prev" (option T.user_cursor);
                    field "limit" (option i32);
                  ];
              output_type = Fields [ field "users" Ot.paginated_users ];
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
              output_type = Fields [ field "user" Ot.user ];
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
              output_type = None;
              error_type = None;
            };
      };
    ]
