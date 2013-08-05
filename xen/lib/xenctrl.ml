(* Memory barriers *)

external xen_mb : unit -> unit = "caml_memory_barrier" "noalloc"
external xen_rmb : unit -> unit = "caml_memory_barrier" "noalloc"
external xen_wmb : unit -> unit = "caml_write_memory_barrier" "noalloc"
