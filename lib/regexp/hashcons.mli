(*
 * hashcons: hash tables for hash consing
 * Copyright (C) 2000 Jean-Christophe FILLIATRE
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License version 2, as published by the Free Software Foundation.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *
 * See the GNU Library General Public License version 2 for more details
 * (enclosed in the file LGPL).
 *)

(* Hash tables for hash consing. Hash consed values are of the
  following type [hash_consed]. The field [tag] contains a unique integer (for
  values hash consed with the same table). The field [hkey] contains the hash
  key of the value (without modulo) for possible use in other hash tables (and
  internally when hash consing tables are resized). The field [node} contains
  the value itself. *)

type 'a hash_consed = {
  hkey : int;
  tag : int;
  node : 'a }

(* Functorial interface. *)

module type HashedType =
  sig
    type t
    val equal : t * t -> bool
    val hash : t -> int
  end

module type S =
  sig
    type key
    type t
    val create : int -> t
    val hashcons : t -> key -> key hash_consed
  end

module Make(H : HashedType) : (S with type key = H.t)
