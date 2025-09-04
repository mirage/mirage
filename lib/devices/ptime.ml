open Functoria.DSL

type ptime = job

let ptime = Functoria.job
let no_ptime = impl "Mirage_runtime" ptime

let impl sublib =
  let packages =
    [ package ~min:"5.1.0" ~max:"6.0.0" ~sublibs:[ ""; sublib ] "mirage-ptime" ]
  in
  impl ~packages "Mirage_ptime" ptime

let default_ptime =
  if_impl Key.is_unix (impl "unix")
    (if_impl Key.is_unikraft (impl "unikraft") (impl "solo5"))

let mock_ptime = impl "mock"
