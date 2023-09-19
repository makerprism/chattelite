open Lwt.Syntax

let create_user (req: Dream.request) =
  let* body = Dream.body req in
  let body = Api_types.CreateUserInput.t_of_yojson (Yojson.Safe.from_string body) in
  let result = Handler.create_user req body in
  result

let users (req: Dream.request) =
  let name = Dream.query req "name" in
  let next = Dream.query req "next" in
  let prev = Dream.query req "prev" in
  let limit = Dream.query req "limit" |> Option.map int_of_string in
  let query = Api_types.UsersQuery.{ name; next; prev; limit } in
  let result = Handler.users req query in
  result

let get_user (req: Dream.request) =
  let user_id = Dream.param req "user_id" in
  let result = Handler.get_user req user_id in
  result

let delete_user (req: Dream.request) =
  let user_id = Dream.param req "user_id" in
  let result = Handler.delete_user req user_id in
  result

let routes = [
  Dream.post "/users" create_user;
  Dream.get "/users" users;
  Dream.get "/user/:user_id" get_user;
  Dream.delete "/user/:user_id" delete_user
]