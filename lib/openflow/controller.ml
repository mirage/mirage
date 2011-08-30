(* 
 * Copyright (c) 2005-2011 Charalampos Rotsos <cr409@cl.cam.ac.uk>
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
open Net
  
let sp = Printf.sprintf
let pr = Printf.printf
let ep = Printf.eprintf
let cp = OS.Console.log

module OP = Ofpacket

module Event = struct
  type t = DATAPATH_JOIN | DATAPATH_LEAVE | PACKET_IN
  type e = 
    | Datapath_join of OP.datapath_id
    | Datapath_leave of OP.datapath_id
    | Packet_in of OP.port * Bitstring.t * OP.datapath_id

  let string_of_event = function
    | Datapath_join dpid -> sp "Datapath_join: dpid:0x%012Lx" dpid
    | Datapath_leave dpid -> sp "Datapath_leave: dpid:0x%012Lx" dpid
    | Packet_in (port, bs, dpid) 
      -> (sp "Packet_in: port:%s ... dpid:0x%012Lx" 
            (OP.string_of_port port) dpid)
      
end

type endhost = {
  ip: Nettypes.ipv4_addr;
  port: int;
}

type state = {
  mutable dp_db:  (OP.datapath_id, Channel.t) Hashtbl.t;
  mutable channel_dp: (endhost, OP.datapath_id) Hashtbl.t;

  mutable datapath_join_cb:
    (state -> OP.datapath_id -> Event.e -> unit) list;
  mutable datapath_leave_cb:
    (state -> OP.datapath_id -> Event.e -> unit) list;
  mutable packet_in_cb:
    (state -> OP.datapath_id -> Event.e -> unit) list;
}

let register_cb controller e cb =
  Event.(
    match e with 
      | DATAPATH_JOIN ->
          controller.datapath_join_cb <- cb :: controller.datapath_join_cb
      | DATAPATH_LEAVE ->
          controller.datapath_leave_cb <- cb :: controller.datapath_leave_cb
      | PACKET_IN ->
          controller.packet_in_cb <- cb :: controller.packet_in_cb
  )
   
let process_of_packet state (remote_addr, remote_port) ofp t = 
  OP.(
    let ep = { ip=remote_addr; port=remote_port } in
    match ofp with
      | Hello (h, _) (* Reply to a hello msg with a hello and a feature request *)
        -> (cp "HELLO";
            Channel.write_bitstring t (build_h h) 
            >> Channel.write_bitstring t (build_features_req 0_l) 
            >> Channel.flush t
        )
        
      | Echo_req (h, bs)  (* Reply to echo requests *)
        -> (cp "ECHO_REQ";
            Channel.write_bitstring t (build_echo_resp h bs) >> Channel.flush t)
        
      | Features_resp (h, sfs) (* Generate a datapath join event *)
        -> (cp "FEATURES_RESP";
            let dpid = sfs.Switch.datapath_id in
            let evt = Event.Datapath_join dpid in
            if not (Hashtbl.mem state.dp_db dpid) then (
              Hashtbl.add state.dp_db dpid t;
              Hashtbl.add state.channel_dp ep dpid
            );
            List.iter (fun cb -> cb state dpid evt) state.datapath_join_cb;
            return ()
        )

      | Packet_in (h, p) (* Generate a packet_in event *) 
        -> (cp (sp "+ %s|%s" 
                  (OP.string_of_h h) (OP.Packet_in.string_of_packet_in p));
            (* XXX no Hashtbl.mem check here? *)
            let dpid = Hashtbl.find state.channel_dp ep in
            let evt = Event.Packet_in (p.Packet_in.in_port, p.Packet_in.data, dpid) in
            List.iter (fun cb -> cb state dpid evt) state.packet_in_cb;
            return ()
        )

      | _ -> OS.Console.log "New packet received"; return () 
  )
   
let send_of_data controller dpid data = 
  let t = Hashtbl.find controller.dp_db dpid in
  Channel.write_bitstring t data >> Channel.flush t
  
let rd_data len t = 
  match len with
    | 0 -> return Bitstring.empty_bitstring
    | _ -> Channel.read_some ~len:len t

let listen mgr ip port init =
  let src = (ip, port) in

  let controller (remote_addr, remote_port) t =
    cp (sp "+ %s:%d" (Nettypes.ipv4_addr_to_string remote_addr) remote_port);
    let st = { dp_db = Hashtbl.create 0; 
               channel_dp = Hashtbl.create 0; 
               datapath_join_cb = []; 
               datapath_leave_cb = []; 
               packet_in_cb = [] 
             }
    in 
    init st;    
    let rec echo () =
      try_lwt
        lwt hbuf = Channel.read_some ~len:OP.h_len t in
        let ofh = OP.parse_h hbuf in
        let dlen = ofh.OP.len - OP.h_len in 
        lwt dbuf = rd_data dlen t in
        let ofp = OP.parse ofh dbuf in
        process_of_packet st (remote_addr, remote_port) ofp t;
        echo ()
      with
        | Nettypes.Closed -> return ()
        | OP.Unparsed (m, bs) -> cp (sp "# unparsed! m=%s" m); echo ()
          
    in echo () 
  in
  Channel.listen mgr (`TCPv4 (src, controller));
