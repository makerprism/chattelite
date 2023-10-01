type client_session = {
  id : int64;
  public_facing_id : string;
  display_name : string;
}

let check_client_jwt ~jwt_secret : Dream.middleware =
 fun h req ->
  let jwt = Dream.header req "X-Access-Token" in
  match jwt with
  | Some jwt -> (
      match Jwto.decode_and_verify jwt_secret jwt with
      | Ok _jwto -> h req
      | Error message ->
          Lwt.return
            (Dream.response ~code:403 ("client JWT is invalid: " ^ message)))
  | None -> Lwt.return (Dream.response ~code:400 "X-Access-Token is missing")

let check_server_api_key ~api_key : Dream.middleware =
 fun h req ->
  let key = Dream.header req "X-Access-Token" in
  match key with
  | Some key ->
      if key = api_key then h req
      else Lwt.return (Dream.response ~code:403 "API key is invalid")
  | None ->
      Lwt.return
        (Dream.response ~code:400 "API key in X-Access-Token is missing")
