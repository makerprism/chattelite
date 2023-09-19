open Lwt.Syntax

module User = struct
  type t = { user_id : string; display_name : string } [@@deriving yojson]

  let make ~user_id ~display_name = { user_id; display_name }
end

module PaginatedUsers = Pagination.Make (User)

let users req =
  let next = Dream.query req "next" in
  let prev = Dream.query req "prev" in
  let limit =
    Option.value ~default:20
      (Option.map int_of_string (Dream.query req "limit"))
  in

  let* users_or_error = Dream.sql req (Db.User.get_many ~next ~prev ~limit) in
  let* users, next, prev = Caqti_lwt.or_fail users_or_error in
  let objs : PaginatedUsers.obj list =
    users
    |> List.map (fun Db.User.{ id = _; public_facing_id; display_name } ->
           User.make ~user_id:public_facing_id ~display_name)
  in

  PaginatedUsers.yojson_of_t (PaginatedUsers.create ~next ~prev ~objs)
  |> Yojson.Safe.to_string |> Dream.json

module CreateUser = struct
  type t = { user_id : string; display_name : string } [@@deriving yojson]
end

let create_user req =
  let* body = Dream.body req in
  let create_user = body |> Yojson.Safe.from_string |> CreateUser.t_of_yojson in
  let* user_or_error =
    Dream.sql req
      (Db.User.insert ~public_facing_id:create_user.user_id
         ~display_name:create_user.display_name)
  in
  let* _user = Caqti_lwt.or_fail user_or_error in
  Dream.json "ok"
