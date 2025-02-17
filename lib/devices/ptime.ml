open Functoria.DSL

type ptime = job

let ptime = Functoria.job
let no_ptime = impl "Mirage_runtime" ptime

let impl sublib =
  let packages =
    [ package ~min:"5.0.0" ~max:"6.0.0" ~sublibs:[ ""; sublib ] "mirage-ptime" ]
  in
  impl ~packages "Mirage_ptime" ptime

let default_ptime = if_impl Key.is_solo5 (impl "solo5") (impl "unix")
let mock_ptime = impl "mock"
