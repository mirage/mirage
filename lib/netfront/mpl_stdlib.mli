(*
 * Copyright (c) 2005 Anil Madhavapeddy <anil@recoil.org>
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
 *
 * $Id: mpl_stdlib.mli,v 1.5 2006/03/14 19:39:56 avsm Exp $
 *)

module Tree :
  sig
    type t = [ `Leaf of string * string | `Tree of string * t list ]
    val print : t -> unit
  end

exception IO_error
exception Buffer_overflow

type env
type frag
type data = [ `Str of string | `Sub of env -> unit | `Frag of frag | `None]

val new_env : ?fillfn:(string -> int -> int -> int) -> ?length:int -> string -> env

val string_of_env : env -> string
val string_of_full_env : env -> string

val fill : ?min:int -> env -> Unix.file_descr -> unit
val fill_string : env -> string -> unit
val reset : env -> unit
val size : env -> int
val total_size : env -> int
val skip : env -> int -> unit
val curpos : env -> int
val curbase : env -> int
val env_at : env -> int -> int -> env
val env_pos : env -> int -> env
val env_recv_fn : env -> (string -> int -> int -> int * 'a) -> 'a
val env_send_fn : env -> (string -> int -> int -> 'a) -> 'a
val env_fn : env -> (string -> int -> int -> 'a) -> 'a
val remaining : env -> int
val flush : env -> Unix.file_descr -> unit
val sendto : env -> Unix.file_descr -> Unix.sockaddr -> unit
val recvfrom : env -> Unix.file_descr -> Unix.msg_flag list -> Unix.sockaddr

type fillfn = string -> int -> int -> int
val set_fillfn : env -> fillfn -> unit
val default_fillfn : env -> unit

(* default to big endian (network endian) *)
val set_little_endian : unit -> unit
val set_big_endian : unit -> unit
val set_network_endian : unit -> unit

module Mpl_byte :
  sig
    type t
    val unmarshal : env -> t
    val marshal : env -> t -> unit
    val at : env -> int -> t
    val to_char : t -> char
    val of_char : char -> t
    val to_int : t -> int
    val of_int : int -> t
  end
module Mpl_uint16 :
  sig
    type t
    val unmarshal : env -> t
    val marshal : env -> t -> unit
    val at : env -> int -> t
    val of_int : int -> t
    val to_int : t -> int
    val dissect : ('a -> int -> 'a) -> 'a -> env -> 'a
  end
module Mpl_uint32 :
  sig
    type t
    val unmarshal : env -> t
    val marshal : env -> t -> unit
    val at : env -> int -> t
    val to_int32 : t -> int32
    val of_int : int -> t
    val of_int32 : int32 -> t
    val to_int : t -> int
  end
module Mpl_uint64 :
  sig
    type t
    val unmarshal : env -> t
    val marshal : env -> t -> unit
    val at : env -> int -> t
    val to_int64 : t -> int64
    val of_int64 : int64 -> t
    val of_int : int -> t
    val to_int : t -> int
  end
module Mpl_raw :
  sig
    val marshal : env -> string -> unit
    val frag : env -> int -> int -> frag
    val total_frag : env -> frag
    val frag_length : frag -> int
    val at : env -> int -> int -> string
    val blit : env -> frag -> unit
    val prettyprint : string -> string
  end
val dump_env : env -> unit

exception Bad_dns_label
module Mpl_dns_label :
  sig
    type t
	 val init_marshal : env -> unit
	 val init_unmarshal : env -> unit
     val of_string_list : ?comp:bool -> string list -> t
	 val to_string_list : t -> string list
	 val marshal : ?comp:bool -> env -> t -> t
     val unmarshal : env -> t
     val size : t -> int
	 val prettyprint : string list -> string
  end
module Mpl_string32 :
  sig
    type t
    val size : t -> int
    val unmarshal : env -> t
    val to_string : t -> string
    val of_string : string -> t
    val marshal : env -> t -> t
    val prettyprint : string -> string
  end
module Mpl_string8 :
  sig
    type t
    val size : t -> int
    val unmarshal : env -> t
    val to_string : t -> string
    val of_string : string -> t
    val marshal : env -> t -> t
    val prettyprint : string -> string
  end
module Mpl_boolean :
  sig
    type t
    val unmarshal : env -> t
    val to_bool : t -> bool
    val of_bool : bool -> t
    val marshal : env -> t -> t
    val prettyprint : bool -> string
  end
module Mpl_mpint :
  sig
    type t
    val size : t -> int
    val unmarshal : env -> t
    val of_string : string -> t
    val to_string : t -> string
    val marshal : env -> t -> t
    val prettyprint : t -> string
    val bytes : t -> int
    val bits : t -> int
  end
