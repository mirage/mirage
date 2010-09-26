(*pp camlp4o -I `ocamlfind query lwt.syntax` pa_lwt.cmo *)

(*
  OCaml HTTP - do it yourself (fully OCaml) HTTP daemon

  Copyright (C) <2002-2005> Stefano Zacchiroli <zack@cs.unibo.it>
  Copyright (C) <2009> Anil Madhavapeddy <anil@recoil.org>

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU Library General Public License as
  published by the Free Software Foundation, version 2.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU Library General Public License for more details.

  You should have received a copy of the GNU Library General Public
  License along with this program; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307
  USA
*)

open Cohttp
open Http_common
open Http_types
open Lwt

let backlog = 15

(* XXX: do something with the backlog *)
let simple ~sockaddr ~timeout callback =
  OS.Flow.listen (fun clisockaddr flow ->
    debug_print "accepted connection";
    let srvsockaddr = sockaddr in                     
    match timeout with
    | None    -> callback ~clisockaddr ~srvsockaddr flow
    | Some tm -> pick [ callback ~clisockaddr ~srvsockaddr flow; OS.Time.sleep tm ]
  ) sockaddr
