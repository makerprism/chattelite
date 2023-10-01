let error_handler =
  (fun error _debug_dump suggested_response ->
    match error.condition with
    | `Exn (Api.Generated_server_endpoints.BadRequest msg) ->
        Dream.json ~code:400 (Format.sprintf "{ \"message\": \"%s\" }" msg)
    | `Exn (Api.Generated_client_endpoints.BadRequest msg) ->
        Dream.json ~code:400 (Format.sprintf "{ \"message\": \"%s\" }" msg)
    | `Exn (Db.Db_schema.BadRequest msg) ->
        Dream.json ~code:400 (Format.sprintf "{ \"message\": \"%s\" }" msg)
    | _ -> Lwt.return suggested_response)
  |> Dream.error_template

let () =
  (*Lwt.async Server_sent_events.message_loop;*)
  Dream.run ~error_handler @@ Dream.logger
  @@ Dream.sql_pool "postgresql://postgres:test@127.0.0.1:5432/ocaml_api"
  (*@@ Dream.origin_referrer_check*)
  @@ Dream.router
       [
         Dream.get "/" (fun _ -> Dream.html Home.render);
         Dream.get "/push" (fun _ ->
             Dream.stream
               ~headers:[ ("Content-Type", "text/event-stream") ]
               Api.Server_sent_events.forward_messages);
         Dream.scope ""
           [ Auth.check_server_api_key ]
           Api.Generated_server_endpoints.routes;
         Dream.scope "" [ Auth.check_client_jwt ]
           Api.Generated_client_endpoints.routes;
       ]
