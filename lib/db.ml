open Petrol
open Petrol.Postgres

let rec last = function [] -> None | [ x ] -> Some x | _ :: tail -> last tail
let schema = StaticSchema.init ()

module User = struct
  let users_table, Expr.[ id_field; public_facing_id_field; display_name_field ]
      =
    StaticSchema.declare_table schema ~name:"users"
      Schema.
        [
          field ~constraints:[ primary_key () ] "id" ~ty:Type.big_serial;
          field "public_facing_id" ~constraints:[ unique () ] ~ty:Type.text;
          field "display_name" ~ty:Type.text;
          (*field "data" ~ty:Type.json*)
        ]

  type t = { id : int64; public_facing_id : string; display_name : string }

  let insert ~public_facing_id:a ~display_name:n ((module DB: Caqti_lwt.CONNECTION) as db) =
    let q =
      Query.insert ~table:users_table
        ~values:
          Expr.[ display_name_field := s n; public_facing_id_field := s a ]
    in
    DB.with_transaction begin fun () ->
      q |> Request.make_zero |> Petrol.exec db
    end

  let get_one ~public_facing_id db =
    let q =
      Query.select ~from:users_table
        Expr.[ id_field; display_name_field; public_facing_id_field ]
      |> Query.limit (Expr.i 1)
      |> Query.where Expr.(s public_facing_id = public_facing_id_field)
    in
    q |> Request.make_one |> Petrol.find db
    |> Lwt_result.map (fun (id, (display_name, (public_facing_id, ()))) ->
           { id; display_name; public_facing_id })

  let get_many ~cursor ~limit db =
    let process_results r =
      let items =
        r
        |> List.map (fun (id, (display_name, (public_facing_id, ()))) ->
               { id; display_name; public_facing_id })
      in
      let prev_cursor =
        last r |> Option.map (fun (id, _) -> Int64.to_string (Int64.add id 1L))
      in
      let next_cursor =
        List.nth_opt r 0 |> Option.map (fun (id, _) -> Int64.to_string id)
      in
      (items, prev_cursor, next_cursor)
    in

    let q =
      Query.select ~from:users_table
        Expr.[ id_field; display_name_field; public_facing_id_field ]
      |> Query.limit (Expr.i limit)
    in
    let q =
      match cursor with
      | None -> q
      | Some c ->
          q
          |> Query.where
               Expr.(id_field >= vl ~ty:Type.big_int (Int64.of_string c))
    in

    q |> Request.make_many |> Petrol.collect_list db
    |> Lwt_result.map process_results
end
