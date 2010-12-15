(* Lightweight thread library for Objective Caml
 * http://www.ocsigen.org/lwt
 * Module Lwt_switch
 * Copyright (C) 2010 Jérémie Dimino
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

exception Off

type on_switch = {
  mutable hooks : (unit -> unit Lwt.t) list;
}

type state =
  | St_on of on_switch
  | St_off

type t = { mutable state : state }

let create () = { state = St_on { hooks = [] } }

let is_on switch =
  match switch.state with
    | St_on _ -> true
    | St_off -> false

let check = function
  | Some{ state = St_off } -> raise Off
  | _ -> ()

let add_hook switch hook =
  match switch with
    | Some{ state = St_on os } ->
        os.hooks <- hook :: os.hooks
    | Some{ state = St_off } ->
        raise Off
    | None ->
        ()

let add_hook_or_exec switch hook =
  match switch with
    | Some{ state = St_on os } ->
        os.hooks <- hook :: os.hooks;
        return ()
    | Some{ state = St_off } ->
        hook ()
    | None ->
        return ()

let turn_off switch =
  match switch.state with
    | St_on { hooks = hooks } ->
        switch.state <- St_off;
        Lwt_list.iter_p (fun hook -> apply hook ()) hooks
    | St_off ->
        return ()
