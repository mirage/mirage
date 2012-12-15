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

  module Proto_64 = struct
    cstruct req {
      uint16_t       id;
      uint16_t       _padding;
      uint32_t       gref
    } as little_endian

    let write ~id ~gref slot =
      set_req_id slot id;
      set_req_gref slot gref;
      id

    cstruct resp {
      uint16_t       id;
      uint16_t       offset;
      uint16_t       flags;
      uint16_t       status
    } as little_endian

    let read slot =
      get_resp_id slot, (get_resp_offset slot, get_resp_flags slot, get_resp_status slot)

    let total_size = max sizeof_req sizeof_resp
    let _ = assert(total_size = 8)
  end

  type response = int * int * int

  let create (id,domid) =
    let name = sprintf "Netif.RX.%s" id in
    lwt rx_gnts, buf = Ring.allocate ~domid ~order:0 in
    let sring = Ring.of_buf ~buf ~idx_size:Proto_64.total_size ~name in
    (* XXX: single-page ring for now *)
    let rx_gnt = List.hd rx_gnts in
    let fring = Ring.Front.init ~sring in
    return (rx_gnt, fring)

end

module TX = struct

  let idx_size = 12 (* in bytes *)

  type response = int

  let create (id,domid) =
    let name = sprintf "Netif.TX.%s" id in
    lwt tx_gnts, buf = Ring.allocate ~domid ~order:0 in
    let sring = Ring.of_buf ~buf ~idx_size ~name in
    (* XXX: single page ring for now *)
    let tx_gnt = List.hd tx_gnts in
    let fring = Ring.Front.init ~sring in
    return (tx_gnt, fring)

  module Proto_64 = struct
    cstruct req {
      uint32_t       gref;
      uint16_t       offset;
      uint16_t       flags;
      uint16_t       id;
      uint16_t       size
    } as little_endian

    type flags =
      |Checksum_blank (* 1 *)
      |Data_validated (* 2 *)
      |More_data      (* 4 *)
      |Extra_info     (* 8 *)

    let flag_more_data = 4

    let write ~gref ~offset ~flags ~id ~size slot =
      set_req_gref slot gref;
      set_req_offset slot offset;
      set_req_flags slot flags;
      set_req_id slot id;
      set_req_size slot size;
      id

    cstruct resp {
      uint16_t       id;
      uint16_t       status
    } as little_endian

    let read slot =
      get_resp_id slot, get_resp_status slot
  end
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
  rx_map: (int, Gnttab.r * Io_page.t) Hashtbl.t;
  rx_gnt: Gnttab.r;
  evtchn: int;
  features: features;
}

type id = string

let devices : (id, t) Hashtbl.t = Hashtbl.create 1

(* Given a VIF ID and backend domid, construct a netfront record for it *)
let plug id =
  lwt backend_id = Xs.(immediate (fun h -> read h (sprintf "device/vif/%s/backend-id" id))) >|= int_of_string in
  Console.log (sprintf "Netfront.create: id=%s domid=%d\n%!" id backend_id);
  (* Allocate a transmit and receive ring, and event channel for them *)
  lwt (rx_gnt, rx_fring) = RX.create (id, backend_id) in
  lwt (tx_gnt, tx_fring) = TX.create (id, backend_id) in
  let evtchn = Evtchn.alloc_unbound_port backend_id in
  (* Read Xenstore info and set state to Connected *)
  let node = sprintf "device/vif/%s/" id in
  lwt backend = Xs.(immediate (fun h -> read h (node ^ "backend"))) in
  lwt mac = Xs.(immediate (fun h -> read h (node ^ "mac"))) in
  printf "MAC: %s\n%!" mac;
  Xs.(transaction (fun h ->
    let wrfn k v = write h (node ^ k) v in
    wrfn "tx-ring-ref" (Gnttab.to_string tx_gnt) >>
    wrfn "rx-ring-ref" (Gnttab.to_string rx_gnt) >>
    wrfn "event-channel" (string_of_int evtchn) >>
    wrfn "request-rx-copy" "1" >>
    wrfn "feature-rx-notify" "1" >>
    wrfn "feature-sg" "1" >>
    wrfn "state" Device_state.(to_string Connected)
  )) >>
  (* Read backend features *)
  lwt features = Xs.(transaction (fun h ->
    let rdfn k =
      try_lwt
        read h (sprintf "%s/feature-%s" backend k) >>= 
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
  lwt gnts = Gnttab.get_n num in
  let pages = Io_page.get_n num in
  List.iter
    (fun (gnt, page) ->
      Gnttab.grant_access ~domid:nf.backend_id ~perm:Gnttab.RW gnt page;
      let gref = Gnttab.to_int32 gnt in
      let id = Int32.to_int gref in (* XXX TODO make gref an int not int32 *)
      Hashtbl.add nf.rx_map id (gnt, page);
      let slot_id = Ring.Front.next_req_id nf.rx_fring in
      let slot = Ring.Front.slot nf.rx_fring slot_id in
      ignore(RX.Proto_64.write ~id ~gref slot)
    ) (List.combine gnts pages);
  if Ring.Front.push_requests_and_check_notify nf.rx_fring then
    Evtchn.notify nf.evtchn;
  return ()

let rx_poll nf fn =
  Ring.Front.ack_responses nf.rx_fring (fun slot ->
    let id,(offset,flags,status) = RX.Proto_64.read slot in
    let gnt, page = Hashtbl.find nf.rx_map id in
    Hashtbl.remove nf.rx_map id;
    Gnttab.end_access gnt;
    Gnttab.put gnt;
    match status with
    |sz when status > 0 ->
      let packet = Io_page.sub page 0 sz in
      ignore_result (try_lwt fn packet
        with exn -> return (printf "RX exn %s\n%!" (Printexc.to_string exn)))
    |err -> printf "RX error %d\n%!" err
  )

let tx_poll nf =
  Ring.Front.poll nf.tx_fring TX.Proto_64.read

(* Push a single page to the ring, but no event notification *)
let write_request ?size ~flags nf page =
  lwt gnt = Gnttab.get () in
  (* This grants access to the *base* data pointer of the page *)
  Gnttab.grant_access ~domid:nf.backend_id ~perm:Gnttab.RO gnt page;
  let gref = Gnttab.to_int32 gnt in
  let id = Int32.to_int gref in
  let size = match size with |None -> Io_page.length page |Some s -> s in
  let offset = Cstruct.base_offset page in
  Ring.Front.push_request_async nf.tx_fring
    (TX.Proto_64.write ~id ~gref ~offset ~flags ~size) 
    (fun () ->
      Gnttab.end_access gnt; 
      Gnttab.put gnt)
 
(* Transmit a packet from buffer, with offset and length *)  
let write nf page =
  lwt () = write_request ~flags:0 nf page in
  if Ring.Front.push_requests_and_check_notify nf.tx_fring then
    Evtchn.notify nf.evtchn;
  return ()

(* Transmit a packet from a list of pages *)
let writev nf pages =
  match pages with
  |[] -> return ()
  |[page] ->
     (* If there is only one page, then just write it normally *)
     write nf page
  |first_page::other_pages ->
     (* For Xen Netfront, the first fragment contains the entire packet
      * length, which is the backend will use to consume the remaining
      * fragments until the full length is satisfied *)
     lwt () = write_request ~flags:TX.Proto_64.flag_more_data ~size:(Cstruct.lenv pages) nf first_page in
     let rec xmit = 
       function
       |[] -> return ()
       |[page] -> (* The last fragment has no More_data flag to indicate eof *)
          write_request ~flags:0 nf page
       |page::tl -> (* A middle fragment has a More_data flag set *)
          lwt () = write_request ~flags:TX.Proto_64.flag_more_data nf page in
          xmit tl
     in
     lwt () = xmit other_pages in
     if Ring.Front.push_requests_and_check_notify nf.tx_fring then
       Evtchn.notify nf.evtchn;
     return ()

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
      lwt sid = Xs.(immediate (fun h -> read h (sprintf "device/vif/%d/backend-id" num))) in
      printf "found: num=%d backend-id=%s\n%!" num sid;
      read_vif (succ num) (sid :: acc)
    with
      _ -> return (List.rev acc)
  in
  read_vif 0 []

let create ?dev fn =
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

(* The Xenstore MAC address is colon separated, very helpfully *)
let ethid t = 
  string_of_int t.backend_id

(* Get write buffer for Netif output *)
let get_writebuf t =
  let page = Io_page.get () in
  (* TODO: record statistics for requesting thread here (in debug mode?) *)
  return page
