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

let allocate_ring ~domid =
	let page = Io_page.get () in
	let x = Io_page.to_cstruct page in
	for i = 0 to Cstruct.len x - 1 do
		Cstruct.set_uint8 x i 0
	done;
	lwt gnt = Gnt.Gntshr.get () in
	Gnt.Gntshr.grant_access ~domid ~writeable:true gnt page;
	return (gnt, x)

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
	lwt rx_gnt, buf = allocate_ring ~domid in
    let sring = Ring.Rpc.of_buf ~buf ~idx_size:Proto_64.total_size ~name in
    let fring = Ring.Rpc.Front.init ~sring in
    let client = Lwt_ring.Front.init string_of_int fring in
    return (rx_gnt, fring, client)

end

module TX = struct

  type response = int

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

    let total_size = max sizeof_req sizeof_resp
    let _ = assert(total_size = 12)
  end

  let create (id,domid) =
    let name = sprintf "Netif.TX.%s" id in
	lwt rx_gnt, buf = allocate_ring ~domid in
    let sring = Ring.Rpc.of_buf ~buf ~idx_size:Proto_64.total_size ~name in
    let fring = Ring.Rpc.Front.init ~sring in
	let client = Lwt_ring.Front.init string_of_int fring in
    return (rx_gnt, fring, client)
end

type features = {
  sg: bool;
  gso_tcpv4: bool;
  rx_copy: bool;
  rx_flip: bool;
  smart_poll: bool;
}

type transport = {
  backend_id: int;
  backend: string;
  mac: string;
  tx_fring: (TX.response,int) Ring.Rpc.Front.t;
  tx_client: (TX.response,int) Lwt_ring.Front.t;
  tx_gnt: Gnt.grant_table_index;
  tx_mutex: Lwt_mutex.t; (* Held to avoid signalling between fragments *)
  rx_fring: (RX.response,int) Ring.Rpc.Front.t;
  rx_client: (RX.response,int) Lwt_ring.Front.t;
  rx_map: (int, Gnt.grant_table_index * Io_page.t) Hashtbl.t;
  rx_gnt: Gnt.grant_table_index;
  evtchn: Eventchn.t;
  features: features;
}

type t = {
  mutable t: transport;
  mutable resume_fns: (t -> unit Lwt.t) list;
  l : Lwt_mutex.t;
  c : unit Lwt_condition.t;
}

type id = string

let devices : (id, t) Hashtbl.t = Hashtbl.create 1

let h = Eventchn.init ()

(* Given a VIF ID and backend domid, construct a netfront record for it *)
let plug_inner id =
  lwt backend_id = Xs.(immediate (fun h -> read h (sprintf "device/vif/%s/backend-id" id))) >|= int_of_string in
  Console.log (sprintf "Netfront.create: id=%s domid=%d\n%!" id backend_id);
  (* Allocate a transmit and receive ring, and event channel for them *)
  lwt (rx_gnt, rx_fring, rx_client) = RX.create (id, backend_id) in
  lwt (tx_gnt, tx_fring, tx_client) = TX.create (id, backend_id) in
  let tx_mutex = Lwt_mutex.create () in
  let evtchn = Eventchn.bind_unbound_port h backend_id in
  let evtchn_port = Eventchn.to_int evtchn in
  (* Read Xenstore info and set state to Connected *)
  let node = sprintf "device/vif/%s/" id in
  lwt backend = Xs.(immediate (fun h -> read h (node ^ "backend"))) in
  lwt mac = Xs.(immediate (fun h -> read h (node ^ "mac"))) in
  printf "MAC: %s\n%!" mac;
  Xs.(transaction (fun h ->
    let wrfn k v = write h (node ^ k) v in
    wrfn "tx-ring-ref" (Gnt.string_of_grant_table_index tx_gnt) >>
    wrfn "rx-ring-ref" (Gnt.string_of_grant_table_index rx_gnt) >>
    wrfn "event-channel" (string_of_int (evtchn_port)) >>
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
  Eventchn.unmask h evtchn;
  (* Register callback activation *)
  return { backend_id; tx_fring; tx_client; tx_gnt; tx_mutex; rx_gnt; rx_fring; rx_client; rx_map;
    evtchn; mac; backend; features }

let plug id = 
  lwt transport = plug_inner id in
  let t = { t=transport; resume_fns=[]; l=Lwt_mutex.create (); c=Lwt_condition.create () } in
  Hashtbl.add devices id t;
  return t

(* Unplug shouldn't block, although the Xen one might need to due
   to Xenstore? XXX *)
let unplug id =
  Console.log (sprintf "Netif.unplug %s: not implemented yet" id);
  ()

let notify nf () =
  Eventchn.notify h nf.evtchn

let refill_requests nf =
  let num = Ring.Rpc.Front.get_free_requests nf.rx_fring in
  lwt gnts = Gnt.Gntshr.get_n num in
  let pages = Io_page.get_n num in
  List.iter
    (fun (gnt, page) ->
      Gnt.Gntshr.grant_access ~domid:nf.backend_id ~writeable:true gnt page;
      let gref = Gnt.int32_of_grant_table_index gnt in
      let id = Int32.to_int gref in (* XXX TODO make gref an int not int32 *)
      Hashtbl.add nf.rx_map id (gnt, page);
      let slot_id = Ring.Rpc.Front.next_req_id nf.rx_fring in
      let slot = Ring.Rpc.Front.slot nf.rx_fring slot_id in
      ignore(RX.Proto_64.write ~id ~gref slot)
    ) (List.combine gnts pages);
  if Ring.Rpc.Front.push_requests_and_check_notify nf.rx_fring
  then notify nf ();
  return ()

let rx_poll nf fn =
  Ring.Rpc.Front.ack_responses nf.rx_fring (fun slot ->
    let id,(offset,flags,status) = RX.Proto_64.read slot in
    let gnt, page = Hashtbl.find nf.rx_map id in
    Hashtbl.remove nf.rx_map id;
    Gnt.Gntshr.end_access gnt;
    Gnt.Gntshr.put gnt;
    match status with
    |sz when status > 0 ->
      let packet = Cstruct.sub (Io_page.to_cstruct page) 0 sz in
      ignore_result (try_lwt fn packet
        with exn -> return (printf "RX exn %s\n%!" (Printexc.to_string exn)))
    |err -> printf "RX error %d\n%!" err
  )

let tx_poll nf =
  Lwt_ring.Front.poll nf.tx_client TX.Proto_64.read

(* Push a single page to the ring, but no event notification *)
let write_request ?size ~flags nf page =
  lwt gnt = Gnt.Gntshr.get () in
  (* This grants access to the *base* data pointer of the page *)
  (* XXX: another place where we peek inside the cstruct *)
  Gnt.Gntshr.grant_access ~domid:nf.t.backend_id ~writeable:false gnt page.Cstruct.buffer;
  let gref = Gnt.int32_of_grant_table_index gnt in
  let id = Int32.to_int gref in
  let size = match size with |None -> Cstruct.len page |Some s -> s in
  (* XXX: another place where we peek inside the cstruct *)
  let offset = page.Cstruct.off in
  lwt replied = Lwt_ring.Front.write nf.t.tx_client
    (TX.Proto_64.write ~id ~gref ~offset ~flags ~size) in
  (* request has been written; when replied returns we have a reply *)
  let replied =
    try_lwt
      lwt _ = replied in
      Gnt.Gntshr.end_access gnt;
      Gnt.Gntshr.put gnt;
      return ()
    with Lwt_ring.Shutdown ->
      Gnt.Gntshr.put gnt;
      fail Lwt_ring.Shutdown
    | e ->
      Gnt.Gntshr.end_access gnt;
      Gnt.Gntshr.put gnt;
      fail e in
  return replied
 
(* Transmit a packet from buffer, with offset and length *)  
let rec write_already_locked nf page =
  try_lwt
    lwt th = write_request ~flags:0 nf page in
    Lwt_ring.Front.push nf.t.tx_client (notify nf.t);
    lwt () = th in
    (* all fragments acknowledged, resources cleaned up *)
    return ()
  with | Lwt_ring.Shutdown -> write_already_locked nf page

let write nf page =
  Lwt_mutex.with_lock nf.t.tx_mutex
  (fun () ->
    write_already_locked nf page
  )

(* Transmit a packet from a list of pages *)
let writev nf pages =
  Lwt_mutex.with_lock nf.t.tx_mutex
  (fun () ->
  match pages with
  |[] -> return ()
  |[page] ->
     (* If there is only one page, then just write it normally *)
     write_already_locked nf page
  |first_page::other_pages ->
     (* For Xen Netfront, the first fragment contains the entire packet
      * length, which is the backend will use to consume the remaining
      * fragments until the full length is satisfied *)
     let size = Cstruct.lenv pages in
     lwt first_th = write_request ~flags:TX.Proto_64.flag_more_data ~size nf first_page in
     let rec xmit = function
       | [] -> return []
       | hd :: [] ->
         lwt th = write_request ~flags:0 nf hd in
         return [ th ]
       | hd :: tl ->
         lwt next_th = write_request ~flags:TX.Proto_64.flag_more_data nf hd in
         lwt rest = xmit tl in
         return (next_th :: rest) in
     lwt rest_th = xmit other_pages in
     (* All fragments are now written, we can now notify the backend *)
     Lwt_ring.Front.push nf.t.tx_client (notify nf.t);
     return ()
  )

let wait_for_plug nf =
	Console.log_s "Wait for plug..." >>
	Lwt_mutex.with_lock nf.l (fun () -> 
		while_lwt not (Eventchn.is_valid nf.t.evtchn) do
			Lwt_condition.wait ~mutex:nf.l nf.c
		done)

let listen nf fn =
  (* Listen for the activation to poll the interface *)
  let rec poll_t t =
    lwt () = refill_requests t in
    rx_poll t fn;
    tx_poll t;
    (* Evtchn.notify nf.t.evtchn; *)
    lwt new_t = 
      try_lwt
		Activations.wait t.evtchn >> return t
      with
        | Generation.Invalid ->
			Console.log_s "Waiting for plug in listen" >> 
			lwt () = wait_for_plug nf in
            Console.log_s "Done..." >> 
            return nf.t
    in poll_t new_t
  in
  poll_t nf.t

(** Return a list of valid VIFs *)
let enumerate () =
  try_lwt Xs.(immediate (fun h -> directory h "device/vif")) with _ -> return []

let resume (id,t) =
  lwt transport = plug_inner id in
  let old_transport = t.t in
  t.t <- transport;
  lwt () = Lwt_list.iter_s (fun fn -> fn t) t.resume_fns in
  lwt () = Lwt_mutex.with_lock t.l (fun () -> Lwt_condition.broadcast t.c (); return ()) in
  Lwt_ring.Front.shutdown old_transport.rx_client;
  Lwt_ring.Front.shutdown old_transport.tx_client;
  return ()

let resume () =
  let devs = Hashtbl.fold (fun k v acc -> (k,v)::acc) devices [] in
  Lwt_list.iter_p (fun (k,v) -> resume (k,v)) devs

let add_resume_hook t fn =
	t.resume_fns <- fn::t.resume_fns

(* Type of callback functions for [create]. *)
type callback = id -> t -> unit Lwt.t

let create fn =
  lwt ids = enumerate () in
  let th = Lwt_list.iter_p (fun id -> plug id >>= fun t -> fn id t) ids in
  Lwt.on_failure th (fun _ -> Hashtbl.iter (fun id _ -> unplug id) devices);
  th

(* The Xenstore MAC address is colon separated, very helpfully *)
let mac nf = 
  let s = String.create 6 in
  Scanf.sscanf nf.t.mac "%02x:%02x:%02x:%02x:%02x:%02x"
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
  string_of_int t.t.backend_id

(* Get write buffer for Netif output *)
let get_writebuf t =
  let page = Io_page.get () in
  (* TODO: record statistics for requesting thread here (in debug mode?) *)
  return (Cstruct.of_bigarray page)

let _ =
  printf "Netif: add resume hook\n%!";
  Sched.add_resume_hook resume
