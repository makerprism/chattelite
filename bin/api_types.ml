(* API input and output types *)
module UserId = struct
  type t = string [@@deriving yojson]
end

module User = struct
  type t = {
    display_name: string;
    user_id: UserId.t
} [@@deriving yojson]
end

(* API input types *)


(* API output types *)
(* endpoint types *)
module CreateUserInput = struct
  type t = {
    display_name: string;
    user_id: UserId.t
} [@@deriving yojson]
end

module CreateUserOutput = struct
  type t = {
    user_id: UserId.t
} [@@deriving yojson]
end

module UsersQuery = struct
  type t = {
    name: (string) option;
    next: (string) option;
    prev: (string) option;
    limit: (int) option
} [@@deriving yojson]
end

module UsersOutput = struct
  type t = {
    users: (User.t) list
} [@@deriving yojson]
end



module GetUserOutput = struct
  type t = {
    user: User.t
} [@@deriving yojson]
end

