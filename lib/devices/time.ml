open Functoria.DSL

type time = TIME

let time = typ TIME

let default_time =
  let packages_v =
    Key.(if_ is_unix)
      [ package ~sublibs:["unix"] "mirage-time" ]
      [ package ~sublibs:["solo5"] "mirage-time" ]
  in
  impl ~packages_v "Mirage_time" time
