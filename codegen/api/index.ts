import * as rust from "./src/gen_rust_api";
import * as ts from "./src/gen_ts_bindings";
import * as go from "./src/gen_go_bindings";

rust.gen();
ts.gen();
go.gen();
