module TestClaims = struct
  type t = { claim : string } [@@deriving yojson]
end

module TestJwt = Jwt.Make (Jwt.DefaultHeader) (TestClaims)

let can_encode () =
  let jwt = TestJwt.encode ~secret:"secret" { TestClaims.claim = "test" } in
  Alcotest.(check bool) "can encode" true (Result.is_ok jwt)

let can_encode_and_decode () =
  let claims = { TestClaims.claim = "test" } in
  let jwt = TestJwt.encode ~secret:"secret" claims in
  let decoded = TestJwt.decode ~secret:"secret" ~jwt:(Result.get_ok jwt) in
  Alcotest.(check bool)
    "can encode and decode" true
    (claims = (Result.get_ok decoded).claims)

let () =
  can_encode ();
  can_encode_and_decode ()
