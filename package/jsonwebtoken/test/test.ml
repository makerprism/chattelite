module TestClaims = struct
  type t = {
    iss : string;
    exp : int;
    is_root : bool; [@key "http://example.com/is_root"]
  }
  [@@deriving yojson]

  let check _ = Ok ()
end

module TestJwt = Jwt.Make (Jwt.DefaultHeader) (TestClaims)

let test_claim = { TestClaims.iss = "joe"; exp = 1300819380; is_root = true }

let can_encode () =
  Alcotest.(check string)
    "test claim"
    "{\"iss\":\"joe\",\"exp\":1300819380,\"http://example.com/is_root\":true}"
    (Yojson.Safe.to_string (TestClaims.yojson_of_t test_claim));
  let header = Jwt.DefaultHeader.default () in
  let jwt =
    TestJwt.encode
      ~header:{ header with algorithm = Jwt.DefaultHeader.HS256 }
      ~secret:"secret" test_claim
  in
  Alcotest.(check string)
    "can encode"
    "eyJhbGdvcml0aG0iOlsiSFMyNTYiXSwidHlwIjpbIkpXVCJdfQ.eyJpc3MiOiJqb2UiLCJleHAiOjEzMDA4MTkzODAsImh0dHA6Ly9leGFtcGxlLmNvbS9pc19yb290Ijp0cnVlfQ.X9mFtZy9m--Yv9vh27seNlM7xEm2t1B-zEjvu_7JPSI"
    (Result.get_ok jwt)

let can_encode_and_decode () =
  let jwt = TestJwt.encode ~secret:"secret" test_claim in
  let decoded = TestJwt.decode ~secret:"secret" ~jwt:(Result.get_ok jwt) in
  Alcotest.(check bool)
    "can encode and decode" true
    (test_claim = (Result.get_ok decoded).claims)

let wrong_signature_fails () =
  let jwt = TestJwt.encode ~secret:"secret" test_claim in
  let decoded =
    TestJwt.decode ~secret:"secret" ~jwt:(Result.get_ok jwt ^ "nope")
  in
  Alcotest.(check string)
    "wrong signature fails to decode" "JWT signature is invalid!"
    (Result.get_error decoded)

let () =
  can_encode ();
  can_encode_and_decode ();
  wrong_signature_fails ()
