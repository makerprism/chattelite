open Lwt.Syntax

let bad_request msg =
  Dream.json ~code:400 (Format.sprintf "{ \"message\": \"%s\" }" msg)

let internal_error msg =
  Dream.json ~code:500 (Format.sprintf "{ \"message\": \"%s\" }" msg)

let run_db req query =
  let* result_or_error = Dream.sql req query in
  Caqti_lwt.or_fail result_or_error

module Client = struct
  module T = Generated_client_types

  let bad_request = bad_request
  let internal_error = internal_error

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
    Lwt.return
      (Ok T.ConversationsOutput.{ conversations = { objs; next; prev } })

  (*    Server_sent_events.broadcast_message (T.ConversationEvent.ConversationEventJoin { from = { Conversation_id; display_name }; timestamp= "TODO"}); *)

  (*
   curl -H "X-Access-Token: eyJhbGciOiJIUzI1NiJ9.YOU_MUST_SET_THIS.st_VZPdJx3BHvVCY2oWplin4oz6BNWhn-hoAaTVCwbU" http://localhost:8080/conversations
  *)
end

module Server = struct
  module T = Generated_server_types

  let bad_request = bad_request
  let internal_error = internal_error

  let create_user req ({ user_id; display_name } : T.CreateUserInput.t) =
    let* () =
      run_db req (Db.User.insert ~public_facing_id:user_id ~display_name)
    in
    Lwt.return (Ok T.CreateUserOutput.{ user_id })

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
      (Ok
         T.GetUserOutput.
           {
             user =
               {
                 user_id = user.public_facing_id;
                 display_name = user.display_name;
               };
           })

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
    Lwt.return (Ok T.UsersOutput.{ users = { objs; next; prev } })

  let delete_user _req _user_id = failwith "not implemented" (* Lwt.return ()*)

  let generate_client_jwt _req ({ user_id } : T.GenerateClientJwtInput.t) =
    let payload =
      Auth.JwtClaims.
        {
          public_facing_id = user_id;
          exp = Ptime.of_float_s @@ (Unix.time () +. 300.0) |> Option.get;
        }
    in
    match Auth.Jwt.encode ~secret:Config.config.client_jwt_secret payload with
    | Ok jwt -> Lwt.return (Ok T.GenerateClientJwtOutput.{ jwt })
    | Error message ->
        Lwt.return (Error (internal_error ("Failed to encode JWT" ^ message)))

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

  let create_conversation req
      (T.CreateConversationInput.{ data; _ } : T.CreateConversationInput.t) =
    let* _conversation_id = run_db req (Db.Conversation.insert ~data) in
    failwith "not_implemented"
  (*Lwt.return T.CreateConversationOutput.{ conversation_id }*)

  let update_converstaion _req _conversation_id _body =
    failwith "not_implemented"

  let add_users_to_conversation _req _conversation_id _body =
    failwith "not_implemented"

  let remove_users_from_conversation _req _conversation_id _body =
    failwith "not_implemented"
end
