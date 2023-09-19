open Lwt.Syntax

exception FailedToParseQuery of string

let create_user (req: Dream.request) =
  let* body = Dream.body req in
  let body = Api_types.CreateUserInput.t_of_yojson (Yojson.Safe.from_string body) in
  let* result : Api_types.CreateUserOutput.t = Handler.create_user req body in
  result |> Api_types.CreateUserOutput.yojson_of_t |> Yojson.Safe.to_string |> Dream.json

let users (req: Dream.request) =
  let query =
    let name = Dream.query req "name" in
    let next = Dream.query req "next" in
    let prev = Dream.query req "prev" in
    let limit = try Dream.query req "limit" |> Option.map int_of_string with _ -> raise (FailedToParseQuery "limit") in
    Api_types.UsersQuery.{ name; next; prev; limit }
  in
  let* result : Api_types.UsersOutput.t = Handler.users req query in
  result |> Api_types.UsersOutput.yojson_of_t |> Yojson.Safe.to_string |> Dream.json

let get_user (req: Dream.request) =
  let user_id = Dream.param req "user_id" in
  let* result : Api_types.GetUserOutput.t = Handler.get_user req user_id in
  result |> Api_types.GetUserOutput.yojson_of_t |> Yojson.Safe.to_string |> Dream.json

let delete_user (req: Dream.request) =
  let user_id = Dream.param req "user_id" in
  let* result : Api_types.DeleteUserOutput.t = Handler.delete_user req user_id in
  result |> Api_types.DeleteUserOutput.yojson_of_t |> Yojson.Safe.to_string |> Dream.json

let routes = [
  Dream.post "/users" create_user;
  Dream.get "/users" users;
  Dream.get "/user/:user_id" get_user;
  Dream.delete "/user/:user_id" delete_user
]