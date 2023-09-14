module type PaginationSig = sig
  type obj
  type t

  val create : next:string option -> prev:string option -> objs:obj list -> t
  val objs : t -> obj list
  val next : t -> string option
  val prev : t -> string option
  val t_of_yojson : Yojson.Safe.t -> t
  val yojson_of_t : t -> Yojson.Safe.t
end

module Make (T : sig
  type t

  val t_of_yojson : Yojson.Safe.t -> t
  val yojson_of_t : t -> Yojson.Safe.t
end) : PaginationSig with type obj = T.t = struct
  type t = { next : string option; prev : string option; objs : T.t list }
  [@@deriving yojson]

  type obj = T.t

  let create ~next ~prev ~objs = { next; prev; objs }
  let objs t = t.objs
  let next t = t.next
  let prev t = t.prev
end
