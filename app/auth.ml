type client_session = {
  id : int64;
  public_facing_id : string;
  display_name : string;
}

let check_client_jwt : Dream.middleware =
 fun h req ->
  let jwt = Dream.header req "X-Access-Token" in
  match jwt with
  | Some jwt -> (
      match Jwto.decode_and_verify "TODO:secret" jwt with
      | Ok _jwto -> h req
      | Error message ->
          Lwt.return
            (Dream.response ~code:403 ("client JWT is invalid: " ^ message)))
  | None -> Lwt.return (Dream.response ~code:400 "X-Access-Token is missing")

let check_server_api_key : Dream.middleware =
 fun h req ->
  let api_key = Dream.header req "X-Access-Token" in
  match api_key with
  | Some api_key ->
      if api_key = "TODO:API_KEY" then h req
      else Lwt.return (Dream.response ~code:403 "API key is invalid")
  | None ->
      Lwt.return
        (Dream.response ~code:400 "API key in X-Access-Token is missing")
