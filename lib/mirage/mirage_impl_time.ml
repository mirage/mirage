open Functoria

type time = TIME

let time = Type.v TIME

let default_time = impl "OS.Time" time
