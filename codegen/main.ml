let gen_typescript_bindings ~t ~it ~ot ~endpoints ~types_output_path
    ~endpoints_output_path ~type_namespace =
  let ts_bindings =
    Gen_endpoints.Gen_ts_bindings.gen_routes ~type_namespace endpoints
  in
  let ts_types =
    Gen_endpoints.Gen_ts_bindings.gen_types ~type_namespace ~t ~it ~ot
  in
  let oc = open_out types_output_path in
  Printf.fprintf oc "/* AUTOMATICALLY GENERATED BY codegen/main.ml */\n\n%s\n"
    ts_types;
  close_out oc;

  let oc = open_out endpoints_output_path in
  Printf.fprintf oc "/* AUTOMATICALLY GENERATED BY codegen/main.ml */\n\n%s"
    ts_bindings;
  close_out oc

let gen_ocaml_endpoints ~t ~it ~ot ~endpoints ~types_output_path
    ~endpoints_output_path ~type_namespace ~handler_namespace =
  let ocaml_types =
    Gen_endpoints.Gen_ocaml_endpoints.gen_types ~type_namespace:"" ~t ~it ~ot
      endpoints
  in
  let ocaml_endpoints =
    Gen_endpoints.Gen_ocaml_endpoints.gen_routes ~type_namespace
      ~handler_namespace endpoints
  in

  let oc = open_out endpoints_output_path in
  Printf.fprintf oc "(* AUTOMATICALLY GENERATED BY codegen/main.ml *)\n\n%s"
    ocaml_endpoints;
  close_out oc;

  let oc = open_out types_output_path in
  Printf.fprintf oc "(* AUTOMATICALLY GENERATED BY codegen/main.ml *)\n\n%s"
    ocaml_types;
  close_out oc

let gen_documentation ~t ~it ~ot ~endpoints ~output_path =
  let docs = Gen_endpoints.Gen_documentation.gen_docs ~t ~it ~ot endpoints in

  let oc = open_out output_path in
  Printf.fprintf oc "<!-- AUTOMATICALLY GENERATED BY codegen/main.ml -->\n\n%s"
    docs;
  close_out oc

let () =
  (* app side *)
  gen_ocaml_endpoints ~t:Server_types.t ~it:Server_types.it ~ot:Server_types.ot
    ~endpoints:Server_endpoints.endpoints
    ~types_output_path:"lib/api/generated_server_types.ml"
    ~endpoints_output_path:"lib/api/generated_server_endpoints.ml"
    ~type_namespace:"Generated_server_types."
    ~handler_namespace:"Handlers.Server.";

  gen_documentation ~t:Server_types.t ~it:Server_types.it ~ot:Server_types.ot
    ~endpoints:Server_endpoints.endpoints
    ~output_path:"api_documentation/server/README.md";

  (* client side*)
  gen_ocaml_endpoints ~t:Client_types.t ~it:Client_types.it ~ot:Client_types.ot
    ~endpoints:Client_endpoints.endpoints
    ~types_output_path:"lib/api/generated_client_types.ml"
    ~endpoints_output_path:"lib/api/generated_client_endpoints.ml"
    ~type_namespace:"Generated_client_types."
    ~handler_namespace:"Handlers.Client.";

  gen_documentation ~t:Client_types.t ~it:Client_types.it ~ot:Client_types.ot
    ~endpoints:Client_endpoints.endpoints
    ~output_path:"api_documentation/client/README.md";

  (* TypeScript sdk *)
  gen_typescript_bindings ~t:Server_types.t ~it:Server_types.it
    ~ot:Server_types.ot ~endpoints:Server_endpoints.endpoints ~type_namespace:""
    ~types_output_path:"sdks/TypeScript/server/src/generated/types.ts"
    ~endpoints_output_path:"sdks/TypeScript/server/src/generated/endpoints.ts";

  gen_typescript_bindings ~t:Server_types.t ~it:Server_types.it
    ~ot:Server_types.ot ~endpoints:Server_endpoints.endpoints ~type_namespace:""
    ~types_output_path:"sdks/TypeScript/client/src/generated/types.ts"
    ~endpoints_output_path:"sdks/TypeScript/client/src/generated/endpoints.ts"
