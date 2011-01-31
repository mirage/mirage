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

type level =
  [ `debug
  | `warn
  | `info
  | `error ]

type logger =
  date       : string -> 
  id         : int    ->
  level      : level  ->
  section    : string ->
  ?backtrace : string ->
  message    : string ->
  unit

type named_logger = {
  name : string;
  fn   : logger;
}

let text_logger ~date ~id ~level ~section ?backtrace ~message =
  let backtrace = match backtrace with
    | None    -> "" 
    | Some bt -> Printf.sprintf "(backtrace: %s)" bt in
  let level = match level with
    | `debug -> "debug"
    | `warn  -> " warn"
    | `info  -> " info"
    | `error -> "error" in
  let all = Printf.sprintf "[%.5d] %s %s %.20s: %s %s" id date level section message backtrace in
  Printf.printf "%s\n%!" all

let text_logger_name =
  "Default text logger"

type state = {
  mutable readers  : named_logger list;
  mutable get_date : unit -> string;
  mutable get_id   : unit -> int;
}

let state = {
  readers  = [];
  get_date = (fun () -> "<not set>");
  get_id   = (fun () -> 0);
}

let broadcast ~level ~section ~message =
  let date = state.get_date () in
  let id   = state.get_id () in
  let backtrace =
    if Printexc.backtrace_status () then
      Some (Printexc.get_backtrace ())
    else
      None in
  List.iter (fun r -> r.fn ~date ~id ~level ~section ?backtrace ~message) state.readers

let add_logger name fn =
  if not (List.exists (fun r -> r.name = name) state.readers) then
    state.readers <- { name; fn } :: state.readers

let rm_logger name =
  state.readers <- List.filter (fun l -> l.name <> name) state.readers

let get_loggers () =
  List.map (fun r -> r.name) state.readers

let set_date date =
  state.get_date <- date

let set_id id =
  state.get_id <- id

let log ~level ~section fmt =
  let fn message =
    broadcast ~level ~section ~message in
  Printf.kprintf fn fmt

let debug section fmt = log ~level:`debug ~section fmt
let info  section fmt = log ~level:`info  ~section fmt
let warn  section fmt = log ~level:`warn  ~section fmt
let error section fmt = log ~level:`error ~section fmt

let _ =
  add_logger text_logger_name text_logger
