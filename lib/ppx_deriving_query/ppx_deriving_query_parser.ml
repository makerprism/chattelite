open Ppxlib
module List = ListLabels
open Ast_builder.Default

let rec get_type_name (ct : core_type) : string option =
  match ct.ptyp_desc with
  | Ptyp_constr ({ txt = Lident "option"; _ }, [arg_type]) ->
    (match get_type_name arg_type with
      | Some inner_name -> Some (inner_name)
      | None -> None)
  | Ptyp_constr ({ txt = Lident name; _ }, []) ->
    Some name
  | _ -> None

let is_option (ct : core_type) : bool =
match ct.ptyp_desc with
| Ptyp_constr ({ txt = Lident "option"; _ }, _) -> true
  | _ -> false 

let gen_decode_expr ~loc (ct: core_type) : expression =
  match get_type_name ct with
  | None -> failwith "type name not found"
  | Some name ->
    if name <> "string" then (
    if is_option ct then
      [%expr Option.map [%e evar ~loc (name ^ "_of_string")]]
    else 
      [%expr Option.map [%e evar ~loc (name ^ "_of_string")] |> Option.get ]
    )
    else [%expr (fun id -> id)]

let query_parser_impl acc (ld : label_declaration) =
  let loc = ld.pld_loc in
  [%expr
    let ([%p ppat_var ~loc ld.pld_name] : [%t ld.pld_type]) =
      try
        Dream.query req [%e estring ~loc ld.pld_name.txt ] |> [%e gen_decode_expr ~loc ld.pld_type]
      with _ -> 
        raise (Invalid_argument [%e estring ~loc ld.pld_name.txt ])
    in
    [%e acc]]

let generate_impl ~ctxt (_rec_flag, type_declarations) =
  let loc = Expansion_context.Deriver.derived_item_loc ctxt in
  List.map type_declarations ~f:(fun (td : type_declaration) ->
      match td with
      | {
       ptype_kind = Ptype_abstract | Ptype_variant _ | Ptype_open;
       ptype_loc;
       _;
      } ->
          let ext =
            Location.error_extensionf ~loc:ptype_loc
              "Cannot derive query parser for non record types"
          in
          [ Ast_builder.Default.pstr_extension ~loc ext [] ]
      | { ptype_kind = Ptype_record fields; _ } ->
          [%str
            let parse_query req =
              try
                Ok ([%e
                List.fold_left fields
                  ~init:
                    (pexp_record ~loc
                       ( List.map fields ~f:(fun (ld : label_declaration) ->
                             ({loc; txt = lident ld.pld_name.txt}, evar ~loc ld.pld_name.txt)) )
                             None)
                  ~f:query_parser_impl])
              with Invalid_argument field_name ->
                Error ("failed to decode '" ^ field_name ^ "' from query")
          ])
  |> List.concat

let generate_intf ~ctxt (_rec_flag, type_declarations) =
  let loc = Expansion_context.Deriver.derived_item_loc ctxt in
  List.map type_declarations ~f:(fun (td : type_declaration) ->
      match td with
      | {
       ptype_kind = Ptype_abstract | Ptype_variant _ | Ptype_open;
       ptype_loc;
       _;
      } ->
          let ext =
            Location.error_extensionf ~loc:ptype_loc
              "Cannot derive query parser for non record types"
          in
          [ Ast_builder.Default.psig_extension ~loc ext [] ]
      | { ptype_kind = Ptype_record _; ptype_name; _ } ->
          [%sig: val parse_query : Dream.request -> ([%t (ptyp_constr ~loc { loc; txt = lident ptype_name.txt } [])], string) result ])
  |> List.concat

let impl_generator = Deriving.Generator.V2.make_noarg generate_impl
let intf_generator = Deriving.Generator.V2.make_noarg generate_intf

let my_deriver =
  Deriving.add "query" ~str_type_decl:impl_generator
    ~sig_type_decl:intf_generator
