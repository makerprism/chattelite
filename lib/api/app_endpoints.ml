(* AUTOMATICALLY GENERATED BY codegen/main.ml *)

open Lwt.Syntax

exception BadRequest of string

let create_user (req : Dream.request) =
  let* body = Dream.body req in
  let body =
    App_types.CreateUserInput.t_of_yojson (Yojson.Safe.from_string body)
  in
  let* (result : App_types.CreateUserOutput.t) =
    App_handlers.create_user req body
  in
  result |> App_types.CreateUserOutput.yojson_of_t |> Yojson.Safe.to_string
  |> Dream.json

let users (req : Dream.request) =
  let query =
    match App_types.UsersQuery.parse_query req with
    | Ok q -> q
    | Error msg -> raise (BadRequest msg)
  in
  let* (result : App_types.UsersOutput.t) = App_handlers.users req query in
  result |> App_types.UsersOutput.yojson_of_t |> Yojson.Safe.to_string
  |> Dream.json

let get_user (req : Dream.request) =
  let user_id = Dream.param req "user_id" in
  let* (result : App_types.GetUserOutput.t) =
    App_handlers.get_user req user_id
  in
  result |> App_types.GetUserOutput.yojson_of_t |> Yojson.Safe.to_string
  |> Dream.json

let delete_user (req : Dream.request) =
  let user_id = Dream.param req "user_id" in
  let* (result : App_types.DeleteUserOutput.t) =
    App_handlers.delete_user req user_id
  in
  result |> App_types.DeleteUserOutput.yojson_of_t |> Yojson.Safe.to_string
  |> Dream.json

let routes =
  [
    Dream.post "/users" create_user;
    Dream.get "/users" users;
    Dream.get "/user/:user_id" get_user;
    Dream.delete "/user/:user_id" delete_user;
  ]
