open Ppx_yojson_conv_lib.Yojson_conv

type config = {
  api_key : string;
  client_jwt_secret : string;
  database_url : string;
}
[@@deriving yojson]

let load_config filename =
  try
    let json_data = Yojson.Safe.from_file filename in
    let config = json_data |> config_of_yojson in
    if config.client_jwt_secret = "YOU_MUST_CHANGE_THIS" then
      failwith "You have to set up the client JWT secret in config.json";
    if config.api_key = "YOU_MUST_CHANGE_THIS" then
      failwith "You have to set up the API key in config.json";
    config
  with
  | Yojson.Json_error e ->
      failwith (Format.sprintf "error parsing JSON: %s\n" e)
  | Sys_error e ->
      failwith (Format.sprintf "Error trying to load config.json: %s\n" e)

let config : config = load_config "./config.json"
