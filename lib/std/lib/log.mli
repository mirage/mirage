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

(** {2 Loggers} *)

(** The level for log event *)
type level =
  [ `debug
  | `warn
  | `info
  | `error ]

(** Logger arguments *)
type logger =
  date       : string -> 
  id         : int    ->
  level      : level  ->
  section    : string ->
  ?backtrace : string ->
  message    : string ->
  unit

(** Add a named logger, which will be called on each new log event *)
val add_logger : string -> logger -> unit

(** Remove a named logger *)
val rm_logger : string -> unit

(** Get all the active loggers *)
val get_loggers : unit -> string list

(** Default logger : display all the result to stdout *)
val text_logger : logger

(** Name of the default text logger (usefull if one wants to uninstall it) *)
val text_logger_name : string

(** {2 Log functions} *)

val debug: string -> ('a, unit, string, unit) format4 -> 'a
val info : string -> ('a, unit, string, unit) format4 -> 'a
val warn : string -> ('a, unit, string, unit) format4 -> 'a
val error: string -> ('a, unit, string, unit) format4 -> 'a

(** {2 Date functions} *)

(** Hook to get the date (OS modules might init it) *)
val set_date : (unit -> string) -> unit

(** Hook to get the current thread's id *)
val set_id : (unit -> int) -> unit
