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

open Cow

type level =
  [ `debug
  | `warn
  | `info
  | `error ]
with json

type t = {
  date      : string;
  level     : level;
  filename  : string;
  message   : string;
  backtrace : string option;
} with json

let default = {
  date      = "-";
  level     = `error;
  filename  = "-";
  message   = "<not set>";
  backtrace = None;
}
  
let css = <:css<
  .debug {
    background-color: blue;
  }
  .warn {
    background-color: orange;
  }
  .info {
    background-color: green;
  }
  .error {
    background-color: red;
  }
  .message {
    color: blue;
  }
>>

type ring = {
  mutable init    : int;
  mutable current : int;
          size    : int;
          content : t array;
}

let make size = {
  init = 0;
  current = 0;
  size = size;
  content = Array.create size default;
}

let get r i =
  r.content.(i mod r.size)

let push r t =
  if (r.current + 1) mod r.size = r.init then
    (* The ring is full, need to overwrite it *)
    r.init    <- (r.init + 1) mod r.size;
  r.content.(r.current) <- t;
  r.current <- (r.current + 1) mod r.size

let state = make 128

let stream () =
  let accu = ref [] in
  for i = state.init to state.current do
    let str = Printf.sprintf "data: %s\nid: %i\n" (Json.to_string (json_of_t (get state i))) i in
    accu := str :: !accu
  done;
  String.concat "\n" (List.rev !accu)

let logger ~date ~level ~filename ?backtrace ~message =
  let t = {
    date;
    level;
    filename;
    message;
    backtrace;
  } in
  push state t

let () =
  Log.add_logger "remote JavaScript debugger" logger
