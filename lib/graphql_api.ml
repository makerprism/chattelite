type resolve_info_t = Context.t Graphql_lwt.Schema.resolve_info

module User = struct
  type t = { user_id : string; display_name : string }

  let make ~user_id ~display_name = { user_id; display_name }

  let schema =
    Graphql_lwt.Schema.(
      obj "user"
        ~fields:
          [
            field "display_name" ~typ:(non_null string)
              ~args:Arg.[]
              ~resolve:(fun _info user -> user.display_name);
            field "user_id" ~typ:(non_null string)
              ~args:Arg.[]
              ~resolve:(fun _info user -> user.user_id);
          ])
end

module PaginatedUsers = Pagination.Make (User)

let schema : Context.t Graphql_lwt.Schema.schema =
  let open Lwt.Syntax in
  Graphql_lwt.Schema.(
    schema
      ~mutations:
        [
          io_field "add_user" ~typ:(non_null string)
            ~args:
              Arg.
                [
                  arg "user_id" ~typ:(non_null string);
                  arg "display_name" ~typ:(non_null string);
                ]
            ~resolve:(fun (info : resolve_info_t) () user_id display_name ->
              let* unit_or_error =
                Dream.sql info.ctx.request
                  (Db.User.insert ~display_name ~public_facing_id:user_id)
              in
              let* _ = Caqti_lwt.or_fail unit_or_error in
              Lwt.return @@ Ok "");
        ]
      [
        io_field "users" ~doc:"All publicly-visible users"
          ~typ:(non_null (PaginatedUsers.schema "paginated_users"))
          ~args:
            Arg.
              [
                arg "cursor" ~typ:string;
                arg' "limit" ~typ:int ~default:(`Int 10);
              ]
          ~resolve:(fun (info : resolve_info_t) () cursor limit ->
            let* users_or_error =
              Dream.sql info.ctx.request (Db.User.get_many ~cursor ~limit)
            in
            let* users, next, prev = Caqti_lwt.or_fail users_or_error in
            let objs : PaginatedUsers.obj list =
              users
              |> List.map
                   (fun Db.User.{ id = _; public_facing_id; display_name } ->
                     User.make ~user_id:public_facing_id ~display_name)
            in
            Lwt.return @@ Ok (PaginatedUsers.create ~next ~prev ~objs));
        io_field "user" ~doc:"Get information about a specific user"
          ~typ:(non_null User.schema)
          ~args:Arg.[ arg "user_id" ~typ:(non_null string) ]
          ~resolve:(fun info () user_id ->
            let* user_or_error =
              Dream.sql info.ctx.request
                (Db.User.get_one ~public_facing_id:user_id)
            in
            let* user = Caqti_lwt.or_fail user_or_error in
            Lwt.return
              (Ok
                 ( user |> fun { id = _; public_facing_id; display_name } ->
                   User.make ~user_id:public_facing_id ~display_name )));
      ])

let default_query = "{\\n  users {\\n    name\\n    id\\n  }\\n}\\n"

let routes =
  [
    Dream.any "/graphql"
      (Dream.graphql (fun request -> Lwt.return Context.{ request }) schema);
    Dream.get "/graphiql" (Dream.graphiql ~default_query "/graphql");
  ]
