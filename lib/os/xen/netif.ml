(*
 * Copyright (c) 2010-2011 Anil Madhavapeddy <anil@recoil.org>
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

module RX = struct

  let idx_size = 8 (* max of sizeof(request), sizeof(response) *)

  let create (num,domid) =
    let name = sprintf "Netif.RX.%d" num in
    lwt (rx_gnt, rx) = Ring.alloc domid in
    let sring = Ring.init rx ~idx_size ~name in
    let fring = Ring.Front.init ~sring in
    return (rx_gnt, sring, fring)

  let write_request ~id ~gref (bs,bsoff,_) =
    let req,_,reqlen = BITSTRING { id:16:littleendian; 0:16; gref:32:littleendian } in
    String.blit req 0 bs (bsoff/8) (reqlen/8)

  let read_response bs =
    bitmatch bs with
    | { id:16:littleendian; offset:16:littleendian; flags:16:littleendian; status:16:littleendian } ->
        (id, offset, flags, status)

end

module TX = struct

  let idx_size = 12 (* in bytes *)

  let create (num,domid) =
    let name = sprintf "Netif.TX.%d" num in
    lwt (tx_gnt, tx) = Ring.alloc domid in
    let sring = Ring.init tx ~idx_size ~name in
    let fring = Ring.Front.init ~sring in
    return (tx_gnt, sring, fring)

  let request ~gref ~offset ~flags ~id ~size (bs,bsoff,_) =
    ()

  let response bs =
    bitmatch bs with
    | { id:16; status:16 } ->
        (id, status)

end

type features = {
  sg: bool;
  gso_tcpv4: bool;
  rx_copy: bool;
  rx_flip: bool;
  smart_poll: bool;
}

type t = {
  backend_id: int;
  backend: string;
  mac: string;
  tx_sring: Ring.sring;
  tx_fring: Ring.Front.t;
  tx_gnt: Gnttab.r;
  rx_sring: Ring.sring;
  rx_fring: Ring.Front.t;
  rx_map: (int, Gnttab.r) Hashtbl.t;
  rx_gnt: Gnttab.r;
  evtchn: int;
  features: features;
}

type id = (int * int)

(* Given a VIF ID and backend domid, construct a netfront record for it *)
let create (num,backend_id) =
  Console.log (sprintf "Netfront.create: start num=%d domid=%d\n%!"
    num backend_id);

  (* Allocate a transmit and receive ring, and event channel for them *)
  lwt (rx_gnt, rx_sring, rx_fring) = RX.create (num,backend_id) in
  lwt (tx_gnt, tx_sring, tx_fring) = TX.create (num,backend_id) in
  let evtchn = Evtchn.alloc_unbound_port backend_id in
  printf "nr_ents in rx: %d\n%!" (Ring.nr_ents rx_sring);
  (* Read xenstore info and set state to Connected *)
  let node = sprintf "device/vif/%d/" num in
  lwt backend = Xs.(t.read (node ^ "backend")) in
  lwt mac = Xs.(t.read (node ^ "mac")) in
  printf "MAC: %s\n%!" mac;
  Xs.(transaction t (fun xst ->
    let wrfn k v = xst.Xst.write (node ^ k) v in
    wrfn "tx-ring-ref" (Gnttab.to_string tx_gnt) >>
    wrfn "rx-ring-ref" (Gnttab.to_string rx_gnt) >>
    wrfn "event-channel" (string_of_int evtchn) >>
    wrfn "request-rx-copy" "1" >>
    wrfn "feature-rx-notify" "1" >>
    wrfn "feature-sg" "1" >>
    wrfn "state" Xb.State.(to_string Connected)
  )) >>
  (* Read backend features *)
  lwt features = Xs.(transaction t (fun xst ->
    let rdfn k =
      try_lwt
        xst.Xst.read (sprintf "%s/feature-%s" backend k) >>= 
        function
        |"1" -> return true
        |_ -> return false
      with exn -> return false in
    lwt sg = rdfn "sg" in
    lwt gso_tcpv4 = rdfn "gso-tcpv4" in
    lwt rx_copy = rdfn "rx-copy" in
    lwt rx_flip = rdfn "rx-flip" in
    lwt smart_poll = rdfn "smart-poll" in
    return { sg; gso_tcpv4; rx_copy; rx_flip; smart_poll }
  )) in
  let rx_map = Hashtbl.create 1 in
  Console.log (sprintf " sg:%b gso_tcpv4:%b rx_copy:%b rx_flip:%b smart_poll:%b"
    features.sg features.gso_tcpv4 features.rx_copy features.rx_flip features.smart_poll);
  Evtchn.unmask evtchn;
  (* Register callback activation *)
  return { backend_id; tx_sring; tx_fring; tx_gnt; rx_gnt; rx_fring; rx_sring; rx_map; evtchn; mac; backend; features }

let refill_requests nf =
  let num = Ring.Front.get_free_requests nf.rx_fring in
  printf "refill rx: %d\n%!" num;
  lwt gnts = Gnttab.get_n ~domid:nf.backend_id ~perm:Gnttab.RW num in
  List.iter (fun gnt ->
    let _ = Gnttab.page gnt in
    let gref = Gnttab.num gnt in
    let id = Int32.to_int gref in (* XXX TODO make gref an int not int32 *)
    Hashtbl.add nf.rx_map id gnt;
    let slot = Ring.Front.next_req_slot nf.rx_fring in
    RX.write_request ~id ~gref slot;
  ) gnts;
  if Ring.Front.push_requests_and_check_notify nf.rx_fring then
    Evtchn.notify nf.evtchn;
  return ()

let rx_poll nf fn =
  Ring.Front.ack_responses nf.rx_fring (fun bs ->
    let id,offset,flags,status = RX.read_response bs in
    let gnt = Hashtbl.find nf.rx_map id in
    Hashtbl.remove nf.rx_map id;
    let page = Gnttab.detach gnt in
    Gnttab.end_access gnt;
    Gnttab.put_free_entry gnt;
    match status with
    |sz when status > 0 ->
      let packet = Bitstring.subbitstring page 0 (sz*8) in
      Bitstring.hexdump_bitstring stdout packet
    |err -> printf "RX error %d\n%!" err
  )

let listen nf fn =
  (* Listen for the activation to poll the interface *)
  let rec poll_t () =
    lwt () = refill_requests nf in
    rx_poll nf fn;
    (* Ring.Netif.Tx_t.poll nf.tx;  *)
    (* Evtchn.notify nf.evtchn; *)
    Activations.wait nf.evtchn >>
    poll_t ()
  in
  poll_t ()

(* Shutdown a netfront *)
let destroy nf =
  printf "netfront_destroy\n%!";
  return ()

(*
(* Transmit a packet from buffer, with offset and length *)  
let output nf fn =
  Gnttab.with_grant ~domid:nf.backend_id ~perm:Gnttab.RO (fun gnt ->
    let gref = Gnttab.num gnt in
    let page = Gnttab.page gnt in
    let offset = 0 in
    let view = Istring.t page 0 in
    let packet = fn view in
    let size = Istring.length view in
    let open Ring.Netif.Tx in
    let flags = 0 in
    let req id = Req.Normal { Req.gref; offset; flags; id; size } in
    (* Push request *)
    lwt res = Ring.Netif.Tx_t.push_one nf.tx ~evtchn:nf.evtchn req in
    let _ = Gnttab.detach gnt in
    match res.Res.status with
    |Res.OK -> return packet
    |Res.Dropped | Res.Error |Res.Null ->
      Console.log "Netif.Tx_t: packet transmit error\n";
      return packet
  ) 
*)

(** Return a list of valid VIF IDs *)
let enumerate () =
  (* Find out how many VIFs we have *)
  let rec read_vif num acc =
    try_lwt
      lwt sid = Xs.(t.read (sprintf "device/vif/%d/backend-id" num)) in
      let domid = int_of_string sid in
      printf "found: num=%d backend-id=%d\n%!" num domid;
      read_vif (succ num) ((num,domid) :: acc)
    with
      Xb.Noent -> return (List.rev acc)
  in
  read_vif 0 []

(* The Xenstore MAC address is colon separated, very helpfully *)
let mac nf = 
  let s = String.create 6 in
  Scanf.sscanf nf.mac "%02x:%02x:%02x:%02x:%02x:%02x"
    (fun a b c d e f ->
      s.[0] <- Char.chr a;
      s.[1] <- Char.chr b;
      s.[2] <- Char.chr c;
      s.[3] <- Char.chr d;
      s.[4] <- Char.chr e;
      s.[5] <- Char.chr f;
    );
  s

let string_of_id t = string_of_int (fst t)
