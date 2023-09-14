let rec render_type (t : Types.t) ~type_namespace =
  match t with
  | TypeLiteral Str -> "string"
  | TypeLiteral I32 -> "number"
  | TypeLiteral U32 -> "number"
  | TypeLiteral F32 -> "number"
  | TypeLiteral F64 -> "number"
  | TypeLiteral Bool -> "boolean"
  | TypeLiteral Json -> "any"
  | TypeLiteral (TypeName n) -> type_namespace ^ n
  | Vec t -> Format.sprintf "%s[]" (render_type t ~type_namespace)
  | Option t -> render_type t ~type_namespace
  | Nullable t -> Format.sprintf "%s | null" (render_type t ~type_namespace)
  | Map { key_t; value_t } -> (
      match value_t with
      | Option _ ->
          Format.sprintf "{[key: %s]: %s | null}"
            (render_type key_t ~type_namespace)
            (render_type value_t ~type_namespace)
      | _ ->
          Format.sprintf "{[key: %s]: %s}"
            (render_type key_t ~type_namespace)
            (render_type value_t ~type_namespace))

let render_struct_field (f : Types.field) =
  match f.field_t with
  | Option t -> (
      match t with
      | Option _ ->
          Format.sprintf "%s?: %s | null" f.field_name
            (render_type f.field_t ~type_namespace:"")
      | _ ->
          Format.sprintf "%s?: %s" f.field_name
            (render_type f.field_t ~type_namespace:""))
  | _ ->
      Format.sprintf "%s: %s" f.field_name
        (render_type f.field_t ~type_namespace:"")

let gen_variant ~prefix (s : Types.struct_) =
  Format.sprintf "export type %s = {\n    type: \"%s\";\n    %s\n}"
    (prefix ^ s.struct_name) s.struct_name
    (String.concat ",\n    " (List.map render_struct_field s.fields))

let gen_struct (s : Types.struct_) =
  Format.sprintf "export type %s = {\n    type: \"%s\";\n    %s\n}"
    s.struct_name s.struct_name
    (String.concat ",\n    " (List.map render_struct_field s.fields))

let gen_type_declaration (decl : Types.type_declaration) ~type_namespace =
  match decl with
  | TypeAlias { name; t } ->
      Format.sprintf "export type %s = %s" name (render_type t ~type_namespace)
  | StructUnion { name; variants } ->
      let variant_names =
        List.map
          (fun (variant : Types.struct_) -> name ^ variant.struct_name)
          variants
      in
      let variant_declarations = List.map (gen_variant ~prefix:name) variants in
      Format.sprintf "export type %s = %s\n\n%s" name
        (String.concat " | " variant_names)
        (String.concat "\n\n" variant_declarations)
  | Struct s -> gen_struct s
  | StringEnum { name; options } ->
      Format.sprintf "export enum %sOptions {\n    %s\n}" name
        (String.concat ",\n    "
           (List.map (fun o -> Format.sprintf "%s = \"%s\"" o o) options))
  | IntEnum { name; options } ->
      Format.sprintf "export enum %sOptions {\n    %s\n}" name
        (String.concat ",\n    "
           (List.map (fun (o, i) -> Format.sprintf "%s = %d" o i) options))
