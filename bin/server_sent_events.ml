type message_object = {
  i : int;
} [@@deriving yojson]

let server_state =
  ref []

let notify =
  ref ignore

let last_message =
  ref 0

let rec message_loop () =
  let%lwt () = Lwt_unix.sleep (Random.float 2.) in

  incr last_message;

  let message = { i = !last_message } |> yojson_of_message_object |> Yojson.Safe.to_string in
  (*Dream.log "Generated message %s" message;*)

  server_state := message::!server_state;
  !notify ();

  message_loop ()

let rec forward_messages stream =
  let%lwt messages =
    match !server_state with
    | [] ->
      let on_message, notify_message = Lwt.wait () in
      notify := Lwt.wakeup_later notify_message;
      let%lwt () = on_message in
      notify := ignore;
      Lwt.return !server_state
    | messages ->
      Lwt.return messages
  in

  server_state := [];

  messages
  |> List.rev
  |> List.map (Printf.sprintf "data: %s\n\n")
  |> String.concat ""
  |> fun text ->
    let%lwt () = Dream.write stream text in
    let%lwt () = Dream.flush stream in
    forward_messages stream