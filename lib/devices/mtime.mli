open Functoria.DSL

type mtime = job

val mtime : mtime typ
val default_mtime : mtime impl
val no_mtime : mtime impl
val mock_mtime : mtime impl
