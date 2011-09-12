(*
  OCaml HTTP - do it yourself (fully OCaml) HTTP daemon

  Copyright (C) <2002-2005> Stefano Zacchiroli <zack@cs.unibo.it>
  Copyright (C) <2009-2011> Anil Madhavapeddy <anil@recoil.org>

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

type conn_id
val string_of_conn_id : conn_id -> string

type daemon_spec = {
  address : string;
  auth : Types.auth_info;
  callback :
    conn_id -> Request.request -> (Net.Channel.t -> unit Lwt.t) Lwt.t;
  conn_closed : conn_id -> unit;
  port : int;
  exn_handler : exn -> unit Lwt.t;
  timeout : float option;
}

val control_body : int -> string -> string
val respond_with : Response.response -> (Net.Channel.t -> unit Lwt.t) Lwt.t
val respond :
  ?body:string ->
  ?headers:(string * string) list ->
  ?version:Types.version ->
  ?status:Types.status_code -> unit -> (Net.Channel.t -> unit Lwt.t) Lwt.t
val respond_control :
  string ->
  ?is_valid_status:(int -> bool) ->
  ?headers:(string * string) list ->
  ?body:string ->
  ?version:Types.version ->
  Types.status_code -> (Net.Channel.t -> unit Lwt.t) Lwt.t
val respond_redirect :
  location:string ->
  ?body:string ->
  ?version:Types.version ->
  ?status:Types.status_code -> unit -> (Net.Channel.t -> unit Lwt.t) Lwt.t
val respond_error :
  ?body:string ->
  ?version:Types.version ->
  ?status:Types.status_code -> unit -> (Net.Channel.t -> unit Lwt.t) Lwt.t
val respond_not_found :
  url:'a ->
  ?version:Types.version -> unit -> (Net.Channel.t -> unit Lwt.t) Lwt.t
val respond_forbidden :
  url:'a ->
  ?version:Types.version -> unit -> (Net.Channel.t -> unit Lwt.t) Lwt.t
val respond_unauthorized :
  ?version:'a -> ?realm:string -> unit -> (Net.Channel.t -> unit Lwt.t) Lwt.t
val listen :
  Net.Manager.t ->
   [< `TCPv4 of Net.Nettypes.ipv4_src * daemon_spec ] ->
  unit Lwt.t

