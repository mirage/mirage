(* Lightweight thread library for Objective Caml
 * http://www.ocsigen.org/lwt
 * Module Lwt_stream
 * Copyright (C) 2009 Jérémie Dimino
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as
 * published by the Free Software Foundation, with linking exceptions;
 * either version 2.1 of the License, or (at your option) any later
 * version. See COPYING file for details.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
 * 02111-1307, USA.
 *)

(** Data streams *)

type 'a t
  (** Type of a stream holding values of type ['a] *)

(** Naming convention: in this module all function taking a function
    which is applied to all element of the streams are suffixed by:

    - [_s] when the function returns a thread and calls are serialised
    - [_p] when the function returns a thread and calls are parallelised
*)

(** {6 Construction} *)

val from : (unit -> 'a option Lwt.t) -> 'a t
  (** [from f] creates an stream from the given input function. [f] is
      called each time more input is needed, and the stream ends when
      [f] returns [None]. *)

val create : unit -> 'a t * ('a option -> unit)
  (** [create ()] returns a new stream and a push function *)

val of_list : 'a list -> 'a t
  (** [of_list l] creates a stream returns all elements of [l] *)

val of_string : string -> char t
  (** [of_string str] creates a stream returning all characters of
      [str] *)

val clone : 'a t -> 'a t
  (** [clone st] clone the given stream. Operations on each stream
      will not affect the other.

      For example:

      {[
        # let st1 = Lwt_stream.of_list [1; 2; 3];;
        val st1 : int Lwt_stream.t = <abstr>
        # let st2 = Lwt_stream.clone st1;;
        val st2 : int Lwt_stream.t = <abstr>
        # lwt x = Lwt_stream.next st1;;
        val x : int = 1
        # lwt y = Lwt_stream.next st2;;
        val y : int = 1
      ]}
  *)

(** {6 Destruction} *)

val to_list : 'a t -> 'a list Lwt.t
  (** Returns the list of elements of the given stream *)

val to_string : char t -> string Lwt.t
  (** Returns the word composed of all characters of the given
      stream *)

(** {6 Data retreival} *)

exception Empty
  (** Exception raised when trying to retreive data from an empty
      stream. *)

val peek : 'a t -> 'a option Lwt.t
  (** [peek st] returns the first element of the stream, if any,
      without removing it. *)

val npeek : int -> 'a t -> 'a list Lwt.t
  (** [npeek n st] returns at most the first [n] elements of [st],
      without removing them. *)

val get : 'a t -> 'a option Lwt.t
  (** [get st] remove and returns the first element of the stream, if
      any. *)

val nget : int -> 'a t -> 'a list Lwt.t
  (** [nget n st] remove and returns at most the first [n] elements of
      [st]. *)

val get_while : ('a -> bool) -> 'a t -> 'a list Lwt.t
val get_while_s : ('a -> bool Lwt.t) -> 'a t -> 'a list Lwt.t
  (** [get_while f st] returns the longest prefix of [st] where all
      elements satisfy [f]. *)

val next : 'a t -> 'a Lwt.t
  (** [next st] remove and returns the next element of the stream, of
      fail with {!Empty} if the stream is empty. *)

val last_new : 'a t -> 'a Lwt.t
  (** [next_new st] if no element are available on [st] without
      sleeping, then it is the same as [next st]. Otherwise it removes
      all elements of [st] that are ready except the last one, and
      return it.

      If fails with {!Empty} if the stream has no more elements *)

val junk : 'a t -> unit Lwt.t
  (** [junk st] remove the first element of [st]. *)

val njunk : int -> 'a t -> unit Lwt.t
  (** [njunk n st] removes at most the first [n] elements of the
      stream. *)

val junk_while : ('a -> bool) -> 'a t -> unit Lwt.t
val junk_while_s : ('a -> bool Lwt.t) -> 'a t -> unit Lwt.t
  (** [junk_while f st] removes all elements at the beginning of the
      streams which satisfy [f]. *)

val junk_old : 'a t -> unit Lwt.t
  (** [junk_old st] removes all elements that are ready to be read
      without yeilding from [st].

      For example the [read_password] function of [Lwt_read_line] use
      that to junk key previously typed by the user.
  *)

val get_available : 'a t -> 'a list
  (** [get_available l] returns all available elements of [l] without
      blocking *)

val get_available_up_to : int -> 'a t -> 'a list
  (** [get_available_up_to l n] returns up to [n] elements of [l]
      without blocking *)

val is_empty : 'a t -> bool Lwt.t
  (** [is_empty enum] returns wether the given stream is empty *)

(** {6 Stream transversal} *)

(** Note: all the following functions are destructive.

    For example:

    {[
      # let st1 = Lwt_stream.of_list [1; 2; 3];;
      val st1 : int Lwt_stream.t = <abstr>
      # let st2 = Lwt_stream.map string_of_int st1;;
      val st2 : string Lwt_stream.t = <abstr>
      # lwt x = Lwt_stream.next st1;;
      val x : int = 1
      # lwt y = Lwt_stream.next st2;;
      val y : string = "2"
    ]}
*)

val choose : 'a t list -> 'a t
  (** [choose l] creates an stream from a list of streams. The
      resulting stream will returns elements returned by any stream of
      [l] in an unspecified order. *)

val map : ('a -> 'b) -> 'a t -> 'b t
val map_s : ('a -> 'b Lwt.t) -> 'a t -> 'b t
  (** [map f st] maps the value returned by [st] with [f] *)

val filter : ('a -> bool) -> 'a t -> 'a t
val filter_s : ('a -> bool Lwt.t) -> 'a t -> 'a t
  (** [filter f st] keeps only value [x] such that [f x] is [true] *)

val filter_map : ('a -> 'b option) -> 'a t -> 'b t
val filter_map_s : ('a -> 'b option Lwt.t) -> 'a t -> 'b t
  (** [filter_map f st] filter and map [st] at the same time *)

val map_list : ('a -> 'b list) -> 'a t -> 'b t
val map_list_s : ('a -> 'b list Lwt.t) -> 'a t -> 'b t
  (** [map_list f st] applies [f] on each element of [st] and flattens
      the lists returned *)

val fold : ('a -> 'b -> 'b) -> 'a t -> 'b -> 'b Lwt.t
val fold_s : ('a -> 'b -> 'b Lwt.t) -> 'a t -> 'b -> 'b Lwt.t
  (** [fold f s x] fold_like function for streams. *)

val iter : ('a -> unit) -> 'a t -> unit Lwt.t
val iter_p : ('a -> unit Lwt.t) -> 'a t -> unit Lwt.t
val iter_s : ('a -> unit Lwt.t) -> 'a t -> unit Lwt.t
  (** [iter f s] iterates over all elements of the stream *)

val find : ('a -> bool) -> 'a t -> 'a option Lwt.t
val find_s : ('a -> bool Lwt.t) -> 'a t -> 'a option Lwt.t
  (** [find f s] find an element in a stream. *)

val find_map : ('a -> 'b option) -> 'a t -> 'b option Lwt.t
val find_map_s : ('a -> 'b option Lwt.t) -> 'a t -> 'b option Lwt.t
  (** [find f s] find and map at the same time. *)

val combine : 'a t -> 'b t -> ('a * 'b) t
  (** [combine s1 s2] combine two streams. The stream will ends when
      the first stream ends. *)

val append : 'a t -> 'a t -> 'a t
  (** [append s1 s2] returns a stream which returns all elements of
      [s1], then all elements of [s2] *)

val concat : 'a t t -> 'a t
  (** [concat st] returns the concatenation of all streams of [st]. *)

val flatten : 'a list t -> 'a t
  (** [flatten st = map_list (fun l -> l) st] *)

(** {6 Parsing} *)

val parse : 'a t -> ('a t -> 'b Lwt.t) -> 'b Lwt.t
  (** [parse st f] parses [st] with [f]. If [f] raise an exception,
      [st] is restored to its previous state. *)

(** {6 Misc} *)

val hexdump : char t -> string t
  (** [hexdump byte_stream] returns a stream which is the same as the
      output of [hexdump -C].

      Basically, here is a simple implementation of [hexdump -C]:

      {[
        open Lwt
        open Lwt_io
        let () = Lwt_main.run (write_lines stdout (Lwt_stream.hexdump (read_lines stdin)))
      ]}
  *)
