open Lwt.Syntax

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

(*    Server_sent_events.broadcast_message (App_types.ConversationEvent.ConversationEventJoin { from = { Conversation_id; display_name }; timestamp= "TODO"}); *)
