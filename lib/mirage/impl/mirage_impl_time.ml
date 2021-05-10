open Functoria

type time = TIME

let time = Type.v TIME

let default_time = impl ~packages:[ package "mirage-time" ] "OS.Time" time
