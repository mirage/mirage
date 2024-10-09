open Functoria.DSL

type time = job

let time = Functoria.job
let no_time = impl "Mirage_runtime" time

let impl sublib =
  let packages =
    [ package ~min:"4.0.0" ~max:"5.0.0" ~sublibs:[ ""; sublib ] "mirage-time" ]
  in
  impl ~packages "Mirage_time" time

let time_unix = impl "unix"
let time_solo5 = impl "solo5"
let default_time = if_impl Key.is_unix time_unix time_solo5
