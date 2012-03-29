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
    validate : 'a -> bool Lwt.t;
    max : int;
    mutable count : int;
    list : 'a Queue.t;
    waiters : 'a Lwt.u Lwt_sequence.t }

let create m ?(check = fun _ f -> f true) ?(validate = fun _ -> return true) create =
  { max = m;
    create = create;
    validate = validate;
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

let release p c =
  try
    wakeup_later (Lwt_sequence.take_l p.waiters) c
  with Lwt_sequence.Empty ->
    Queue.push c p.list

let replace_acquired p =
  ignore_result (
    p.count <- p.count - 1;
    lwt c = create_member p in
    release p c;
    return ()
  )

let acquire p =
  if Queue.is_empty p.list then
    if p.count < p.max then
      create_member p
    else begin
      let waiter, wakener = task () in
      let node = Lwt_sequence.add_r wakener p.waiters in
      on_cancel waiter (fun () -> Lwt_sequence.remove node);
      waiter
    end
  else
    let c = Queue.take p.list in
    lwt valid =
      try_lwt
        p.validate c
      with e ->
        replace_acquired p;
        raise_lwt e
    in
    if valid then
      return c
    else begin
      p.count <- p.count - 1;
      create_member p
    end

let checked_release p c =
  p.check c begin fun ok ->
    if ok then
      release p c
    else
      replace_acquired p
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
