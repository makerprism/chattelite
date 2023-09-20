open Petrol
open Petrol.Postgres
include Db_schema.User

let insert ~public_facing_id:a ~display_name:n
    ((module DB : Caqti_lwt.CONNECTION) as db) =
  let q =
    Query.insert ~table:users_table
      ~values:Expr.[ display_name_field := s n; public_facing_id_field := s a ]
  in
  DB.with_transaction (fun () -> q |> Request.make_zero |> Petrol.exec db)

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

let get_many ~next ~prev ~limit db =
  let process_results r =
    let items =
      r
      |> List.map (fun (id, (display_name, (public_facing_id, ()))) ->
             { id; display_name; public_facing_id })
    in
    let prev_cursor =
      Utils.last r |> Option.map (fun (id, _) -> Int64.add id 1L)
    in
    let next_cursor = List.nth_opt r 0 |> Option.map (fun (id, _) -> id) in
    (items, prev_cursor, next_cursor)
  in

  let q =
    Query.select ~from:users_table
      Expr.[ id_field; display_name_field; public_facing_id_field ]
    |> Query.limit (Expr.i limit)
  in
  let q =
    match next with
    | None -> q
    | Some c -> q |> Query.where Expr.(id_field > vl ~ty:Type.big_int c)
  in
  let q =
    match prev with
    | None -> q
    | Some c -> q |> Query.where Expr.(id_field < vl ~ty:Type.big_int c)
  in

  q |> Request.make_many |> Petrol.collect_list db
  |> Lwt_result.map process_results

let get_many_by_ids ~(ids : int64 list) (module DB : Caqti_lwt.CONNECTION) =
  let open Lwt.Infix in
  let query =
    Caqti_request.create ~oneshot:true
      Caqti_type.(string)
      Caqti_type.(tup3 int64 string string)
      Caqti_mult.zero_or_more
      (fun _ ->
        Result.get_ok
        @@ Caqti_query.of_string
             "SELECT id, public_facing_id, display_name FROM users WHERE id IN \
              ($1)")
  in
  let ids = String.concat ", " (List.map Int64.to_string ids) in
  let open Lwt.Syntax in
  DB.collect_list query ids >>= function
  | Ok rows ->
      let* _ =
        Lwt_io.printlf "FOUND: %s"
          (String.concat ", "
             (List.map (fun (a, _, _) -> Int64.to_string a) rows))
      in

      Lwt_list.map_s
        (fun (id, public_facing_id, display_name) ->
          Lwt.return { id; public_facing_id; display_name })
        rows
  | Error err ->
      let* _ = Lwt_io.printlf "Error: %s" (Caqti_error.show err) in
      Lwt.return []
