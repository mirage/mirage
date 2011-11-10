(* 
 * Copyright (c) 2011 Charalampos Rotsos <cr409@cl.cam.ac.uk>
 * Copyright (c) 2011 Richard Mortier <mort@cantab.net>
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

let resolve t = Lwt.on_success t (fun _ -> ())

module OP = Openflow.Ofpacket
module OC = Openflow.Controller
module OE = OC.Event

let pp = Printf.printf
let sp = Printf.sprintf

(* TODO this the mapping is incorrect. the datapath must be moved to the key
 * of the hashtbl *)

type mac_switch = {
  addr: OP.eaddr; 
  switch: OP.datapath_id;
}

type switch_state = {
  mutable mac_cache: (mac_switch, OP.Port.t) Hashtbl.t;
  mutable dpid: OP.datapath_id list
}

let switch_data = { 
  mac_cache = Hashtbl.create 0; 
  dpid = [] 
} 

let datapath_join_cb controller dpid evt =
  let dp = match evt with
    | OE.Datapath_join c -> c
    | _ -> invalid_arg "bogus datapath_join event match!"
  in
  switch_data.dpid <- switch_data.dpid @ [dp];
  Log.info "OF Controller" "+ datapath:0x%012Lx\n" dp

let packet_in_cb controller dpid evt =
  Log.info "OF Controller" 
    "dpid:0x%012Lx evt:%s" dpid (OE.string_of_event evt);
  
  let (in_port, buffer_id, data, dp) = match evt with
    | OE.Packet_in (inp, buf, dat, dp) -> (inp, buf, dat, dp)
    | _ -> invalid_arg "bogus packet_in event match!"
  in

  let m = OP.Match.parse_from_raw_packet in_port data in 

  (* save src mac address *)
  let ix = { addr=(OP.Match.get_dl_src m); switch=dpid } in
  if not (Hashtbl.mem switch_data.mac_cache ix) then
    Printf.printf "adding mac %s on port %s" 
      (OP.eaddr_to_string m.OP.Match.dl_src) 
      (OP.Port.string_of_port in_port);
    Hashtbl.add switch_data.mac_cache ix in_port
  else 
      Printf.printf "adding mac %s on port %s" 
        (OP.eaddr_to_string m.OP.Match.dl_src) 
        (OP.Port.string_of_port in_port);
    Hashtbl.replace switch_data.mac_cache ix in_port;

    (* check if I know the output port in order to define what type of message
     * we need to send *)
    let ix = { addr=(OP.Match.get_dl_dst m); switch=dpid } in
      if ((OP.eaddr_is_broadcast ix.addr) 
        || (not (Hashtbl.mem switch_data.mac_cache ix))) 
      then (
        let pkt = (OP.Packet_out.create
                     ~buffer_id:buffer_id
                     ~actions:[| OP.Flow.Output(OP.Port.All, 2000) |] 
                     ~data:data ~in_port:in_port () ) in
          resolve (OC.send_of_data controller dpid
                     (OP.Packet_out.packet_out_to_bitstring pkt))
      ) else (
        let out_port = Hashtbl.find switch_data.mac_cache ix in
        let actions = [| OP.Flow.Output(out_port, 2000) |] in
        let pkt = OP.Flow_mod.create m 0_L OP.Flow_mod.ADD actions () in 
          resolve (let bs = OP.Flow_mod.flow_mod_to_bitstring pkt in
                     OC.send_of_data controller dpid bs
          );               
          Log.info "OF Controller" "%s" (OP.Match.match_to_string m)
      )

let init controller = 
  Log.info "OF Controller" "register datapath cb";
  OC.register_cb controller OE.DATAPATH_JOIN datapath_join_cb;
  Log.info "OF Controller" "register packet_in cb\n";
  OC.register_cb controller OE.PACKET_IN packet_in_cb

let main () =
  Log.info "OF Controller" "starting controller";
  Net.Manager.create (fun mgr interface id ->
                        let port = 6633 in 
                          OC.listen mgr (None, port) init
                            >> return (Log.info "OF Controller" "done!")
  )
