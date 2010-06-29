(* Lightweight thread library for Objective Caml
 * http://www.ocsigen.org/lwt
 * Module Lwt_main
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

open Lwt

type current_time = float Lazy.t
type fd_set = unit list
type select = fd_set -> fd_set -> fd_set -> float option -> current_time * fd_set * fd_set * fd_set

external block_domain : float -> unit = "mirage_block_domain"

let select_filters = Lwt_sequence.create ()

let min_timeout a b = match a, b with
  | None, b -> b
  | a, None -> a
  | Some a, Some b -> Some(min a b)

let apply_filters select =
  let now = Lazy.lazy_from_fun Mir.gettimeofday in
  Lwt_sequence.fold_l (fun filter select -> filter now select) select_filters select

let default_select (set_r:fd_set) (set_w:fd_set) (set_e:fd_set) timeout : (current_time * fd_set * fd_set * fd_set) =
  let set_r, set_w, set_e =
    if (set_r = [] && set_w = [] && set_e = [] && timeout = Some 0.0) then
      (* If there is nothing to monitor and there is no timeout,
         save one system call: *)
      ([], [], [])
    else (
      (* XXX 10 second default timer for debugging for now *)
      block_domain (match timeout with None -> 10. |Some t -> t);
      ([], [], [])) in
  (Lazy.lazy_from_fun Mir.gettimeofday, set_r, set_w, set_e)

let default_iteration () =
  Lwt.wakeup_paused ();
  ignore (apply_filters default_select [] [] [] None)

let main_loop_iteration = ref default_iteration

let rec run t =
  Lwt.wakeup_paused ();
  match Lwt.poll t with
    | Some x ->
        x
    | None ->
        !main_loop_iteration ();
        run t

let exit_hooks = Lwt_sequence.create ()

let rec call_hooks () =
  match Lwt_sequence.take_opt_l exit_hooks with
    | None ->
        return ()
    | Some f ->
        lwt () =
          try_lwt
            f ()
          with exn ->
            return ()
        in
        call_hooks ()

let () = at_exit (fun () -> run (call_hooks ()))
let at_exit f = ignore (Lwt_sequence.add_l f exit_hooks)
