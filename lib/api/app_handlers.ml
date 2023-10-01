open Lwt.Syntax

let create_user req ({ user_id; display_name } : App_types.CreateUserInput.t) =
  let* user_or_error =
    Dream.sql req (Db.User.insert ~public_facing_id:user_id ~display_name)
  in
  let* () = Caqti_lwt.or_fail user_or_error in
  Lwt.return App_types.CreateUserOutput.{ user_id }

(* curl -X POST -H "Content-Type: application/json" -d '{"user_id":"sabine", "display_name": "sabine"}' http://localhost:8080/users
*)

(*    Server_sent_events.broadcast_message (App_types.ConversationEvent.ConversationEventJoin { from = { user_id; display_name }; timestamp= "TODO"}); *)

let get_user req user_id =
  let* user_or_error =
    Dream.sql req (Db.User.get_one ~public_facing_id:user_id)
  in
  let* user = Caqti_lwt.or_fail user_or_error in
  Lwt.return
    App_types.GetUserOutput.
      {
        user =
          { user_id = user.public_facing_id; display_name = user.display_name };
      }

let users req (query : App_types.UsersQuery.t) =
  let* users_or_error =
    Dream.sql req
      (Db.User.get_many ~next:query.next ~prev:query.prev
         ~limit:(Option.value ~default:20 query.limit))
  in
  let* users, next, prev = Caqti_lwt.or_fail users_or_error in
  let objs : App_types.User.t list =
    users
    |> List.map (fun Db.User.{ id = _; public_facing_id; display_name } ->
           App_types.User.{ user_id = public_facing_id; display_name })
  in
  Lwt.return App_types.UsersOutput.{ users = { objs; next; prev } }

let delete_user _req _user_id = Lwt.return ()
