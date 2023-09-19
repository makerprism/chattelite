open T

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
      alias T.conversation_id str;
      alias T.line_id str;
      alias T.date_time str;
    ]

let it = []

let ot =
  Gen_types.Types.
    [
      struct_ (u Ot.user)
        [ field "display_name" str; field "user_id" T.user_id ];
      paginate Ot.paginated_users Ot.user;
      struct_ (u Ot.parent_line)
        [
          field "line_id" T.line_id;
          field "timestamp" T.date_time;
          field "from" Ot.user;
          field "message" str;
          field "data" str;
          (* JSON *)
        ];
      struct_ (u Ot.line)
        [
          field "line_id" T.line_id;
          field "timestamp" T.date_time;
          field "from" Ot.user;
          field "message" str;
          field "data" str;
          (* JSON *)
          field "reply_to_line" (nullable T.line_id);
        ];
      struct_ (u Ot.thread)
        [ field "line" Ot.line; field "replies" (vec Ot.line) ];
      struct_union (u Ot.conversation_event)
        [
          struct_union_variant "NewLine" [ field "line" Ot.line ];
          struct_union_variant "Join"
            [ field "timestamp" T.date_time; field "from" Ot.user ];
          struct_union_variant "Leave"
            [ field "timestamp" T.date_time; field "from" Ot.user ];
          struct_union_variant "StartTyping"
            [ field "timestamp" T.date_time; field "from" Ot.user ];
          struct_union_variant "EndTyping"
            [ field "timestamp" T.date_time; field "from" Ot.user ];
        ];
      struct_ (u Ot.conversation)
        [
          field "conversation_id" T.conversation_id;
          field "timestamp" T.date_time;
          field "number_of_unread_messages" i32;
          field "newest_line" (nullable Ot.line);
        ];
      paginate Ot.paginated_conversations Ot.conversation;
    ]
