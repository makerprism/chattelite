type config = { api_key : string; client_jwt_secret : string }
[@@deriving yojson]

let load_config filename =
  try
    let json_data = Yojson.Safe.from_file filename in
    json_data |> config_of_yojson
  with Yojson.Json_error e ->
    failwith (Format.sprintf "error parsing JSON: %s\n" e)

let config : config = load_config "./config.json"
