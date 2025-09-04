open Functoria.DSL

type mtime = job

let mtime = Functoria.job
let no_mtime = impl "Mirage_runtime" mtime

let impl sublib =
  let packages =
    [ package ~min:"5.2.0" ~max:"6.0.0" ~sublibs:[ ""; sublib ] "mirage-mtime" ]
  in
  impl ~packages "Mirage_mtime" mtime

let default_mtime =
  if_impl Key.is_unix (impl "unix")
    (if_impl Key.is_unikraft (impl "unikraft") (impl "solo5"))

let mock_mtime = impl "mock"
