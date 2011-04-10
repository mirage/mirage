(* Lwt
 * http://www.ocsigen.org
 * Copyright (C) 2008 Jérôme Vouillon
 * Laboratoire PPS - CNRS Université Paris Diderot
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, with linking exceptions;
 * either version 2.1 of the License, or (at your option) any later version.
 * See COPYING file for details.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 *)

open Lwt

(*
XXX Close after some timeout
...
*)

type 'a t =
  { create : unit -> 'a Lwt.t;
    check : 'a -> (bool -> unit) -> unit;
    max : int;
    mutable count : int;
    list : 'a Queue.t;
    waiters : 'a Lwt.u Lwt_sequence.t }

let create m ?(check = fun _ f -> f true) create =
  { max = m;
    create = create;
    check = check;
    count = 0;
    list = Queue.create ();
    waiters = Lwt_sequence.create () }

let create_member p =
  try_lwt
    p.count <- p.count + 1; (* must be done before p.create *)
    lwt mem = p.create () in
    return mem
  with exn ->
    (* create failed, so don't increment count *)
    p.count <- p.count - 1;
    raise_lwt exn

let acquire p =
  try
    return (Queue.take p.list)
  with Queue.Empty ->
    if p.count < p.max then
      create_member p
    else begin
      let waiter, wakener = task () in
      let node = Lwt_sequence.add_r wakener p.waiters in
      on_cancel waiter (fun () -> Lwt_sequence.remove node);
      waiter
    end

let release p c =
  try
    wakeup (Lwt_sequence.take_l p.waiters) c
  with Lwt_sequence.Empty ->
    Queue.push c p.list

let checked_release p c =
  p.check c begin fun ok ->
    if ok then
      release p c
    else
      ignore (p.count <- p.count - 1;
              lwt c = create_member p in
              release p c;
              return ())
  end

let use p f =
  lwt c = acquire p in
  try_lwt
    lwt r = f c in
    release p c;
    return r
  with e ->
    checked_release p c;
    raise_lwt e
