open Petrol
open Petrol.Postgres

exception BadRequest of string

let schema = Petrol.StaticSchema.init ()

module User = struct
  let users_table, Expr.[ id_field; public_facing_id_field; display_name_field ]
      =
    StaticSchema.declare_table schema ~name:"users"
      Schema.
        [
          field ~constraints:[ primary_key () ] "id" ~ty:Type.big_serial;
          field "public_facing_id" ~constraints:[ unique () ] ~ty:Type.text;
          field "display_name" ~ty:Type.text;
          (*field "data" ~ty:Type.json*)
        ]

  type t = { id : int64; public_facing_id : string; display_name : string }
end

module Conversation = struct
  let ( conversations_table,
        Expr.[ id_field; created_at_field; updated_at_field; data_field ] ) =
    StaticSchema.declare_table schema ~name:"conversation"
      Schema.
        [
          field ~constraints:[ primary_key () ] "id" ~ty:Type.big_serial;
          field "created_at" ~ty:Type.date;
          field "updated_at" ~ty:Type.date;
          field "data" ~ty:Type.text;
          (*field "data" ~ty:Type.json*)
        ]

  type t = {
    id : int64;
    created_at : Ptime.t;
    updated_at : Ptime.t;
    data : string;
  }

  module Participant = struct
    let ( participants_table,
          Expr.
            [
              conversation_id_field;
              user_id_field;
              created_at_field;
              updated_at_field;
            ] ) =
      StaticSchema.declare_table schema ~name:"conversation_participant"
        ~constraints:
          Schema.[ table_primary_key [ "conversation_id"; "user_id" ] ]
        Schema.
          [
            field "conversation_id" ~ty:Type.big_int;
            field "user_id" ~ty:Type.big_int;
            field "created_at" ~ty:Type.date;
            field "updated_at" ~ty:Type.date;
          ]

    type t = {
      conversation_id : int64;
      user_id : int64;
      created_at : Ptime.t;
      updated_at : Ptime.t;
    }
  end
end
