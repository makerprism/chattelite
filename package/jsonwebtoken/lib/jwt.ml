module DefaultHeader = struct
  include Default_header
end

module NumericTime = struct
  include Ptime

  let yojson_of_t v =
    let t = Ptime.to_float_s v |> int_of_float in
    `Int t

  let to_t_option v =
    let f =
      match v with
      | `Float f -> Some f
      | `Int f -> Some (float_of_int f)
      | `Null -> None
      | _ -> raise (Yojson.Json_error "Failed to decode int or float!")
    in
    Option.map
      (fun f ->
        match Ptime.of_float_s f with
        | None -> raise (Yojson.Json_error "Failed to decode NumericTime.t!")
        | Some t -> t)
      f

  let t_of_yojson (v : Yojson.Safe.t) =
    let f =
      match v with
      | `Float f -> f
      | `Int f -> float_of_int f
      | _ -> raise (Yojson.Json_error "Failed to decode int or float!")
    in
    match Ptime.of_float_s f with
    | None -> raise (Yojson.Json_error "Failed to decode NumericTime!")
    | Some t -> t
end

let ( let<? ) result = Result.bind result

let check_exp ~now exp =
  if Ptime.is_earlier exp ~than:now then Error "Token has expired (now > exp)!"
  else Ok ()

let check_nbf ~now nbf =
  if Ptime.is_earlier nbf ~than:now then Ok ()
  else Error "Token is not yet valid (nbf > now)!"

module type Sig = sig
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

  val decode : ?unchecked:bool -> secret:string -> string -> (t, string) result
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
end) : Sig with module Header = Header and module Claims = Claims = struct
  module Header = Header
  module Claims = Claims

  type t = { header : Header.t; claims : Claims.t; signature : string }

  let encode_base64 str =
    Base64.encode ~pad:false ~alphabet:Base64.uri_safe_alphabet str

  let decode_base64 str =
    match Base64.decode ~pad:false ~alphabet:Base64.uri_safe_alphabet str with
    | Ok s -> Ok s
    | Error (`Msg e) -> Error e

  let yojson_of_base64_string base64_str =
    let<? str = base64_str |> decode_base64 in
    try Ok (str |> Yojson.Safe.from_string)
    with Yojson.Json_error e -> Error e

  let base64_string_of_yojson v = v |> Yojson.Safe.to_string |> encode_base64

  let encode ?(header = Header.default ()) ~secret claims =
    let<? base64_header =
      Header.yojson_of_t header |> base64_string_of_yojson
      |> Result.map_error (fun _ -> "Failed to base64-encode header!")
    in
    let<? base64_claims =
      claims |> Claims.yojson_of_t |> base64_string_of_yojson
      |> Result.map_error (fun _ -> "Failed to base64-encode claims!")
    in
    let unsigned_token = base64_header ^ "." ^ base64_claims in
    let<? signature =
      Header.algorithm header ~secret unsigned_token
      |> encode_base64
      |> Result.map_error (fun _ -> "Failed to base64-encode signature!")
    in
    Ok (unsigned_token ^ "." ^ signature)

  let split_jwt ~jwt =
    match jwt |> String.split_on_char '.' with
    | [ base64_header; base64_claims; base64_signature ] ->
        Ok (base64_header, base64_claims, base64_signature)
    | _ -> Error "Couldn't split JWT into header, claims, and signature!"

  let check_and_get_signature ~secret ~header ~base64_header ~base64_claims
      ~base64_signature =
    let<? signature = base64_signature |> decode_base64 in
    let unsigned_token = base64_header ^ "." ^ base64_claims in
    let check_signature = Header.algorithm header ~secret unsigned_token in
    if signature = check_signature then Ok signature
    else Error "JWT signature is invalid!"

  let check_claims ~(claims : Yojson.Safe.t) =
    let now = Ptime_clock.now () in
    let<? _ =
      match Yojson.Safe.Util.member "exp" claims |> NumericTime.to_t_option with
      | None -> Ok ()
      | Some exp -> exp |> check_exp ~now
    in
    let<? _ =
      match Yojson.Safe.Util.member "nbf" claims |> NumericTime.to_t_option with
      | None -> Ok ()
      | Some exp -> exp |> check_nbf ~now
    in
    let<? claims =
      try Ok (claims |> Claims.t_of_yojson)
      with Yojson.Json_error e -> Error e
    in
    Claims.check claims

  let decode ?(unchecked = false) ~secret jwt =
    let<? base64_header, base64_claims, base64_signature = split_jwt ~jwt in
    let<? yojson_header = yojson_of_base64_string base64_header in
    let<? header =
      try Ok (yojson_header |> Header.t_of_yojson)
      with Yojson.Json_error e -> Error e
    in
    let<? signature =
      check_and_get_signature ~secret ~header ~base64_header ~base64_claims
        ~base64_signature
    in
    let<? yojson_claims = yojson_of_base64_string base64_claims in
    let<? _ = if unchecked then Ok () else check_claims ~claims:yojson_claims in
    let<? claims =
      try Ok (yojson_claims |> Claims.t_of_yojson)
      with Yojson.Json_error e -> Error e
    in

    Ok { header; claims; signature }
end
