(*
 * Copyright (C) 2010 Thomas Gazagnaire <thomas@gazagnaire.org>
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

module User : sig
  
  type t = {
    id_str     : string;
    screen_name : string;
  }

  val json_of_t : t -> Json.t
  val t_of_json : Json.t -> t

end

module Status : sig

  type t = {
    id   : int;
    user : User.t;
    text : string;
  }

  val json_of_t : t -> Json.t
  val t_of_json : Json.t -> t

  val json_of_t_list : t list -> Json.t
  val t_list_of_json : Json.t -> t list

(*  val user_timeline : Http.Rpc.TCPv4.mgr -> ?screen_name:string -> unit -> t list Lwt.t *)
end
