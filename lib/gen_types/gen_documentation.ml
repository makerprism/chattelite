let rec render_type (t : Types.t) ~type_namespace =
  match t with
  | TypeLiteral Str -> "String"
  | TypeLiteral I32 -> "Integer"
  | TypeLiteral U32 -> "Integer"
  | TypeLiteral F32 -> "Float32"
  | TypeLiteral F64 -> "Float64"
  | TypeLiteral Bool -> "Boolearn"
  | TypeLiteral Unit -> "Unit"
  | TypeLiteral Json -> failwith "not implemented"
  | TypeLiteral (TypeName n) ->
      Format.sprintf "[%s](#%s)" (Utils.to_pascal_case n)
        (type_namespace ^ Utils.to_pascal_case n)
  | Vec t -> Format.sprintf "Array of (%s)" (render_type t ~type_namespace)
  | Option t -> Format.sprintf "Optional (%s)" (render_type t ~type_namespace)
  | Nullable t -> Format.sprintf "Nullable (%s)" (render_type t ~type_namespace)
  | Map { key_t = _; value_t = _ } -> failwith "not implemented"

let render_struct_field (f : Types.field) =
  Format.sprintf "|%s|%s|" f.field_name
    (render_type f.field_t ~type_namespace:"")

let gen_variant ~prefix (s : Types.struct_) =
  Format.sprintf "* %s\n%s\n" (prefix ^ s.struct_name)
    (String.concat "\n"
       ([ "|field_name|type|"; "|-|-|" ] @ List.map render_struct_field s.fields))

let deriving = function
  | [] -> ""
  | ppxes -> Format.sprintf " [@@@@deriving %s]" (String.concat ", " ppxes)

let linkable_anchor name = Format.sprintf "<a name=\"%s\">%s</a>" name name

let gen_type_documentation (decl : Types.type_declaration) ~type_namespace =
  match decl with
  | Types.TypeAlias { name; t } ->
      Format.sprintf "## %s\n\n  is an alias for %s"
        (linkable_anchor (Utils.to_pascal_case name))
        (render_type t ~type_namespace)
  | StructUnion { name; variants } ->
      let variants =
        List.map
          (fun (variant : Types.struct_) -> gen_variant ~prefix:name variant)
          variants
      in
      Format.sprintf "## %s\n\n  is one of these variants:\n%s"
        (linkable_anchor (Utils.to_pascal_case name))
        (String.concat "\n" variants)
  | Struct s ->
      Format.sprintf "## %s\n\nis a struct with these fields:\n%s"
        (linkable_anchor (Utils.to_pascal_case s.struct_name))
        (String.concat "\n"
           ([ "|name|type|"; "|-|-|" ] @ List.map render_struct_field s.fields))
  | StringEnum { name; options } ->
      Format.sprintf "## %s\n\nis a string enum with these options:\n%s"
        (linkable_anchor (Utils.to_pascal_case name))
        (String.concat "\n"
           ([ "|option|"; "|-|" ]
           @ List.map (fun o -> Format.sprintf "|%s|" o) options))
  | IntEnum { name = _; options = _ } -> failwith "not implemented"
