(lang dune 3.7)

(name api)

(generate_opam_files true)

(source
 (github username/reponame))

(authors "Author Name")

(maintainers "Maintainer Name")

(documentation https://url/to/documentation)

(package
 (name api)
 (synopsis "A short synopsis")
 (description "A longer description")
 (depends
  ocaml
  dune
  caqti-driver-postgresql
  petrol
  (dream (= "1.0.0~alpha5"))
  (yojson (= "2.0.2"))
  (ppx_yojson_conv (= "v0.15.1"))
  (lwt_ppx (= "2.1.0"))
  (graphql (= "0.14.0"))
  (graphql-lwt (= "0.14.0")))
 (tags
  (topics "to describe" your project)))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/dune-files.html#dune-project
