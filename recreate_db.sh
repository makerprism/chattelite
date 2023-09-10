PGPASSWORD=test psql -h 127.0.0.1 -p 5432 -d postgres -U postgres -c 'DROP DATABASE ocaml_api'
PGPASSWORD=test psql -h 127.0.0.1 -p 5432 -d postgres -U postgres -c 'CREATE DATABASE ocaml_api'
opam exec -- dune exec migrations
