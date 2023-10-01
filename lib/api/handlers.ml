open Lwt.Syntax

exception BadRequest of string
exception InternalError of string

let run_db req query =
  let* result_or_error = Dream.sql req query in
  Caqti_lwt.or_fail result_or_error

module Client = struct
  module T = Generated_client_types

  let conversations req (query : T.ConversationsQuery.t) =
    let* conversations, next, prev =
      run_db req
        (Db.Conversation.get_many ~next:query.next ~prev:query.prev
           ~limit:(Option.value ~default:20 query.limit))
    in
    let objs : T.Conversation.t list =
      conversations
      |> List.map (fun Db.Conversation.{ id; _ } ->
             T.Conversation.
               {
                 conversation_id = Int64.to_string id;
                 timestamp = "TODO";
                 number_of_unread_messages = -1;
                 newest_line = None;
               })
    in
    Lwt.return T.ConversationsOutput.{ conversations = { objs; next; prev } }

  (*    Server_sent_events.broadcast_message (T.ConversationEvent.ConversationEventJoin { from = { Conversation_id; display_name }; timestamp= "TODO"}); *)

  (*
   curl -H "X-Access-Token: eyJhbGciOiJIUzI1NiJ9.YOU_MUST_SET_THIS.st_VZPdJx3BHvVCY2oWplin4oz6BNWhn-hoAaTVCwbU" http://localhost:8080/conversations
  *)
end

module Server = struct
  module T = Generated_server_types

  let create_user req ({ user_id; display_name } : T.CreateUserInput.t) =
    let* () =
      run_db req (Db.User.insert ~public_facing_id:user_id ~display_name)
    in
    Lwt.return T.CreateUserOutput.{ user_id }

  (*
  curl -X POST \
     -H "Content-Type: application/json" \
     -H "X-Access-Token: YOU_MUST_SET_THIS" \
     -d '{"user_id":"abc", "display_name": "abc"}' \
     http://localhost:8080/_/users
*)

  let get_user req user_id =
    let* user = run_db req (Db.User.get_one ~public_facing_id:user_id) in
    Lwt.return
      T.GetUserOutput.
        {
          user =
            {
              user_id = user.public_facing_id;
              display_name = user.display_name;
            };
        }

  let users req (query : T.UsersQuery.t) =
    let* users, next, prev =
      run_db req
        (Db.User.get_many ~next:query.next ~prev:query.prev
           ~limit:(Option.value ~default:20 query.limit))
    in
    let objs : T.User.t list =
      users
      |> List.map (fun Db.User.{ id = _; public_facing_id; display_name } ->
             T.User.{ user_id = public_facing_id; display_name })
    in
    Lwt.return T.UsersOutput.{ users = { objs; next; prev } }

  let delete_user _req _user_id = failwith "not implemented" (* Lwt.return ()*)

  let generate_client_jwt _req ({ user_id } : T.GenerateClientJwtInput.t) =
    let payload = [ ("user_id", user_id) ] in
    match Jwto.encode Jwto.HS256 Config.config.client_jwt_secret payload with
    | Ok jwt -> Lwt.return T.GenerateClientJwtOutput.{ jwt }
    | Error message -> raise (InternalError ("Failed to encode JWT" ^ message))

  (* TODO: generate JWT with expiration time?
     IMPORTANT NOTE: jwto library does not seem to support
     checking expiration time at this point *)

  (*
      curl -X POST \
     -H "Content-Type: application/json" \
     -H "X-Access-Token: YOU_MUST_SET_THIS" \
     -d '{"user_id":"sabine"}' \
     http://localhost:8080/_/gen-client-jwt
    *)

  (* TODO: conversation endpoints, when user joins conversation, send message:
     Server_sent_events.broadcast_message (T.ConversationEvent.ConversationEventJoin { from = { user_id; display_name }; timestamp= "TODO"}); *)
end
