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
  date:string -> 
  level:level ->
  filename:string ->
  ?backtrace:string ->
  message:string ->
  unit

type named_logger = {
  name : string;
  fn   : logger;
}

let text_logger ~date ~level ~filename ?backtrace ~message =
  let backtrace = match backtrace with
    | None    -> "" 
    | Some bt -> Printf.sprintf "(backtrace: %s)" bt in
  let level = match level with
    | `debug -> "debug"
    | `warn  -> " warn"
    | `info  -> " info"
    | `error -> "error" in
  let all = Printf.sprintf "[%s] %s %.10s %s %s" date level filename message backtrace in
  Printf.printf "%s\n%!" all


type state = {
  mutable readers  : named_logger list;
  mutable get_date : unit -> string;
}

let state = {
  readers  = [];
  get_date = (fun () -> "<not set>");
}

let broadcast ~level ~filename ~message =
  let date = state.get_date () in
  let backtrace =
    if Printexc.backtrace_status () then
      Some (Printexc.get_backtrace ())
    else
      None in
  List.iter (fun r -> r.fn ~date ~level ~filename ?backtrace ~message) state.readers

let add_logger name fn =
  if not (List.exists (fun r -> r.name = name) state.readers) then
    state.readers <- { name; fn } :: state.readers

let rm_logger name =
  state.readers <- List.filter (fun l -> l.name <> name) state.readers

let get_loggers () =
  List.map (fun r -> r.name) state.readers

let set_date date =
  state.get_date <- date


let log ~level ~filename fmt =
  let fn message =
    broadcast ~level ~filename ~message in
  Printf.kprintf fn fmt

let debug ~filename fmt = log ~level:`debug ~filename fmt
let info  ~filename fmt = log ~level:`info  ~filename fmt
let warn  ~filename fmt = log ~level:`warn  ~filename fmt
let error ~filename fmt = log ~level:`error ~filename fmt
