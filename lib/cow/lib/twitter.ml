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

open Lwt

(* XXX: no DNS client yet *)
let twitter = "http://128.242.245.244"

module User = struct
  
  type t = {
    id_str     : string;
    scree_name : string;
  } with json

end

module Status = struct

  type t = {
    id   : int;
    user : User.t;
    text : string;
  } with json

  type t_list =
      t list
  with json

  let user_timeline user =
    let uri = Printf.sprintf "%s/statuses/user_timeline/%s.json" twitter user in
    lwt _, body = Http.Client.post uri in
    let str = Json.of_string body in
    return (t_list_of_json str)

end

