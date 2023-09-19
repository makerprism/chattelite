let rec render_type (t : Types.t) ~type_namespace =
  match t with
  | TypeLiteral Str -> "string"
  | TypeLiteral I32 -> "int"
  | TypeLiteral U32 -> "int"
  | TypeLiteral F32 -> "Float32.t"
  | TypeLiteral F64 -> "Float64.t"
  | TypeLiteral Bool -> "bool"
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

let gen_type_declaration (decl : Types.type_declaration) ~type_namespace =
  match decl with
  | TypeAlias { name; t } ->
      Format.sprintf
        "module %s = struct\n  type t = %s [@@@@deriving yojson]\nend"
        (Utils.to_pascal_case name)
        (render_type t ~type_namespace)
  | StructUnion { name; variants } ->
      let variant_names =
        List.map
          (fun (variant : Types.struct_) -> gen_variant ~prefix:name variant)
          variants
      in
      Format.sprintf
        "module %s = struct\n  type t =\n    | %s [@@@@deriving yojson]\nend"
        (Utils.to_pascal_case name)
        (String.concat "\n    | " variant_names)
  | Struct s ->
      Format.sprintf
        "module %s = struct\n  type t = {\n    %s\n} [@@@@deriving yojson]\nend"
        (Utils.to_pascal_case s.struct_name)
        (String.concat ";\n    " (List.map render_struct_field s.fields))
  | StringEnum { name; options } ->
      Format.sprintf
        "module %s = struct\n  type t = %s [@@@@deriving yojson]\nend"
        (Utils.to_pascal_case name)
        (String.concat "   | " options)
  | IntEnum { name = _; options = _ } -> failwith "not implemented"
