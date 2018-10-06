(** Wrapper around [Bos] which provides a "dry run" feature. *)

(** {1 The job type} *)

(** An action that when executed may return a value of type ['a]. *)
type 'a t

(** An action that returns a value. *)
val return : 'a -> 'a t

(** Functor instance. *)
val map : f:('a -> 'b) -> 'a t -> 'b t

(** Monad instance. *)
val bind : f:('a -> 'b t) -> 'a t -> 'b t

module Infix : sig
  val (>>=) : 'a t -> ('a -> 'b t) -> 'b t
end

(** {1 Actions } *)

(** Delete a file. (see [Bos.OS.File.delete]) *)
val delete : Fpath.t -> unit t

(** Does a file exist? (see [Bos.OS.File.exists]) *)
val exists : Fpath.t -> bool t

(** Run a command. (see [Bos.OS.Cmd.run]) *)
val run_cmd : Bos.Cmd.t -> unit t

(** Write some data to a file. (see [Bos.OS.File.write]) *)
val write_file : Fpath.t -> string -> unit t

(** Open a file with a given mode, and write some data to it through a function.
    (see [Bos.OS.File.with_oc]). [purpose] is used in error messages. *)
val with_out :
  mode:int option ->
  path:Fpath.t ->
  purpose:string ->
  (Format.formatter -> 'a) ->
  'a t

(** {1 Interpreters} *)

(** Run the command through [Bos]. *)
val run : 'a t -> ('a, Rresult.R.msg) result

(** Emulate the action. This will not do IO on the actual files.
    Some approximation is done to determine the result of actions.
    [files] is a list of paths that are supposed to exist at the beginning.
    Returns:
    - the result of the action (which can be an [Bos] error)
    - the list of files after execution
    - a trace (list of log messages)
 *)
val dry_run :
  'a t ->
  files:Fpath.t list ->
  ('a, Rresult.R.msg) result * Fpath.t list * string list

(** Only output the trace part of [dry_run]. *)
val dry_run_trace :
  'a t ->
  files:Fpath.t list ->
  unit
