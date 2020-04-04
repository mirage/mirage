(*
 * Copyright (c) 2013-2020 Thomas Gazagnaire <thomas@gazagnaire.org>
 * Copyright (c) 2013-2020 Anil Madhavapeddy <anil@recoil.org>
 * Copyright (c) 2015-2020 Gabriel Radanne <drupyog@zoho.com>
 * Copyright (c) 2019-2020 Etienne Millon <etienne@tarides.com>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *)

(** Wrapper around [Bos] which provides a "dry run" feature. *)

(** {1 The action type} *)

type 'a t
(** An action that when executed may return a value of type ['a]. *)

val ok : 'a -> 'a t
(** An action that returns a value. *)

val error : string -> 'a t
(** [error e] is the failed action with error message [e]. *)

val errorf : ('a, Format.formatter, unit, 'b t) format4 -> 'a
(** [errorf fmt] is the failed action with error message [fmt]. *)

val map : f:('a -> 'b) -> 'a t -> 'b t
(** Functor instance. *)

val bind : f:('a -> 'b t) -> 'a t -> 'b t
(** Monad instance. *)

val seq : unit t list -> unit t
(** [seq t] runs the elements of [t] in sequence. *)

module List : sig
  val iter : f:('a -> unit t) -> 'a list -> unit t

  val map : f:('a -> 'b t) -> 'a list -> 'b list t
end

module Infix : sig
  val ( >>= ) : 'a t -> ('a -> 'b t) -> 'b t

  val ( >|= ) : 'a t -> ('a -> 'b) -> 'b t
end

(** {1 Actions} *)

val rm : Fpath.t -> unit t
(** Delete a file. (see [Bos.OS.File.delete]) *)

val mkdir : Fpath.t -> bool t
(** Create a directory. (See [Bos.OS.Dir.create] *)

val rmdir : Fpath.t -> unit t
(** Remove a directory. (see [Bos.OS.Dir.delete]) *)

val with_dir : Fpath.t -> (unit -> 'a t) -> 'a t
(** [with_dir d f] runs [f] with [d] as current working directory. (See
    [Bos.OS.Dir.with_current]). *)

val pwd : unit -> Fpath.t t
(** [pwd ()] is the current working directory. (See [Bos.OS.Dir.current]) *)

val is_file : Fpath.t -> bool t
(** Does a file exist? (see [Bos.OS.File.exists]) *)

val is_dir : Fpath.t -> bool t
(** Does a directory exist? (see [Bos.OS.Dir.exists]) *)

val size_of : Fpath.t -> int option t
(** [size_of f] is [Some i] if [f] exists and is of size [i], and [None] if [f]
    doesn't exist. *)

val set_var : string -> string option -> unit t
(** [set_var v c] sets env variable [c] to [c]. (see [Bos.OS.Env.set_var]) *)

val get_var : string -> string option t
(** [get_var v] gets the value of the variable [c] in the environment. (see
    [Bos.OS.Env.get]) *)

type channel = [ `Null | `Fmt of Format.formatter ]
(** The type for channels. *)

val run_cmd : ?err:channel -> ?out:channel -> Bos.Cmd.t -> unit t
(** Run a command. By default, [err] is [Fmt.stderr] and [out] is [Fmt.stdout].
    (see [Bos.OS.Cmd.run]) *)

val run_cmd_out : ?err:channel -> Bos.Cmd.t -> string t
(** Run a command and return stdout. By default [err] is [Fmt.stderr]. (See
    [Bos.OS.Cmd.run_out]) *)

val write_file : Fpath.t -> string -> unit t
(** Write some data to a file. (see [Bos.OS.File.write]) *)

val read_file : Fpath.t -> string t
(** [read_file f] is [f]'s contents. (see [Bos.OS.File.read]) *)

val tmp_file : ?mode:int -> Bos.OS.File.tmp_name_pat -> Fpath.t t
(** [tmp_file pat] is a tempory file built using the pattern [pat]. (See
    [Bos.OS.File.tmp]) *)

val ls : Fpath.t -> (Fpath.t -> bool) -> Fpath.t list t
(** [ls dir] is the list of files in [dir]. *)

val with_output :
  ?mode:int ->
  ?append:bool ->
  path:Fpath.t ->
  purpose:string ->
  (Format.formatter -> 'a) ->
  'a t
(** Open a file with a given mode, and write some data to it through a function.
    (see [Bos.OS.File.with_oc]). [purpose] is used in error messages. If
    [append] is set (by default it is not), the data is appended to [path]. *)

(** {1 Interpreters} *)

val run : 'a t -> ('a, Rresult.R.msg) result
(** Run the command through [Bos]. *)

type env
(** The type for virtual environments. *)

val eq_env : env -> env -> bool
(** [eq_env] is the equality function for virtual filesystems. *)

val pp_env : env Fmt.t
(** [pp_env] is the pretty-printer for virtual filesystems. *)

type files = [ `Passtrough of Fpath.t | `Files of (Fpath.t * string) list ]

val env :
  ?commands:(Bos.Cmd.t -> (string * string) option) ->
  ?env:(string * string) list ->
  ?pwd:Fpath.t ->
  ?files:files ->
  unit ->
  env

val dry_run : ?env:env -> 'a t -> ('a, Rresult.R.msg) result * env * string list
(** Emulate the action. This will not do IO on the actual files. Some
    approximation is done to determine the result of actions. [files] is a list
    of paths that are supposed to exist at the beginning. Returns:

    - the result of the action (which can be an [Bos] error)
    - the list of files after execution
    - a trace (list of log messages) *)

val dry_run_trace : ?env:env -> 'a t -> unit
(** Only output the trace part of [dry_run]. *)
