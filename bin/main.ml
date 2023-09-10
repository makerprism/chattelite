let () =
  Lwt.async Server_sent_events.message_loop;

  Dream.run @@ Dream.logger
  @@ Dream.sql_pool "postgresql://postgres:test@127.0.0.1:5432/ocaml_api"
  (*@@ Dream.origin_referrer_check*)
  @@ Dream.router
       ([
          Dream.get "/" (fun _ -> Dream.html Home.render);
          Dream.get "/push" (fun _ ->
              Dream.stream
                ~headers:[ ("Content-Type", "text/event-stream") ]
                Server_sent_events.forward_messages);
        ]
       @ Api.Generated_api.routes)
