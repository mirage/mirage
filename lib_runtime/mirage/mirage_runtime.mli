(*
 * Copyright (c) 2014 David Sheets <sheets@alum.mit.edu>
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

(** Mirage run-time utilities.

    {e Release %%VERSION%%} *)

(** {2 Log thresholds} *)

type log_threshold = [ `All | `Src of string ] * Logs.level
(** The type for log threshold. *)

val set_level : default:Logs.level -> log_threshold list -> unit
(** [set_level ~default l] set the log levels needed to have all of the log
    sources appearing in [l] be used. *)

module Arg : sig
  (** {2 Mirage command-line arguments} *)

  include module type of Functoria_runtime.Arg

  val make :
    (string -> ('a, [ `Msg of string ]) result) ->
    ('a -> string) ->
    'a Cmdliner.Arg.converter
  (** [make of_string pp] is the command-line argument converter using on
      [of_string] and [pp]. *)

  (** [S] is the signature used by {!of_module} to create a command-line
      argument converter. *)
  module type S = sig
    type t

    val of_string : string -> (t, [ `Msg of string ]) result

    val to_string : t -> string
  end

  val of_module : (module S with type t = 'a) -> 'a Cmdliner.Arg.converter
  (** [of module (module M)] creates a command-line argyument converter from a
      module satisfying the signature {!S}. *)

  (** {2 Mirage command-line argument converters} *)

  val ip : Ipaddr.t Cmdliner.Arg.converter
  (** [ip] converts IP address. *)

  val ipv4_address : Ipaddr.V4.t Cmdliner.Arg.converter
  (** [ipv4] converts an IPv4 address. *)

  val ipv4 : (Ipaddr.V4.Prefix.t * Ipaddr.V4.t) Cmdliner.Arg.converter
  (** [ipv4] converts ipv4/netmask to Ipaddr.V4.t * Ipaddr.V4.Prefix.t . *)

  val ipv6 : Ipaddr.V6.t Cmdliner.Arg.converter
  (** [ipv6]converts IPv6 address. *)

  val ipv6_prefix : Ipaddr.V6.Prefix.t Cmdliner.Arg.converter
  (**[ipv6_prefix] converts IPv6 prefixes. *)

  val log_threshold : log_threshold Cmdliner.Arg.converter
  (** [log_threshold] converts log reporter threshold. *)
end

include module type of Functoria_runtime with module Arg := Arg

(** {2 Registering scheduler hooks} *)

val at_exit : (unit -> unit Lwt.t) -> unit
(** [at_exit hook] registers [hook], which will be executed before the unikernel
    exits. The first hook registered will be executed last. *)

val at_enter_iter : (unit -> unit) -> unit
(** [at_enter_iter hook] registers [hook] to be executed at the beginning of
    each event loop iteration. The first hook registered will be executed last.

    If [hook] calls {!at_enter_iter} recursively, the new hook will run only on
    the next event loop iteration. *)

val at_leave_iter : (unit -> unit) -> unit
(** [at_leave_iter hook] registers [hook] to be executed at the end of each
    event loop iteration. See {!at_enter_iter} for details. *)

(** {2 Running hooks} *)

(** This is mainly for for developers implementing new targets. *)

val run_exit_hooks : unit -> unit Lwt.t
(** [run_exit_hooks ()] calls the sequence of hooks registered with {!at_exit}
    in sequence. *)

val run_enter_iter_hooks : unit -> unit
(** [run_enter_iter_hooks ()] calls the sequence of hooks registered with
    {!at_enter_iter} in sequence. *)

val run_leave_iter_hooks : unit -> unit
(** [run_leave_iter_hooks ()] call the sequence of hooks registered with
    {!at_leave_iter} in sequence. *)
