type mode := Key.mode

open Functoria

val dune : Info.t -> Dune.stanza list
(** Dune rules to build the unikernel *)

val configure : Info.t -> unit Action.t
(** Configure-time actions. *)

val build_context : Dune.stanza list
(** Generate build context configuration *)

val context_name : Info.t -> string
(** Dune context *)

val packages : mode -> package list
(** The required packages to support this backend. *)

val install : Info.t -> Install.t
(** [install i] returns which files are installed in context [i]. *)
