module type PaginationSig = sig
  type obj
  type t

  val create : next:string option -> prev:string option -> objs:obj list -> t
  val objs : t -> obj list
  val next : t -> string option
  val prev : t -> string option

  val schema :
    ?doc:string -> string -> (Context.t, t option) Graphql_lwt.Schema.typ
end

module Make (T : sig
  type t

  val schema : (Context.t, t option) Graphql_lwt.Schema.typ
end) : PaginationSig with type obj = T.t = struct
  type t = { next : string option; prev : string option; objs : T.t list }
  type obj = T.t

  let create ~next ~prev ~objs = { next; prev; objs }
  let objs t = t.objs
  let next t = t.next
  let prev t = t.prev

  let schema ?doc name =
    Graphql_lwt.Schema.(
      obj ?doc name
        ~fields:
          [
            field "next" ~typ:string
              ~args:Arg.[]
              ~resolve:(fun _info (pagination : t) -> next pagination);
            field "prev" ~typ:string
              ~args:Arg.[]
              ~resolve:(fun _info (pagination : t) -> prev pagination);
            field "objs"
              ~typ:(non_null (list (non_null T.schema)))
              ~args:Arg.[]
              ~resolve:(fun _info (pagination : t) -> objs pagination);
          ])
end
