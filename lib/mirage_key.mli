(*
 * Copyright (c) 2015 Nicolas Ojeda Bar <n.oje.bar@gmail.com>
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

(** Support for setting configuration parameters via the command-line.

    [Mirage_key] is used by the [Mirage] and [Main] modules to:

    - Construct [Cmdliner.Term.t]'s corresponding to used configuration keys in
      order to be able to set them at compile-time (see {!Main.configure}).

    - Generate a [bootvar.ml] file during configuration containing necessary
      code to do the same at run-time. *)

include module type of Mirage_runtime.Configvar

exception Illegal of string

val ocamlify : string -> string
(** [ocamlify s] returns a valid OCaml identifier from similar to [s].
    Concretely, [ocamlify s] is the string that results from removing all
    characters outside of ['a'-'z''A'-'Z''0''9''_''-'], and replacing '-' with
    '_'.  If the resulting string starts with a digit or is empty then it raises
    [Illegal s]. *)

type kval = V : 'a desc * 'a option ref -> kval
(** A type descritor together with an optional value of the type being
    described.  The value can potentially be set when running `mirage configure`
    with appropiate parameters. *)

type key =
  { doc : string;
    v : kval;
    name : string }
(** The type of configuration keys that can be set on the command-line. *)

type t = key

val name : key -> string
(** [name k] is just [ocamlify k.name].  Two keys [k1] and [k2] are considered
    equal if [name k1 = name k2]. *)

val term : key -> unit Cmdliner.Term.t
(** [term k] is a [Cmdliner.Term.t] that, when evaluated, sets the value of the
    the key [k]. *)

val create : ?doc:string -> ?default:'a -> string -> 'a desc -> key
(** [create ~doc ~default name desc] creates a new configuration key with
    docstring [doc], default value [default], name [name] and type descriptor
    [desc].  It is an error to use more than one key with the same [name]. *)

val compare : key -> key -> int
(** [compare k1 k2] is [compare (name k1) (name k2)]. *)

val print_ocaml : unit -> key -> string
(** [print_ocaml () k] returns a string [s] such that if [k.v] is [V (_, r)],
    then evaluating the contents of [s] will produce the value [!r]. *)

val print_meta : unit -> key -> string
(** [print_meta () k] returns a string [s] such that if [k.v] is [V (d, _)],
    then evaluating the contents of [s] will produce the value [d]. *)
