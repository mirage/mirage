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
let twitter_ip = Net.Nettypes.ipv4_addr_of_tuple (168l,143l,162l,45l)
let twitter = "http://168.143.162.45"
module User = struct
  
  type t = {
    id_str     : string;
    screen_name : string;
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

(*
  let user_timeline mgr ?screen_name () =
    let filter = match screen_name with
      | Some n -> "?screen_name=" ^ n
      | None   -> "" in
    let req_url = Printf.sprintf "%s/1/statuses/user_timeline.json%s" twitter filter in
    let req_headers =
      ["Host", "api.twitter.com";
       "Connection", "keep-alive" ] in
    let req = { req_meth=`GET; req_url; req_headers; req_body=None } in
    lwt res = request mgr (twitter_ip,80) req in
    lwt body = OS.Istring.View.(ts_of_stream res.res_body >|= ts_to_string) in
    let str = Json.of_string body in
    return (t_list_of_json str)
*)
end

