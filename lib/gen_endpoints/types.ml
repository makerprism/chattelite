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
  output_body_type : route_params;
}

type post_route = {
  url_params : url_params;
  query_param_type : route_params;
  input_body_type : route_params;
  output_body_type : route_params;
  error_type : error_variant list option;
}

type delete_route = {
  url_params : url_params;
  output_body_type : route_params;
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
