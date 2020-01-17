open Functoria

type time = TIME

let time = Type TIME

let default_time = impl "OS.Time" time
