(*
 * Copyright (C) 2006-2009 Citrix Systems Inc.
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

type mmap_prot_flag = RDONLY | WRONLY | RDWR
type mmap_map_flag = SHARED | PRIVATE

(* mmap: fd -> prot_flag -> map_flag -> length -> offset -> interface *)
external mmap: Unix.file_descr -> mmap_prot_flag -> mmap_map_flag
		-> int -> int -> mmap_interface = "stub_mmap_init"
external unmap: mmap_interface -> unit = "stub_mmap_final"
(* read: interface -> start -> length -> data *)
external read: mmap_interface -> int -> int -> string = "stub_mmap_read"
(* write: interface -> data -> start -> length -> unit *)
external write: mmap_interface -> string -> int -> int -> unit = "stub_mmap_write"
(* getpagesize: unit -> size of page *)
external getpagesize: unit -> int = "stub_mmap_getpagesize"
