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

type features = {
  barrier: bool;
  removable: bool;
  sector_size: int64; (* stored as int64 for convenient division *)
  sectors: int64;
}

type t = {
  backend_id: int;
  backend: string;
  vdev: int;
  ring: Ring.Blkif_t.t;
  gnt: Gnttab.r;
  evtchn: int;
  features: features;
}

type id = int

(* Given a VBD ID and a backend domid, construct a blkfront record *)
let create vdev =
  printf "Blkfront.create; vdev=%d\n%!" vdev;
  let node = sprintf "device/vbd/%d/%s" vdev in
  lwt backend_id = Xs.(t.read (node "backend-id")) in
  lwt backend_id = try_lwt return (int_of_string backend_id)
    with _ -> fail (Failure "invalid backend_id") in
  lwt (gnt, ring) = Ring.Blkif_t.t backend_id in
  let evtchn = Evtchn.alloc_unbound_port backend_id in
  (* Read xenstore info and set state to Connected *)
  lwt backend = Xs.(t.read (node "backend")) in
  Xs.(transaction t (fun xst ->
    let wrfn k v = xst.Xst.write (node k) v in
    wrfn "ring-ref" (Gnttab.to_string gnt) >>
    wrfn "event-channel" (string_of_int evtchn) >>
    wrfn "protocol" "x86_64-abi" >>
    wrfn "state" Xb.State.(to_string Connected) 
  )) >>
  (* Read backend features *)
  lwt features = Xs.(transaction t (fun xst ->
    let backend = sprintf "%s/%s" backend in
    let rdfn fn default k =
      try_lwt
       lwt s = xst.Xst.read (backend k) in
       return (fn s)
      with exn -> return default in
    lwt barrier = rdfn ((=) "1") false "feature-barrier" in
    lwt removable = rdfn ((=) "1") false "removable" in
    lwt sectors = rdfn Int64.of_string 0L "sectors" in
    lwt sector_size = rdfn Int64.of_string 0L "sector_size" in
    return { barrier; removable; sector_size; sectors }
  )) in
  printf "Blkfront features: barrier=%b removable=%b\n%!" 
    features.barrier features.removable;
  Evtchn.unmask evtchn;
  return { backend_id; backend; vdev; ring; gnt; evtchn; features }

(** Return a list of valid VBDs *)
let enumerate () =
  lwt vbds = Xs.(t.directory "device/vbd") in
  return (List.fold_left (fun a b ->
    try int_of_string b :: a with _ -> a) [] vbds)

(** Read a sector number and length.
    len and off must be aligned to features.sector size *)
let read t off len =
  let sector_size = t.features.sector_size in
  if (Int64.rem off sector_size != 0L) ||
     (Int64.rem len sector_size != 0L) then
    fail (Failure "unaligned read")
  else begin
    let sector = Int64.div off sector_size in
    let num_sectors = Int64.div len sector_size in
    return () (* TODO *)
  end
