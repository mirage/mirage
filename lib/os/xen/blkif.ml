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
exception Read_error of string

let rec poll t =
  lwt () = Activations.wait t.evtchn in
  Ring.Blkif_t.poll t.ring;
  poll t

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
  lwt monitor_t = Xs.(monitor_paths Xs.t
    [sprintf "%s/state" backend, (Xb_state.(to_string Connected))] 20. 
    (fun (k,v) -> Xb_state.(of_string v = Connected))
  ) in
  (* XXX bug: the xenstore watches seem to come in before the
     actual update. A short sleep here for the race, but not ideal *)
  Time.sleep 0.1 >>
  (* Read backend features *)
  lwt features = Xs.(transaction t (fun xst ->
    let backend = sprintf "%s/%s" backend in
    let rdfn fn default k =
      try_lwt
        lwt s = xst.Xst.read (backend k) in
        return (fn s)
      with exn -> return default in
    lwt state = rdfn (Xb_state.of_string) Xb_state.Unknown "state" in
    printf "state=%s\n%!" (Xb_state.prettyprint state);
    lwt barrier = rdfn ((=) "1") false "feature-barrier" in
    lwt removable = rdfn ((=) "1") false "removable" in
    lwt sectors = rdfn Int64.of_string (-1L) "sectors" in
    lwt sector_size = rdfn Int64.of_string 0L "sector-size" in
    return { barrier; removable; sector_size; sectors }
  )) in
  printf "Blkfront features: barrier=%b removable=%b sector_size=%Lu sectors=%Lu\n%!" 
    features.barrier features.removable features.sector_size features.sectors;
  Evtchn.unmask evtchn;
  let t = { backend_id; backend; vdev; ring; gnt; evtchn; features } in
  let th = poll t in
  return (t,th)
      
(** Return a list of valid VBDs *)
let enumerate () =
  lwt vbds = Xs.(t.directory "device/vbd") in
  return (List.fold_left (fun a b ->
    try int_of_string b :: a with _ -> a) [] vbds)

(* Read a single page from disk.
   Offset is the sector number, which must be page-aligned *)
let read_page t sector =
  Gnttab.with_grant ~domid:t.backend_id ~perm:Gnttab.RW
    (fun gnt ->
      let _ = Gnttab.page gnt in
      let gref = Gnttab.num gnt in
      let segs =[| { Ring.Blkif.Req.gref; first_sector=0; last_sector=7 } |] in
      let req id = Ring.Blkif.Req.({op=Read; handle=t.vdev; id; sector; segs}) in
      lwt res = Ring.Blkif_t.push_one t.ring ~evtchn:t.evtchn req in
      let open Ring.Blkif.Res in
      match res.status with
      |Error -> fail (Read_error "read")
      |Not_supported -> fail (Read_error "unsupported")
      |Unknown _ -> fail (Read_error "unknown error")
      |OK ->
        let raw = Gnttab.detach gnt in
        return (Istring.t raw 4096)
    )

(** Read a number of contiguous sectors off disk.
    This function assumes a 512 byte sector size.
  *)
let read_512 t sector num_sectors =
  (* Round down the starting sector in order to get a page aligned sector *)
  let start_sector = Int64.(mul 8L (div sector 8L)) in
  let start_offset = Int64.(to_int (sub sector start_sector)) in
  (* Round up the ending sector to get the final page size *)
  let end_sector = Int64.(mul 8L (div (add (add sector num_sectors) 7L) 8L)) in
  let end_offset = Int64.(to_int (sub 7L (sub end_sector (add sector num_sectors)))) in
  (* printf "sector=%Lu num=%Lu start=%Lu[%d] end=%Lu[%d]\n%!"
    sector num_sectors start_sector start_offset end_sector end_offset; *)
  (* Calculate number of 4K pages needed *)
  let len = Int64.(to_int (div (sub end_sector start_sector) 8L)) in
  if len > 11 then
    fail (Failure (sprintf "len > 11 sec=%Lu num=%Lu" sector num_sectors))
  else Gnttab.with_grants ~domid:t.backend_id ~perm:Gnttab.RW len
    (fun gnts ->
      let segs = Array.mapi
        (fun i gnt ->
          let first_sector = match i with
            |0 -> start_offset
            |_ -> 0 in
          let last_sector = match i with
            |n when n == len-1 -> end_offset
            |_ -> 7 in
          let _ = Gnttab.page gnt in
          let gref = Gnttab.num gnt in
          { Ring.Blkif.Req.gref; first_sector; last_sector }
        ) gnts in
      let req id = Ring.Blkif.Req.({ op=Read; handle=t.vdev; id; sector=start_sector; segs }) in
      lwt res = Ring.Blkif_t.push_one t.ring ~evtchn:t.evtchn req in
      let open Ring.Blkif.Res in
      match res.status with
      |Error -> fail (Read_error "read")
      |Not_supported -> fail (Read_error "unsupported")
      |Unknown x -> fail (Read_error "unknown error")
      |OK ->
        (* Get the pages, and convert them into Istring views *)
        let pages = Array.mapi
          (fun i gnt ->
            let page = Gnttab.detach gnt in
            let start_offset = match i with
              |0 -> start_offset * 512
              |_ -> 0 in
            let end_offset = match i with
              |n when n = len-1 -> (end_offset + 1) * 512
              |_ -> 4096 in
            let bytes = end_offset - start_offset in
            Istring.t ~off:start_offset page bytes;
          ) gnts in
        return pages
    )
