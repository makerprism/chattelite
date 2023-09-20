(* type declarations *)

type type_declaration =
  | BasicTypeDecl of Gen_types.Types.type_declaration
  | IdType of string
(*  | Cursor of *)

(* Generic types from Gen_types *)

include Gen_types.Types.TypeDeclarations

let alias n t = BasicTypeDecl (Gen_types.Types.alias n t)
let struct_ n f = BasicTypeDecl (Gen_types.Types.struct_ n f)

let string_enum n options =
  BasicTypeDecl (Gen_types.Types.string_enum n options)

let int_enum n options = BasicTypeDecl (Gen_types.Types.int_enum n options)
let struct_union n v = BasicTypeDecl (Gen_types.Types.struct_union n v)

(* Types specific to this API *)

let id_type name = IdType name

(* route types *)
type method_ = Get | Post | Delete
type url_param = { name : string; t : Gen_types.Types.t }
type url_params = url_param list option

type error_variant = {
  variant : Gen_types.Types.struct_;
  status_code : int;
  title : string;
}

type route_params =
  | Fields of Gen_types.Types.field list
  | Structs of Gen_types.Types.struct_ list
  | None

type get_route = {
  url_params : url_params;
  query_param_type : route_params;
  output_type : route_params;
}

type post_route = {
  url_params : url_params;
  query_param_type : route_params;
  input_type : route_params;
  output_type : route_params;
  error_type : error_variant list option;
}

type delete_route = {
  url_params : url_params;
  output_type : route_params;
  error_type : error_variant list option;
}

type route_shape =
  | Get of get_route
  | Post of post_route
  | Delete of delete_route

type route = {
  name : string;
  url : string;
  docstring : string;
  shape : route_shape;
}
