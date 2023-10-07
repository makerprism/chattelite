let () =
  let server_routes =
    [
      Dream.scope ""
        [ Api.Auth.check_server_api_key ~api_key:Api.Config.config.api_key ]
        Api.Generated_server_endpoints.routes;
    ]
  in
  let client_routes =
    [
      Dream.scope ""
        [
          Api.Auth.check_client_jwt
            ~jwt_secret:Api.Config.config.client_jwt_secret;
        ]
        Api.Generated_client_endpoints.routes;
      Dream.get "/push" (fun _ ->
          Dream.stream
            ~headers:[ ("Content-Type", "text/event-stream") ]
            Api.Server_sent_events.forward_messages);
    ]
  in

  Dream.run @@ Dream.logger
  @@ Dream.sql_pool Api.Config.config.database_url
  (*@@ Dream.origin_referrer_check*)
  @@ Dream.router
       ([ Dream.get "/" (fun _ -> Dream.html Home.render) ]
       @ server_routes @ client_routes)
