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

need to set up a database connection string for PostgreSQL in `config.json`:

```
{
    "api_key": "YOU_MUST_SET_THIS",
    "client_jwt_secret": "YOU_MUST_SET_THIS",
    "database_url": "postgresql://postgres:test@127.0.0.1:5432/ocaml_api"
}
```