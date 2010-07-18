(*
 * Copyright (C) 2006-2009 Citrix Systems Inc.
 * Copyright (C) 2010 Anil Madhavapeddy <anil@recoil.org>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published
 * by the Free Software Foundation; version 2.1 only. with the special
 * exception on linking described in file LICENSE.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *)

type mmap_interface

external xenstore_init: unit -> mmap_interface = "stub_xenstore_init"
external xenstore_evtchn_port: unit -> int = "stub_xenstore_evtchn_port"
external xenstore_evtchn_notify: unit -> unit = "stub_xenstore_evtchn_notify"

let condition = 
    let port = xenstore_evtchn_port () in
    Lwt_mirage_main.Activations.register port
