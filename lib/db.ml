open Petrol
open Petrol.Postgres

let schema = StaticSchema.init ()

let users_table, Expr.[ id_field; public_facing_id_field; display_name_field ] =
  StaticSchema.declare_table schema ~name:"users"
    Schema.
      [
        field
          ~constraints:[ primary_key ~auto_increment:true () ]
          "id" ~ty:Type.big_int;
        field "public_facing_id" ~constraints:[ unique () ] ~ty:Type.text;
        field "display_name" ~ty:Type.text;
        (*field "data" ~ty:Type.json*)
      ]

module User = struct
  type t = { id : int64; public_facing_id : string; display_name : string }
end

let insert_user ~public_facing_id:a ~display_name:n db =
  Query.insert ~table:users_table
    ~values:Expr.[ display_name_field := s n; public_facing_id_field := s a ]
  |> Request.make_zero |> Petrol.exec db

let get_user ~public_facing_id db =
  Query.select ~from:users_table
    Expr.[ id_field; display_name_field; public_facing_id_field ]
  |> Query.limit (Expr.i 1)
  |> Query.where Expr.(s public_facing_id = public_facing_id_field)
  |> Request.make_one |> Petrol.find db
  |> Lwt_result.map (fun (id, (display_name, (public_facing_id, ()))) ->
         User.{ id; display_name; public_facing_id })

let get_users ~limit db =
  Query.select ~from:users_table
    Expr.[ id_field; display_name_field; public_facing_id_field ]
  |> Query.limit (Expr.i limit)
  |> Request.make_many |> Petrol.collect_list db
  |> Lwt_result.map
       (List.map (fun (id, (display_name, (public_facing_id, ()))) ->
            User.{ id; display_name; public_facing_id }))
