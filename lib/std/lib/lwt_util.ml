(* Lightweight thread library for Objective Caml
 * http://www.ocsigen.org/lwt
 * Module Lwt_util
 * Copyright (C) 2005-2008 Jérôme Vouillon
 * Laboratoire PPS - CNRS Université Paris Diderot
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

open Lwt

let rec iter f l =
  let l = List.fold_left (fun acc a -> f a :: acc) [] l in
  let l = List.rev l in
  List.fold_left (fun rt t -> t >>= fun () -> rt) (Lwt.return ()) l

let rec iter_serial f l =
  match l with
    []     -> return ()
  | a :: r -> f a >>= (fun () -> iter_serial f r)

let rec map f l =
  match l with
    [] ->
      return []
  | v :: r ->
      let t = f v in
      let rt = map f r in
      t >>= (fun v' ->
      rt >>= (fun l' ->
      return (v' :: l')))

let map_with_waiting_action f wa l =
  let rec loop l =
    match l with
      [] ->
        return []
    | v :: r ->
        let t = f v in
        let rt = loop r in
        t >>= (fun v' ->
          (* Perform the specified "waiting action" for the next    *)
          (* item in the list.                                      *)
          if r <> [] then
            wa (List.hd r)
          else
            ();
          rt >>= (fun l' ->
            return (v' :: l')))
  in
  if l <> [] then
    wa (List.hd l)
  else
    ();
  loop l

let rec map_serial f l =
  match l with
    [] ->
      return []
  | v :: r ->
      f v >>= (fun v' ->
      map_serial f r >>= (fun l' ->
      return (v' :: l')))

let rec fold_left f a = function
  | [] -> return a
  | b::l -> f a b >>= fun v -> fold_left f v l

let join = Lwt.join

type region =
  { mutable size : int;
    mutable count : int;
    waiters : (unit Lwt.u * int) Queue.t }

let make_region count = { size = count; count = 0; waiters = Queue.create () }

let resize_region reg sz = reg.size <- sz

let leave_region reg sz =
   try
     if reg.count - sz >= reg.size then raise Queue.Empty;
     let (w, sz') = Queue.take reg.waiters in
     reg.count <- reg.count - sz + sz';
     Lwt.wakeup w ()
   with Queue.Empty ->
     reg.count <- reg.count - sz

let run_in_region_1 reg sz thr =
  (catch
     (fun () -> thr () >>= (fun v -> leave_region reg sz; return v))
     (fun e -> leave_region reg sz; fail e))

let run_in_region reg sz thr =
  if reg.count >= reg.size then begin
    let (res, w) = wait () in
    Queue.add (w, sz) reg.waiters;
    res >>= (fun () -> run_in_region_1 reg sz thr)
  end else begin
    reg.count <- reg.count + sz;
    run_in_region_1 reg sz thr
  end
