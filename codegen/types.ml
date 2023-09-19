let paginate name obj_t =
  Gen_types.Types.(
    struct_ (u name)
      [
        field "next" (option str);
        field "prev" (option str);
        field "objs" (vec obj_t);
      ])

let t = Gen_types.Types.[ alias T.user_id str ]
let it = []

let ot =
  Gen_types.Types.
    [
      struct_ (u T.user) [ field "display_name" str; field "user_id" T.user_id ];
      paginate T.paginated_users T.user;
    ]
