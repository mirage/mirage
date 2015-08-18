(*
 * Copyright (c) 2015 Gabriel Radanne <drupyog@zoho.com>
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

(** Runtime module for functoria-generated DSLs. *)

(** Runtime Key module.

    Contains the bare minimum to define keys and plug them in cmdliner. *)
module Key : sig

  (** A key containing a value of type 'a. *)
  type 'a t

  (** Create a new key. *)
  val create :
    doc:Cmdliner.Arg.info ->
    default:'a -> 'a Cmdliner.Arg.converter -> 'a t

  (** Get the value of a key. Will use the default value if no
      command line argument was provided. *)
  val get : 'a t -> 'a

  (** Derive a cmdliner term from a key. *)
  val term : 'a t -> unit Cmdliner.Term.t

end

(** [with_argv keys s argv] uses the given key terms to parse the given [argv].
    [s] is the name of the cmdline executable. *)
val with_argv : unit Cmdliner.Term.t list -> string -> string array -> unit Lwt.t

val with_kv :  unit Cmdliner.Term.t list -> string -> (string * string) list -> unit Lwt.t
(** [with_kv keys s kv] is equivalent to {!with_argv} but uses a [(key,value) list] instead of an array as input. *)
