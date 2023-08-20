module type PaginationSig = sig
  type obj
  type t

  val create : cursor:string -> objs:obj list -> t
  val objs : t -> obj list
  val cursor : t -> string

  val schema :
    ?doc:string -> string -> (Context.t, t option) Graphql_lwt.Schema.typ
end

module Make (T : sig
  type t

  val schema : (Context.t, t option) Graphql_lwt.Schema.typ
end) : PaginationSig with type obj = T.t = struct
  type t = { cursor : string; objs : T.t list }
  type obj = T.t

  let create ~cursor ~objs = { cursor; objs }
  let objs t = t.objs
  let cursor t = t.cursor

  let schema ?doc name =
    Graphql_lwt.Schema.(
      obj ?doc name
        ~fields:
          [
            field "cursor" ~typ:(non_null string)
              ~args:Arg.[]
              ~resolve:(fun _info (pagination : t) -> cursor pagination);
            field "objs"
              ~typ:(non_null (list (non_null T.schema)))
              ~args:Arg.[]
              ~resolve:(fun _info (pagination : t) -> objs pagination);
          ])
end
