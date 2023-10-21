module DefaultHeader = struct
  type algorithm = HS256 | HS512 | None [@@deriving yojson]
  type typ = JWT [@@deriving yojson]
  type t = { algorithm : algorithm; typ : typ } [@@deriving yojson]

  let algorithm v ~secret =
    match v.algorithm with
    | HS256 ->
        fun str ->
          Digestif.SHA256.hmac_string ~key:secret str
          |> Digestif.SHA256.to_raw_string
    | HS512 ->
        fun str ->
          Digestif.SHA512.hmac_string ~key:secret str
          |> Digestif.SHA512.to_raw_string
    | _ -> failwith "not implemented"

  let default () = { algorithm = HS512; typ = JWT }
end

module type JwtSig = sig
  module Header : sig
    type t

    val default : unit -> t
  end

  module Claims : sig
    type t
  end

  type t = { header : Header.t; claims : Claims.t; signature : string }

  val encode :
    ?header:Header.t -> secret:string -> Claims.t -> (string, string) result

  val decode : secret:string -> jwt:string -> (t, string) result
  (*val is_valid : secret:string -> jwt:string -> bool*)
end

module Make (Header : sig
  type t

  val algorithm : t -> secret:string -> string -> string
  val default : unit -> t
  val yojson_of_t : t -> Yojson.Safe.t
  val t_of_yojson : Yojson.Safe.t -> t
end) (Claims : sig
  type t

  val yojson_of_t : t -> Yojson.Safe.t
  val t_of_yojson : Yojson.Safe.t -> t
end) : JwtSig with module Header = Header and module Claims = Claims = struct
  module Header = Header
  module Claims = Claims

  type t = { header : Header.t; claims : Claims.t; signature : string }

  let encode_base64 str =
    Base64.encode ~pad:false ~alphabet:Base64.uri_safe_alphabet str

  let decode_base64 str =
    let r = Base64.decode ~pad:false ~alphabet:Base64.uri_safe_alphabet str in
    match r with
    | Ok s -> s
    | Error _ -> failwith (Printf.sprintf "Error decoding\n  %s" str)

  let encode ?(header = Header.default ()) ~secret claims =
    let base64_header =
      match
        Header.yojson_of_t header |> Yojson.Safe.to_string |> encode_base64
      with
      | Ok h -> h
      | Error _ -> failwith "Error base64 encoding header"
    in
    let base64_claims =
      match
        claims |> Claims.yojson_of_t |> Yojson.Safe.to_string |> encode_base64
      with
      | Ok h -> h
      | Error _ -> failwith "Error base64 encoding claims"
    in
    let unsigned_token = base64_header ^ "." ^ base64_claims in
    let signature =
      match Header.algorithm header ~secret unsigned_token |> encode_base64 with
      | Ok h -> h
      | Error _ -> failwith "Error base64 encoding signature"
    in
    Ok (unsigned_token ^ "." ^ signature)

  let decode ~secret ~jwt =
    let base64_header, base64_claims, base64_signature =
      match jwt |> String.split_on_char '.' with
      | [ h; c; s ] -> (h, c, s)
      | _ -> failwith "couldn't split jwt"
    in
    let header =
      base64_header |> decode_base64 |> Yojson.Safe.from_string
      |> Header.t_of_yojson
    in
    let claims =
      base64_claims |> decode_base64 |> Yojson.Safe.from_string
      |> Claims.t_of_yojson
    in
    let get_signature base64_header base64_claims base64_signature =
      let signature = base64_signature |> decode_base64 in
      let unsigned_token = base64_header ^ "." ^ base64_claims in
      let check_signature = Header.algorithm header ~secret unsigned_token in
      if signature = check_signature then Ok signature
      else Error "Signatures don't match"
    in
    match get_signature base64_header base64_claims base64_signature with
    | Ok signature -> Ok { header; claims; signature }
    | Error e -> Error e

  (*let is_valid ~secret:_ ~jwt:_ = failwith "not implemented"*)
end

(* TODO: use mirage-crypto *)
