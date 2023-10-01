open Petrol
open Petrol.Postgres

exception BadRequest of string

let auto_increment_primary_key_col =
  Schema.(field ~constraints:[ primary_key () ] "id" ~ty:Type.big_serial)

let created_at_col = Schema.(field "created_at" ~ty:Type.date)
let updated_at_col = Schema.(field "updated_at" ~ty:Type.date)
let deleted_col = Schema.(field "deleted" ~ty:Type.bool)

let foreign_key_col ~table ~column name =
  Schema.(
    field
      ~constraints:[ foreign_key ~table ~columns:Expr.[ column ] () ]
      name ~ty:Type.big_int)

let schema = Petrol.StaticSchema.init ()

module User = struct
  let ( table,
        Expr.
          [
            id_field;
            created_at_field;
            updated_at_field;
            deleted_field;
            public_facing_id_field;
            display_name_field;
          ] ) =
    StaticSchema.declare_table schema ~name:"users"
      Schema.
        [
          auto_increment_primary_key_col;
          created_at_col;
          updated_at_col;
          deleted_col;
          field "public_facing_id" ~constraints:[ unique () ] ~ty:Type.text;
          field "display_name" ~ty:Type.text;
          (*field "data" ~ty:Type.json*)
        ]

  type t = { id : int64; public_facing_id : string; display_name : string }
end

module Conversation = struct
  let table, Expr.[ id_field; created_at_field; updated_at_field; data_field ] =
    StaticSchema.declare_table schema ~name:"conversation"
      Schema.
        [
          auto_increment_primary_key_col;
          created_at_col;
          updated_at_col;
          field "data" ~ty:Type.text;
          (*field "data" ~ty:Type.json*)
        ]

  type t = {
    id : int64;
    created_at : Ptime.t;
    updated_at : Ptime.t;
    data : string;
  }
end

module Participant = struct
  let ( table,
        Expr.
          [
            conversation_id_field;
            user_id_field;
            created_at_field;
            updated_at_field;
            lines_seen_until_field;
          ] ) =
    StaticSchema.declare_table schema ~name:"conversation_participant"
      ~constraints:Schema.[ table_primary_key [ "user_id"; "conversation_id" ] ]
      Schema.
        [
          foreign_key_col ~table:Conversation.table
            ~column:Conversation.id_field "conversation_id";
          foreign_key_col ~table:User.table ~column:User.id_field "user_id";
          created_at_col;
          updated_at_col;
          field "lines_seen_until" ~ty:Type.date;
        ]

  type t = {
    conversation_id : int64;
    user_id : int64;
    created_at : Ptime.t;
    updated_at : Ptime.t;
  }
end

module Line = struct
  let ( table,
        Expr.
          [
            id_field;
            created_at_field;
            updated_at_field;
            deleted_field;
            conversation_id_field;
            thread_line_id_field;
            reply_to_line_id_field;
            sender_user_id_field;
            message_field;
            data_field;
          ] ) =
    StaticSchema.declare_table schema ~name:"line"
      Schema.
        [
          auto_increment_primary_key_col;
          created_at_col;
          updated_at_col;
          deleted_col;
          foreign_key_col ~table:Conversation.table
            ~column:Conversation.id_field "conversation_id";
          field
            (*~constraints:
              [
                foreign_key ~table ~columns:Expr.[ Line.id_field ] ();
              ]*)
            "thread_line_id" ~ty:Type.big_int;
          field
            (*~constraints:
              [
                foreign_key ~table ~columns:Expr.[ Line.id_field ] ();
              ]*)
            "reply_to_line_id" ~ty:Type.big_int;
          foreign_key_col ~table:User.table ~column:User.id_field
            "sender_user_id";
          field "message" ~ty:Type.text;
          field "data" ~ty:Type.text;
        ]

  type t = {
    conversation_id : int64;
    user_id : int64;
    created_at : Ptime.t;
    updated_at : Ptime.t;
  }
end
