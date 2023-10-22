module TestClaims = struct
  type t = {
    iss : string;
    exp : Jwt.NumericTime.t;
    nbf : Jwt.NumericTime.t;
    is_root : bool; [@key "http://example.com/is_root"]
  }
  [@@deriving yojson]

  let check v = if v.iss = "joe" then Ok () else Error "Invalid issuer"
end

module TestJwt = Jwt.Make (Jwt.DefaultHeader) (TestClaims)

let test_claim =
  {
    TestClaims.iss = "joe";
    exp = Ptime.of_float_s 1300819380.0 |> Option.get;
    nbf = Ptime.of_float_s 1300819380.0 |> Option.get;
    is_root = true;
  }

let can_encode () =
  let header = Jwt.DefaultHeader.default () in
  let jwt =
    TestJwt.encode
      ~header:{ header with algorithm = Jwt.DefaultHeader.HS256 }
      ~secret:"secret" test_claim
  in
  Alcotest.(check bool) "can encode" true (Result.is_ok jwt)

let can_encode_and_decode () =
  let jwt = TestJwt.encode ~secret:"secret" test_claim in
  let decoded =
    TestJwt.decode ~unchecked:true ~secret:"secret" (Result.get_ok jwt)
  in
  Alcotest.(check bool)
    "can encode and decode" true
    (test_claim = (Result.get_ok decoded).claims)

let wrong_signature_fails () =
  let jwt = TestJwt.encode ~secret:"secret" test_claim in
  let decoded = TestJwt.decode ~secret:"secret" (Result.get_ok jwt ^ "nope") in
  Alcotest.(check string)
    "wrong signature fails to decode" "JWT signature is invalid!"
    (Result.get_error decoded)

let check_fails () =
  let jwt = TestJwt.encode ~secret:"secret" test_claim in
  let decoded = TestJwt.decode ~secret:"secret" (Result.get_ok jwt) in
  Alcotest.(check string)
    "expired token fails check" "Token has expired (now > exp)!"
    (Result.get_error decoded)

let () =
  can_encode ();
  can_encode_and_decode ();
  wrong_signature_fails ();
  check_fails ()
