let uppercase_first string =
  let first_char = String.get string 0 in
  String.make 1 (Char.uppercase_ascii first_char)
  ^ String.sub string 1 (String.length string - 1)

let to_pascal_case str =
  let r = ref "" in
  let capitalize = ref true in
  let is_all_uppercase = String.uppercase_ascii str = str in
  String.iter
    (fun c ->
      if c = '_' then capitalize := true
      else if !capitalize then (
        r := !r ^ String.make 1 (Char.uppercase_ascii c);
        capitalize := false)
      else
        r :=
          !r
          ^
          if is_all_uppercase then String.make 1 (Char.lowercase_ascii c)
          else String.make 1 c)
    str;
  !r

let to_camel_case str =
  let s = to_pascal_case str in
  String.make 1 (Char.lowercase_ascii (String.get s 0))
  ^ String.sub s 1 (String.length s - 1)

let to_snake_case str =
  let r = ref "" in
  let is_all_uppercase = String.uppercase_ascii str = str in
  for i = 0 to String.length str - 1 do
    let c = String.get str i in
    if i > 0 && Char.uppercase_ascii c = c && not is_all_uppercase then
      r := !r ^ "_";
    r := !r ^ String.make 1 (Char.lowercase_ascii c)
  done;
  !r
