open Petrol
open Petrol.Postgres
include Db_schema.Conversation

let insert ~(data : string) ((module DB : Caqti_lwt.CONNECTION) as db) =
  let now = Ptime_clock.now () in
  let q =
    Query.insert ~table
      ~values:
        Expr.
          [
            data_field := s data;
            created_at_field := vl ~ty:Type.date now;
            updated_at_field := vl ~ty:Type.date now;
          ]
  in
  DB.with_transaction (fun () -> q |> Request.make_zero |> Petrol.exec db)

let get_one ~id db =
  let q =
    Query.select ~from:table
      Expr.[ id_field; created_at_field; updated_at_field; data_field ]
    |> Query.limit (Expr.i 1)
    |> Query.where Expr.(id = id_field)
  in
  q |> Request.make_one |> Petrol.find db
  |> Lwt_result.map (fun (id, (created_at, (updated_at, (data, ())))) ->
         { id; created_at; updated_at; data })

let get_many ~next ~prev ~limit db =
  let process_results r =
    let items =
      r
      |> List.map (fun (id, (created_at, (updated_at, (data, ())))) ->
             { id; created_at; updated_at; data })
    in
    let prev_cursor =
      Utils.last r |> Option.map (fun (id, _) -> Int64.add id 1L)
    in
    let next_cursor = List.nth_opt r 0 |> Option.map (fun (id, _) -> id) in
    (items, prev_cursor, next_cursor)
  in

  let q =
    Query.select ~from:table
      Expr.[ id_field; created_at_field; updated_at_field; data_field ]
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

module Participant = struct
  include Db_schema.Participant

  let insert ~conversation_id ~user_id
      ((module DB : Caqti_lwt.CONNECTION) as db) =
    let now = Ptime_clock.now () in
    let q =
      Query.insert ~table
        ~values:
          Expr.
            [
              conversation_id_field := vl ~ty:Type.big_int conversation_id;
              user_id_field := vl ~ty:Type.big_int user_id;
              created_at_field := vl ~ty:Type.date now;
              updated_at_field := vl ~ty:Type.date now;
            ]
    in
    DB.with_transaction (fun () -> q |> Request.make_zero |> Petrol.exec db)

  let get_many ~conversation_id ~next ~prev ~limit db =
    let open Lwt.Syntax in
    let process_results (r : (int64 * unit) list) =
      let* items =
        User.get_many_by_ids ~ids:(List.map (fun (x, _) -> x) r) db
      in
      let prev_cursor =
        Utils.last r
        |> Option.map (fun (id, _) -> Int64.to_string (Int64.add id 1L))
      in
      let next_cursor =
        List.nth_opt r 0 |> Option.map (fun (id, _) -> Int64.to_string id)
      in
      let* _ =
        Lwt_io.printlf "Results: %s"
          (String.concat ", " (List.map (fun (a, _) -> Int64.to_string a) r))
      in

      Lwt.return (items, prev_cursor, next_cursor)
    in

    let q =
      Query.select ~from:table Expr.[ user_id_field ]
      |> Query.where
           Expr.(conversation_id_field = vl ~ty:Type.big_int conversation_id)
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
end
