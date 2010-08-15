type console
exception Internal_error of string
val create : unit -> console
val create_additional_console : unit -> console Lwt.t
val sync_write : console -> string -> int -> int -> unit Lwt.t
val write : console -> string -> int -> int -> unit
