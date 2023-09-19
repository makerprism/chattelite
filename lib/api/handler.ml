open Lwt.Syntax

let create_user req ({ user_id; display_name } : Types.CreateUserInput.t) =
  let* user_or_error =
    Dream.sql req (Db.User.insert ~public_facing_id:user_id ~display_name)
  in
  let* () = Caqti_lwt.or_fail user_or_error in
  Lwt.return Types.CreateUserOutput.{ user_id }

let get_user _req _user_id =
  Lwt.return
    Types.GetUserOutput.
      { user = { display_name = "TODO"; user_id = "TODO" } }

let users req (query : Types.UsersQuery.t) =
  let* users_or_error =
    Dream.sql req
      (Db.User.get_many ~next:query.next ~prev:query.prev
         ~limit:(Option.value ~default:20 query.limit))
  in
  let* users, next, prev = Caqti_lwt.or_fail users_or_error in
  let objs : Types.User.t list =
    users
    |> List.map (fun Db.User.{ id = _; public_facing_id; display_name } ->
           Types.User.{ user_id = public_facing_id; display_name })
  in
  Lwt.return Types.UsersOutput.{ users = { objs; next; prev } }
(*  PaginatedUsers.create ~next ~prev ~objs*)

let delete_user _req _user_id = Lwt.return ()
