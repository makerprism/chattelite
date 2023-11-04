module JwtClaims = struct
  type t = { public_facing_id : string; exp : Jwt.NumericTime.t }
  [@@deriving yojson]

  let check _ = Ok () (* FIXME: proper checks*)
end

type client_session = {
  id : int64;
  public_facing_id : string;
  display_name : string;
}

let user_field : client_session Dream.field = Dream.new_field ()

module Jwt = Jwt.Make (Jwt.DefaultHeader) (JwtClaims)

let run_db req query =
  let open Lwt.Syntax in
  let* result_or_error = Dream.sql req query in
  Caqti_lwt.or_fail result_or_error

let check_client_jwt ~jwt_secret : Dream.middleware =
 fun h req ->
  let jwt = Dream.header req "X-Access-Token" in
  match jwt with
  | Some jwt -> (
      match Jwt.decode ~secret:jwt_secret jwt with
      | Ok jwt ->
          let open Lwt.Syntax in
          let public_facing_id = jwt.claims.JwtClaims.public_facing_id in
          let* user = run_db req (Db.User.get_one ~public_facing_id) in
          Dream.set_field req user_field
            {
              id = user.id;
              public_facing_id = user.public_facing_id;
              display_name = user.display_name;
            };
          h req
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
