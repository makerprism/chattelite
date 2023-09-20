let migrate () =
  let open Lwt.Syntax in
  let* conn_or_fail =
    Caqti_lwt.connect
      (Uri.of_string "postgresql://postgres:test@127.0.0.1:5432/ocaml_api")
  in
  let* conn = Caqti_lwt.or_fail conn_or_fail in
  let* init_or_fail = Petrol.StaticSchema.initialise Db.Db_schema.schema conn in
  let* _ = Caqti_lwt.or_fail init_or_fail in
  Lwt.return (Ok ())

let () =
  let _ = Lwt_main.run (migrate ()) in
  ()
