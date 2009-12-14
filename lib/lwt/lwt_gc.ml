(* Lightweight thread library for Objective Caml
 * http://www.ocsigen.org/lwt
 * Module Lwt_gc
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

let ensure_termination t =
  if Lwt.state t = Lwt.Sleep then begin
    let hook = Lwt_sequence.add_l (fun _ -> t) Lwt_main.exit_hooks in
    (* Remove the hook when t has terminated *)
    ignore (try_lwt t finally Lwt_sequence.remove hook; Lwt.return ())
  end

let finaliser f x =
  ensure_termination (f x)

let finalise f = Gc.finalise (finaliser f)

(* Exit hook for a finalise_or_exit *)
let foe_exit f weak _ =
  match Weak.get weak 0 with
    | None ->
        (* The value has been garbage collected, normally this point
           is never reached *)
        Lwt.return ()
    | Some x ->
        (* Just to avoid double finalisation *)
        Weak.set weak 0 None;
        f x

(* Finaliser for a finalise_or_exit *)
let foe_finalise f hook weak x =
  (* Remove the exit hook, it is not needed anymore *)
  Lwt_sequence.remove hook;
  (* This should not be necessary, i am just paranoid: *)
  Weak.set weak 0 None;
  (* Finally call the real finaliser: *)
  finaliser f x

let finalise_or_exit f x =
  (* Create a weak pointer, so the exit-hook will prevent [x] from
     being garbage collected: *)
  let weak = Weak.create 1 in
  Weak.set weak 0 (Some x);
  let hook = Lwt_sequence.add_l (foe_exit f weak) Lwt_main.exit_hooks in
  Gc.finalise (foe_finalise f hook weak) x
