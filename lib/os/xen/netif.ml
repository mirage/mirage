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

  type response = int * int * int

  let create (id,domid) =
    let name = sprintf "Netif.RX.%s" id in
    lwt rx_gnt, sring = Ring.init ~domid ~idx_size ~name in
    let fring = Ring.Front.init ~sring in
    return (rx_gnt, fring)

  let write_request ~id ~gref (bs,bsoff,_) =
    let req,_,reqlen = BITSTRING { id:16:littleendian; 0:16; gref:32:littleendian } in
    String.blit req 0 bs (bsoff/8) (reqlen/8);
    id

  let read_response bs =
    bitmatch bs with
    | { id:16:littleendian; offset:16:littleendian; flags:16:littleendian;
        status:16:littleendian } ->
          (id, (offset, flags, status))

end

module TX = struct

  let idx_size = 12 (* in bytes *)

  type response = int

  let create (id,domid) =
    let name = sprintf "Netif.TX.%s" id in
    lwt tx_gnt, sring = Ring.init ~domid ~idx_size ~name in
    let fring = Ring.Front.init ~sring in
    return (tx_gnt, fring)

  let write_request ~gref ~offset ~flags ~id ~size (bs,bsoff,_) =
    let req,_,reqlen = BITSTRING { gref:32:littleendian; offset:16:littleendian;
      flags:16:littleendian; id:16:littleendian; size:16:littleendian } in
    String.blit req 0 bs (bsoff/8) (reqlen/8);
    id

  let read_response bs =
    bitmatch bs with
    | { id:16:littleendian; status:16:littleendian } ->
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
  tx_fring: (TX.response,int) Ring.Front.t;
  tx_gnt: Gnttab.r;
  rx_fring: (RX.response,int) Ring.Front.t;
  rx_map: (int, Gnttab.r) Hashtbl.t;
  rx_gnt: Gnttab.r;
  evtchn: int;
  features: features;
}

type id = string

let devices : (id, t) Hashtbl.t = Hashtbl.create 1

(* Given a VIF ID and backend domid, construct a netfront record for it *)
let plug id =
  lwt backend_id = Xs.(t.read (sprintf "device/vif/%s/backend-id" id)) >|= int_of_string in
  Console.log (sprintf "Netfront.create: id=%s domid=%d\n%!" id backend_id);
  (* Allocate a transmit and receive ring, and event channel for them *)
  lwt (rx_gnt, rx_fring) = RX.create (id, backend_id) in
  lwt (tx_gnt, tx_fring) = TX.create (id, backend_id) in
  let evtchn = Evtchn.alloc_unbound_port backend_id in
  (* Read Xenstore info and set state to Connected *)
  let node = sprintf "device/vif/%s/" id in
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
  let t = { backend_id; tx_fring; tx_gnt; rx_gnt; rx_fring; rx_map;
    evtchn; mac; backend; features } in
  Hashtbl.add devices id t;
  return t

(* Unplug shouldn't block, although the Xen one might need to due
   to Xenstore? XXX *)
let unplug id =
  Console.log (sprintf "Netif.unplug %s: not implemented yet" id);
  ()

let refill_requests nf =
  let num = Ring.Front.get_free_requests nf.rx_fring in
  lwt gnts = Gnttab.get_n ~domid:nf.backend_id ~perm:Gnttab.RW num in
  List.iter (fun gnt ->
    let _ = Gnttab.page gnt in
    let gref = Gnttab.num gnt in
    let id = Int32.to_int gref in (* XXX TODO make gref an int not int32 *)
    Hashtbl.add nf.rx_map id gnt;
    let slot_id = Ring.Front.next_req_id nf.rx_fring in
    let slot = Ring.Front.slot nf.rx_fring slot_id in
    ignore(RX.write_request ~id ~gref slot);
  ) gnts;
  if Ring.Front.push_requests_and_check_notify nf.rx_fring then
    Evtchn.notify nf.evtchn;
  return ()

let rx_poll nf fn =
  Ring.Front.ack_responses nf.rx_fring (fun bs ->
    let id,(offset,flags,status) = RX.read_response bs in
    let gnt = Hashtbl.find nf.rx_map id in
    Hashtbl.remove nf.rx_map id;
    let page = Gnttab.detach gnt in
    Gnttab.end_access gnt;
    Gnttab.put_free_entry gnt;
    match status with
    |sz when status > 0 ->
      let packet = Bitstring.subbitstring page 0 (sz*8) in
      ignore_result (try_lwt fn packet
        with exn -> return (printf "RX exn %s\n%!" (Printexc.to_string exn)))
    |err -> printf "RX error %d\n%!" err
  )

(* Transmit a packet from buffer, with offset and length *)  
let output nf bsv =
  Gnttab.with_grant ~domid:nf.backend_id ~perm:Gnttab.RO (fun gnt ->
    let gref = Gnttab.num gnt in
    let id = Int32.to_int gref in
    let page = Gnttab.page gnt in
    let (pagebuf, pageoffbits, _) = page in
    let pageoff = pageoffbits / 8 in
    let size = List.fold_left (fun offset (src,srcoff,srclenbits) ->
      let srclen = srclenbits / 8 in
      String.blit src (srcoff/8) pagebuf (pageoff+offset) srclen;
      offset+srclen) 0 bsv in
    let flags = 0 in
    let offset = 0 in
    let res = Ring.Front.push_request_and_wait nf.tx_fring
      (TX.write_request ~id ~gref ~offset~flags ~size) in
    if Ring.Front.push_requests_and_check_notify nf.tx_fring then
      Evtchn.notify nf.evtchn;
    match_lwt res with
    |status when status = 0 -> return ()
    |errcode -> return (printf "TX: error %d\n%!" errcode)
  )

let tx_poll nf =
  Ring.Front.poll nf.tx_fring (TX.read_response)

let listen nf fn =
  (* Listen for the activation to poll the interface *)
  let rec poll_t () =
    lwt () = refill_requests nf in
    rx_poll nf fn;
    tx_poll nf;
    (* Evtchn.notify nf.evtchn; *)
    Activations.wait nf.evtchn >>
    poll_t ()
  in
  poll_t ()

(** Return a list of valid VIF IDs *)
let enumerate () =
  (* Find out how many VIFs we have *)
  let rec read_vif num acc =
    try_lwt
      lwt sid = Xs.(t.read (sprintf "device/vif/%d/backend-id" num)) in
      printf "found: num=%d backend-id=%s\n%!" num sid;
      read_vif (succ num) (sid :: acc)
    with
      Xb.Noent -> return (List.rev acc)
  in
  read_vif 0 []

let create fn =
  let th,_ = Lwt.task () in
  Lwt.on_cancel th (fun _ -> Hashtbl.iter (fun id _ -> unplug id) devices);
  lwt ids = enumerate () in
  let pt = Lwt_list.iter_p (fun id ->
    lwt t = plug id in
    fn id t) ids in
  th <?> pt

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

