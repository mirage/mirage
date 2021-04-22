open Functoria
module Key = Mirage_key

(** A Mirage target: target consists in multiple backends grouped together. *)
module type TARGET = sig
  type t
  (** The type representing a specific backend in a target. *)

  val cast : Key.mode -> t
  (** Ensures the mode is a backend supported by this target. *)

  val dune : Info.t -> Dune.stanza list
  (** Dune rules to build the unikernel *)

  val configure : Info.t -> unit Action.t
  (** Configure-time actions. *)

  val build_context : ?build_dir:Fpath.t -> Info.t -> Dune.stanza list
  (** Generate build context configuration *)

  val context_name : Info.t -> string
  (** Dune context *)

  val packages : t -> package list
  (** The required packages to support this backend. *)

  val install : Info.t -> Install.t
  (** [install i] returns which files are installed in context [i]. *)
end
