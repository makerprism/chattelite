open Lwt.Syntax

module Client = struct
  let conversations req (query : Client_types.ConversationsQuery.t) =
    let* conversations_or_error =
      Dream.sql req
        (Db.Conversation.get_many ~next:query.next ~prev:query.prev
           ~limit:(Option.value ~default:20 query.limit))
    in
    let* conversations, next, prev = Caqti_lwt.or_fail conversations_or_error in
    let objs : Client_types.Conversation.t list =
      conversations
      |> List.map (fun Db.Conversation.{ id; _ } ->
             Client_types.Conversation.
               {
                 conversation_id = Int64.to_string id;
                 timestamp = "TODO";
                 number_of_unread_messages = -1;
                 newest_line = None;
               })
    in
    Lwt.return
      Client_types.ConversationsOutput.{ conversations = { objs; next; prev } }

  (*    Server_sent_events.broadcast_message (Server_types.ConversationEvent.ConversationEventJoin { from = { Conversation_id; display_name }; timestamp= "TODO"}); *)
end

module Server = struct
  let create_user req
      ({ user_id; display_name } : Server_types.CreateUserInput.t) =
    let* user_or_error =
      Dream.sql req (Db.User.insert ~public_facing_id:user_id ~display_name)
    in
    let* () = Caqti_lwt.or_fail user_or_error in
    Lwt.return Server_types.CreateUserOutput.{ user_id }

  (* curl -X POST -H "Content-Type: application/json" -d '{"user_id":"sabine", "display_name": "sabine"}' http://localhost:8080/users
  *)

  (*    Server_sent_events.broadcast_message (Server_types.ConversationEvent.ConversationEventJoin { from = { user_id; display_name }; timestamp= "TODO"}); *)

  let get_user req user_id =
    let* user_or_error =
      Dream.sql req (Db.User.get_one ~public_facing_id:user_id)
    in
    let* user = Caqti_lwt.or_fail user_or_error in
    Lwt.return
      Server_types.GetUserOutput.
        {
          user =
            {
              user_id = user.public_facing_id;
              display_name = user.display_name;
            };
        }

  let users req (query : Server_types.UsersQuery.t) =
    let* users_or_error =
      Dream.sql req
        (Db.User.get_many ~next:query.next ~prev:query.prev
           ~limit:(Option.value ~default:20 query.limit))
    in
    let* users, next, prev = Caqti_lwt.or_fail users_or_error in
    let objs : Server_types.User.t list =
      users
      |> List.map (fun Db.User.{ id = _; public_facing_id; display_name } ->
             Server_types.User.{ user_id = public_facing_id; display_name })
    in
    Lwt.return Server_types.UsersOutput.{ users = { objs; next; prev } }

  let delete_user _req _user_id = Lwt.return ()
end
