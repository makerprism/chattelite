let rec render_type (t : Types.t) ~type_namespace =
  match t with
  | TypeLiteral Str -> "string"
  | TypeLiteral I32 -> "int"
  | TypeLiteral U32 -> "int"
  | TypeLiteral I63 -> "int"
  | TypeLiteral F32 -> "Float32.t"
  | TypeLiteral F64 -> "Float64.t"
  | TypeLiteral Bool -> "bool"
  | TypeLiteral Unit -> "unit"
  | TypeLiteral Json -> failwith "not implemented"
  | TypeLiteral (TypeName n) -> type_namespace ^ Utils.to_pascal_case n ^ ".t"
  | Vec t -> Format.sprintf "(%s) list" (render_type t ~type_namespace)
  | Option t -> Format.sprintf "(%s) option" (render_type t ~type_namespace)
  | Nullable t -> Format.sprintf "(%s) option" (render_type t ~type_namespace)
  | Map { key_t = _; value_t = _ } -> failwith "not implemented"

let render_struct_field (f : Types.field) =
  Format.sprintf "%s: %s" f.field_name
    (render_type f.field_t ~type_namespace:"")

let gen_variant ~prefix (s : Types.struct_) =
  Format.sprintf "%s of {\n  %s\n}\n" (prefix ^ s.struct_name)
    (String.concat ";\n  " (List.map render_struct_field s.fields))

let deriving = function
  | [] -> ""
  | ppxes -> Format.sprintf " [@@@@deriving %s]" (String.concat ", " ppxes)

let gen_type_declaration (decl : Types.type_declaration) ~type_namespace ~ppxes
    =
  match decl with
  | TypeAlias { name; t } ->
      Format.sprintf "module %s = struct\n  type t = %s%s\nend"
        (Utils.to_pascal_case name)
        (render_type t ~type_namespace)
        (deriving ppxes)
  | StructUnion { name; variants } ->
      let variant_names =
        List.map
          (fun (variant : Types.struct_) -> gen_variant ~prefix:name variant)
          variants
      in
      Format.sprintf "module %s = struct\n  type t =\n    | %s%s\nend"
        (Utils.to_pascal_case name)
        (String.concat "\n    | " variant_names)
        (deriving ppxes)
  | Struct s ->
      Format.sprintf "module %s = struct\n  type t = {\n    %s\n}%s\nend"
        (Utils.to_pascal_case s.struct_name)
        (String.concat ";\n    " (List.map render_struct_field s.fields))
        (deriving ppxes)
  | StringEnum { name; options } ->
      Format.sprintf "module %s = struct\n  type t = %s%s\nend"
        (Utils.to_pascal_case name)
        (String.concat "   | " options)
        (deriving ppxes)
  | IntEnum { name = _; options = _ } -> failwith "not implemented"
