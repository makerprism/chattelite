let migrate () =
  let open Lwt_result.Syntax in
  let* conn =
    Caqti_lwt.connect
      (Uri.of_string "postgresql://postgres:test@127.0.0.1:5432/ocaml_api")
  in
  let* _ = Petrol.StaticSchema.initialise Api.Db.schema conn in
  Lwt.return (Ok ())

let () =
  let _ = Lwt_main.run (migrate ()) in
  ()
