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

open Lwt
open Printf

type id = string

(** Block devices (read/write sectors *)
type blkif = <
  id: string;
  read_512: int64 -> int64 -> Io_page.t Lwt_stream.t;
  write_page: int64 -> Io_page.t -> unit Lwt.t;
  sector_size: int;
  size: int64;
  readwrite: bool;
  ppname: string;
  destroy: unit;
>

(** Key/value read-only *)
type kv_ro = <
  iter_s: (string -> unit Lwt.t) -> unit Lwt.t;
  read: string -> Io_page.t Lwt_stream.t option Lwt.t;
  size: string -> int64 option Lwt.t;
>

type plug = {
  p_id: string;  (* ID of device to plug in *)
  p_dep_ids: string list; (* Dependent ids that must be plugged in *)
  p_cfg: (string * string) list; (* Configuration keys, provider-dependent *)
}

(** An individual entry in the device tree *)
type entry = {
  provider: provider;    (* Provider that created this entry *)
  id: string;            (* Unique ID for this device *)
  depends: entry list;   (* Dependencies that this device uses *)
  node: device;          (* The device itself *)
}

(** A concrete device, or a holding slot for threads waiting for it *)
and device = 
|Blkif of blkif
|KV_RO of kv_ro

(** A provider listens for new device ids, and create/destroy them *)
and provider = <
  id: string;             (* Human-readable name of provider *)
  create: deps:entry list -> cfg:(string * string) list -> id -> entry Lwt.t; (* Create a device from an id *)
  plug: plug Lwt_mvar.t;    (* Read this mvar when new devices show up *)
  unplug: id Lwt_mvar.t;  (* Read this mvar for when devices are unplugged *)
>

(** Track all the devices in the system *)
let device_tree: (id, entry) Hashtbl.t = Hashtbl.create 1
(** Track all the threads waiting for a device *)
let device_waiters: (id, entry Lwt.u Lwt_sequence.t) Hashtbl.t = Hashtbl.create 1
(** Track all the threads waiting for general listen events *)
let wildcard_waiters: id Lwt_mvar.t Lwt_sequence.t = Lwt_sequence.create ()

(** Track all registered providers in the system *)
let providers : provider list ref = ref []

(** Register a new KV_RO provider *)
let new_provider p =
  providers := p :: !providers

(** Find a device node for id and return the entry *)
let rec find id =
  try
    let entry = Hashtbl.find device_tree id in
    return entry
  with Not_found -> begin
    printf "Devices: [%s] sleeping\n%!" id;
    let seq = 
      try
        Hashtbl.find device_waiters id
      with Not_found ->
        let seq = Lwt_sequence.create () in
        Hashtbl.add device_waiters id seq;
        seq
    in
    let th,u = Lwt.task () in
    let node = Lwt_sequence.add_r u seq in
    Lwt.on_cancel th (fun _ -> Lwt_sequence.remove node);
    lwt ent = th in
    printf "Devices: [%s] waking\n%!" id;
    return ent 
  end

(** Main device manager thread *)
let device_t () =
  let th,u = Lwt.task () in
  Lwt.on_cancel th (fun () -> () (* TODO *));
  (** Loop to read a value from an mvar and apply function to it in parallel *)
  let rec mvar_loop mvar fn =
    lwt x = Lwt_mvar.take mvar in
    fn x <&> (mvar_loop mvar fn)
  in
  (* For each provider, set up a thread that listens for incoming plug events *)
  let provider_t provider =
    printf "Devices: [%s] provider start\n%!" provider#id;
    mvar_loop provider#plug (fun {p_id; p_dep_ids; p_cfg } ->
      printf "Devices: [%s:%s] provider plug\n%!" provider#id p_id;
      (* Satisfy all the dependencies *)
      lwt deps = Lwt_list.map_p find p_dep_ids in
      lwt entry = provider#create ~deps ~cfg:p_cfg p_id in
      (* Check if the device already exists (or any waiters are present *)
      if Hashtbl.mem device_tree p_id then begin
        printf "Devices: [%s:%s] ignoring repeat device plug\n%!" provider#id p_id;
        return ()
      end else begin
        Hashtbl.add device_tree p_id entry;
        (* Inform any wildcard listeners of the new device *)
        Lwt_sequence.iter_l (fun mvar -> ignore(Lwt_mvar.put mvar p_id)) wildcard_waiters;
        (* Check for any waiting threads *)
        match Hashtbl.find_all device_waiters p_id with
        |[] ->
          printf "Devices: [%s:%s] no waiters\n%!" provider#id p_id;
          return ()
        |[waiters] ->
          printf "Devices: [%s:%s] waking waiters\n%!" provider#id p_id;
           Hashtbl.remove device_waiters p_id;
           Lwt_sequence.iter_l (fun w -> Lwt.wakeup w entry) waiters;
           return ()
        |_ -> assert false
      end
    )
  in
  let p_t = Lwt_list.iter_p provider_t !providers in
  p_t <&> th

let iter_s fn =
  let ids = Hashtbl.fold (fun k v a -> k :: a) device_tree [] in
  Lwt_list.iter_s fn ids

let iter_p fn =
  let ids = Hashtbl.fold (fun k v a -> k :: a) device_tree [] in
  Lwt_list.iter_p fn ids

let listen fn =
  let mvar = Lwt_mvar.create_empty () in
  let th,_ = Lwt.task () in
  let listen_t = 
    (* Inform of all the existing devices *)
    let _ = iter_p fn in
    let node = Lwt_sequence.add_r mvar wildcard_waiters in
    Lwt.on_cancel th (fun () -> Lwt_sequence.remove node);
    (* Watch for new devices *)
    while_lwt true do
      Lwt_mvar.take mvar >>= fn
    done
  in
  Lwt.on_cancel th (fun () -> Lwt.cancel listen_t);
  try_lwt th with Canceled -> return ()
  
let find_blkif id = find id >|= function |{node=Blkif b} -> Some b |_ -> None
let find_kv_ro id = find id >|= function |{node=KV_RO b} -> Some b |_ -> None

let with_blkif id fn =
  find_blkif id >>= function
  |None -> raise_lwt (Failure "with_blkif")
  |Some b -> fn b

let with_kv_ro id fn =
  find_kv_ro id >>= function
  |None -> raise_lwt (Failure "with_kv_ro")
  |Some b -> fn b

(* Start the device manager thread when the system "boots" *) 
let _ = Main.at_enter device_t
