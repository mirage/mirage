open Functoria.DSL

type console

val console : console typ

val default_console : console impl

val custom_console : string -> console impl
