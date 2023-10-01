# Chattelite

WIP rewriting the project in the main branch to OCaml

```
opam switch create . 5.0.0 --no-install

opam install . --deps-only

# codegen must be run from repository root because the output file paths are relative TODO: fix

opam exec -- dune exec codegen

opam exec -- dune exec migrations

opam exec -- dune exec api
```