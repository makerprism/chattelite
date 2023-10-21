module DefaultHeader : sig
  type algorithm = HS256 | HS512 | None [@@deriving yojson]
  type typ = JWT [@@deriving yojson]
  type t = { algorithm : algorithm; typ : typ } [@@deriving yojson]

  val algorithm : t -> secret:string -> string -> string
  val default : unit -> t
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
end

module Make (Header : sig
  type t

  val algorithm : t -> secret:string -> string -> string
  val default : unit -> t
  val yojson_of_t : t -> Yojson.Safe.t
  val t_of_yojson : Yojson.Safe.t -> t
end) (Claims : sig
  type t

  (* FIXME: add checking of claims and add checking of RFC claims like exp *)

  val yojson_of_t : t -> Yojson.Safe.t
  val t_of_yojson : Yojson.Safe.t -> t
end) : JwtSig with module Header = Header and module Claims = Claims
