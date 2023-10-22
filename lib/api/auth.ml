module JwtClaims = struct
  type t = { public_facing_id : string } [@@deriving yojson]

  let check _ = Ok () (* FIXME: proper checks*)
end

type client_session = {
  id : int64;
  public_facing_id : string;
  display_name : string;
}

let user_field : client_session Dream.field = Dream.new_field ()

module Jwt = Jwt.Make (Jwt.DefaultHeader) (JwtClaims)

let check_client_jwt ~jwt_secret : Dream.middleware =
 fun h req ->
  let jwt = Dream.header req "X-Access-Token" in
  match jwt with
  | Some jwt -> (
      match Jwt.decode ~secret:jwt_secret ~jwt with
      | Ok jwt ->
          let public_facing_id = jwt.claims.JwtClaims.public_facing_id in

          (*let id = List.find_map (fun (field, value) -> if field = "id" then Some (Int64.of_string value) else None) payload |> Option.get in*)
          (*let display_name = List.find_map (fun (field, value) -> if field = "display_name" then Some ( value) else None) payload |> Option.get in*)
          (* FIXME: load id, display_name from database / cache *)
          Dream.set_field req user_field
            { id = -999L; public_facing_id; display_name = "TODO" };
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
