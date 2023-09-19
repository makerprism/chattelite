open Lwt.Syntax

let create_user req ({ user_id; display_name } : Api_types.CreateUserInput.t) =
  let* user_or_error =
    Dream.sql req (Db.User.insert ~public_facing_id:user_id ~display_name)
  in
  let* () = Caqti_lwt.or_fail user_or_error in
  Lwt.return Api_types.CreateUserOutput.{ user_id }

let get_user _req _user_id =
  Lwt.return
    Api_types.GetUserOutput.
      { user = { display_name = "TODO"; user_id = "TODO" } }

let users req (query : Api_types.UsersQuery.t) =
  let* users_or_error =
    Dream.sql req
      (Db.User.get_many ~next:query.next ~prev:query.prev
         ~limit:(Option.value ~default:20 query.limit))
  in
  let* users, next, prev = Caqti_lwt.or_fail users_or_error in
  let objs : Api_types.User.t list =
    users
    |> List.map (fun Db.User.{ id = _; public_facing_id; display_name } ->
           Api_types.User.{ user_id = public_facing_id; display_name })
  in
  Lwt.return Api_types.UsersOutput.{ users = { objs; next; prev } }
(*  PaginatedUsers.create ~next ~prev ~objs*)

let delete_user _req _user_id = Lwt.return ()
