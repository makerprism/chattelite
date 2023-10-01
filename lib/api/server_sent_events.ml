let waiting_connections = ref []

let broadcast_message (message : Client_types.ConversationEvent.t) =
  let message =
    message |> Client_types.ConversationEvent.yojson_of_t
    |> Yojson.Safe.to_string
  in

  (* Wake up all waiting connections and pass message to them *)
  List.iter (fun notify -> notify [ message ]) !waiting_connections;
  waiting_connections := []

let rec forward_messages stream =
  let open Lwt.Syntax in
  let* messages =
    let on_message, notify_message = Lwt.wait () in
    waiting_connections :=
      (fun state -> Lwt.wakeup_later notify_message state)
      :: !waiting_connections;
    let* received_messages = on_message in
    Lwt.return received_messages
  in

  messages |> List.rev
  |> List.map (Printf.sprintf "data: %s\n\n")
  |> String.concat ""
  |> fun text ->
  let* () = Dream.write stream text in
  let* () = Dream.flush stream in
  forward_messages stream
