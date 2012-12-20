(*
 * Copyright (c) 2011 Anil Madhavapeddy <anil@recoil.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *)

type id = string

type blkif = <
  id : string;
  destroy : unit;
  ppname : string;
  read_512: int64 -> int64 -> Cstruct.t Lwt_stream.t;
  write_page: int64 -> Io_page.t -> unit Lwt.t;
  sector_size : int;
  size: int64;
  readwrite: bool;
>

type kv_ro = <
  iter_s : (string -> unit Lwt.t) -> unit Lwt.t;
  read : string -> Cstruct.t Lwt_stream.t option Lwt.t;
  size : string -> int64 option Lwt.t 
>

type plug = {
  p_id: string;  (* ID of device to plug in *)
  p_dep_ids: string list; (* Dependent ids that must be plugged in *)
  p_cfg: (string * string) list; (* Configuration keys, provider-dependent *)
}

type entry = {
  provider : provider;
  id : string;
  depends : entry list;
  node : device;
}

and device =
  | Blkif of blkif
  | KV_RO of kv_ro

and provider = <
  create : deps:entry list -> cfg:(string*string) list -> id -> entry Lwt.t;
  id : string;
  plug : plug Lwt_mvar.t;
  unplug : id Lwt_mvar.t 
>

val new_provider : provider -> unit

val find : id -> entry Lwt.t
val find_blkif : id -> blkif option Lwt.t
val find_kv_ro : id -> kv_ro option Lwt.t

val with_blkif : id -> (blkif -> 'a Lwt.t) -> 'a Lwt.t
val with_kv_ro : id -> (kv_ro -> 'a Lwt.t) -> 'a Lwt.t

val listen : (id -> unit Lwt.t) -> unit Lwt.t
