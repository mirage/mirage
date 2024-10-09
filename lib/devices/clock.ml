open Functoria.DSL

type clock = job

let clock = Functoria.job
let no_clock = impl "Mirage_runtime" clock

let impl sublib =
  let packages =
    [ package ~min:"5.0.0" ~max:"6.0.0" ~sublibs:[ ""; sublib ] "mirage-clock" ]
  in
  impl ~packages "Mirage_clock" clock

let clock_unix = impl "unix"
let clock_solo5 = impl "solo5"
let default_clock = if_impl Key.is_solo5 clock_solo5 clock_unix
