open T

let endpoints =
  Gen_endpoints.Types.
    [
      {
        name = "conversations";
        url = "/conversations";
        docstring =
          "retrieve all conversations visible to the authenticated user";
        shape =
          Get
            {
              url_params = None;
              query_param_type =
                Fields
                  [
                    field "name" (option str);
                    field "next" (option T.conversation_cursor);
                    field "prev" (option T.conversation_cursor);
                    field "limit" (option i32);
                  ];
              output_type =
                Fields [ field "conversations" Ot.paginated_conversations ];
            };
      };
    ]
