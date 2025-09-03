open Functoria.DSL

type sleep = job

let sleep = Functoria.job
let no_sleep = impl "Mirage_runtime" sleep

let impl sublib =
  let packages =
    [ package ~min:"4.1.0" ~max:"5.0.0" ~sublibs:[ ""; sublib ] "mirage-sleep" ]
  in
  impl ~packages "Mirage_sleep" sleep

let default_sleep =
  if_impl Key.is_unix (impl "unix")
    (if_impl Key.is_unikraft (impl "unikraft") (impl "solo5"))
