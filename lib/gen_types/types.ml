type type_literal =
  | TypeName of string
  | Str
  | I32
  | U32
  | Bool
  | Json
  | F32
  | F64

type t =
  | TypeLiteral of type_literal
  | Nullable of t
  | Option of t
  | Vec of t
  | Map of { key_t : t; value_t : t }

type field = { field_name : string; field_t : t }
type struct_ = { struct_name : string; fields : field list }

type type_declaration =
  | TypeAlias of { name : string; t : t }
  | Struct of struct_
  | StringEnum of { name : string; options : string list }
  | IntEnum of { name : string; options : (string * int) list }
  | StructUnion of { name : string; variants : struct_ list }

let t name = TypeLiteral (TypeName name)

let u name =
  match name with
  | TypeLiteral (TypeName name) -> name
  | _ -> failwith "u takes a TypeLiteral (TypeName _)"

let alias name t =
  match name with
  | TypeLiteral (TypeName name) -> TypeAlias { name; t }
  | _ -> failwith "name on type alias must by a TypeLiteral (TypeName _)"

let field name t = { field_name = name; field_t = t }
let struct_ name fields = Struct { struct_name = name; fields }
let string_enum name options = StringEnum { name; options }
let int_enum name options = IntEnum { name; options }
let struct_union name variants = StructUnion { name; variants }
let struct_union_variant name fields = { struct_name = name; fields }
let str = TypeLiteral Str
let nullable t = Nullable t
let option t = Option t
let vec t = Vec t
let map k t = Map { key_t = k; value_t = t }
