type algorithm = HS256 | HS384 | HS512 [@@deriving yojson]
type typ = JWT [@@deriving yojson]
type t = { algorithm : algorithm; typ : typ } [@@deriving yojson]

let algorithm v ~secret =
  match v.algorithm with
  | HS256 ->
      fun str ->
        Digestif.SHA3_256.hmac_string ~key:secret str
        |> Digestif.SHA3_256.to_raw_string
  | HS384 ->
      fun str ->
        Digestif.SHA3_384.hmac_string ~key:secret str
        |> Digestif.SHA3_384.to_raw_string
  | HS512 ->
      fun str ->
        Digestif.SHA3_512.hmac_string ~key:secret str
        |> Digestif.SHA3_512.to_raw_string

let default () = { algorithm = HS512; typ = JWT }
