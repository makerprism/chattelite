let gen_code () =
  let ts =
    Types.
      [
        struct_union "Test"
          [
            struct_ "Success" [ field "id" (TypeLiteral Str) ];
            struct_ "Error" [ field "message" (TypeLiteral Str) ];
          ];
        struct_decl "NiceStruct" [ field "id" (TypeLiteral Str) ];
        string_enum "Entity" [ "Post"; "User"; "Message" ];
        (*int_enum "Cakes" [ ("Small", 1); ("Large", 2) ];*)
      ]
  in
  let result =
    List.map Gen_typescript.gen_type_declaration ts
    @ List.map Gen_ocaml.gen_type_declaration ts
  in
  print_endline (String.concat "\n\n" result)

let () = gen_code ()
