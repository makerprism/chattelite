module DefaultHeader = struct
  include Default_header
end

module type JwtSig = sig
  module Header : sig
    type t

    val default : unit -> t
  end

  module Claims : sig
    type t

    val check : t -> (unit, string) result
  end

  type t = { header : Header.t; claims : Claims.t; signature : string }

  val encode :
    ?header:Header.t -> secret:string -> Claims.t -> (string, string) result

  val decode : secret:string -> jwt:string -> (t, string) result
  val decode_and_check : secret:string -> jwt:string -> (t, string) result
end

module Make (Header : sig
  type t

  val algorithm : t -> secret:string -> string -> string
  val default : unit -> t
  val yojson_of_t : t -> Yojson.Safe.t
  val t_of_yojson : Yojson.Safe.t -> t
end) (Claims : sig
  type t

  val check : t -> (unit, string) result
  val yojson_of_t : t -> Yojson.Safe.t
  val t_of_yojson : Yojson.Safe.t -> t
end) : JwtSig with module Header = Header and module Claims = Claims = struct
  module Header = Header
  module Claims = Claims

  type t = { header : Header.t; claims : Claims.t; signature : string }

  let ( let<? ) result = Result.bind result

  let encode_base64 str =
    Base64.encode ~pad:false ~alphabet:Base64.uri_safe_alphabet str

  let decode_base64 str =
    match Base64.decode ~pad:false ~alphabet:Base64.uri_safe_alphabet str with
    | Ok s -> Ok s
    | Error (`Msg e) -> Error e

  let encode ?(header = Header.default ()) ~secret claims =
    let<? base64_header =
      Header.yojson_of_t header |> Yojson.Safe.to_string |> encode_base64
      |> Result.map_error (fun _ -> "Failed to encode base64 header!")
    in
    let<? base64_claims =
      claims |> Claims.yojson_of_t |> Yojson.Safe.to_string |> encode_base64
      |> Result.map_error (fun _ -> "Failed to encode base64 claims!")
    in
    let unsigned_token = base64_header ^ "." ^ base64_claims in
    let<? signature =
      Header.algorithm header ~secret unsigned_token
      |> encode_base64
      |> Result.map_error (fun _ -> "Failed to encode base64 signature!")
    in
    Ok (unsigned_token ^ "." ^ signature)

  let decode ~secret ~jwt =
    let check_and_get_signature ~header ~base64_header ~base64_claims
        ~base64_signature =
      let<? signature = base64_signature |> decode_base64 in
      let unsigned_token = base64_header ^ "." ^ base64_claims in
      let check_signature = Header.algorithm header ~secret unsigned_token in
      if signature = check_signature then Ok signature
      else Error "JWT signature is invalid!"
    in

    match jwt |> String.split_on_char '.' with
    | [ base64_header; base64_claims; base64_signature ] ->
        let<? string_header = base64_header |> decode_base64 in
        let<? header =
          try Ok (string_header |> Yojson.Safe.from_string |> Header.t_of_yojson)
          with Yojson.Json_error e -> Error e
        in
        let<? signature =
          check_and_get_signature ~header ~base64_header ~base64_claims
            ~base64_signature
        in
        let<? string_claims = base64_claims |> decode_base64 in
        let<? claims =
          try Ok (string_claims |> Yojson.Safe.from_string |> Claims.t_of_yojson)
          with Yojson.Json_error e -> Error e
        in
        Ok { header; claims; signature }
    | _ -> Error "Couldn't split JWT into header, claims, and signature!"

  let decode_and_check ~secret ~jwt =
    let check ~jwt = Claims.check jwt.claims in

    let<? decoded_jwt = decode ~secret ~jwt in
    let<? _ = check ~jwt:decoded_jwt in
    Ok decoded_jwt
end
