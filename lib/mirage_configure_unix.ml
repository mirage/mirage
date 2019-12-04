open Mirage_impl_misc

module Key = Mirage_key

let configure_unix ~name ~binary_location ~target =
  let target_name = Fmt.strf "%a" Key.pp_target target in
  let alias =
    sexp_of_fmt
      {sexp|
      (alias
        (name %s)
        (enabled_if (= %%{context_name} "default"))
        (deps %s))
      |sexp} target_name name in
  let libs =
    sexp_of_fmt
      {sexp|
      (rule
        (target libs.sexp)
        (action (with-stdout-to %%{target} (echo "(-thread)"))))
      |sexp} in
  let rule =
    sexp_of_fmt
      {sexp|
      (rule
        (target %s)
        (deps %s)
        (mode promote)
        (action (run ln -nfs %s %s)))
      |sexp} name binary_location binary_location name in
  Ok [ alias; libs; rule; ]
