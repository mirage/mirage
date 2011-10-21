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
  type t = 
    | DATAPATH_JOIN | DATAPATH_LEAVE
    | PACKET_IN | FLOW_REMOVED 
    | FLOW_STATS_REPLY | AGGR_FLOW_STATS_REPLY | DESC_STATS_REPLY 
    | PORT_STATS_REPLY | TABLE_STATS_REPLY | PORT_STATUS_CHANGE 

  type e = 
    | Datapath_join of OP.datapath_id
    | Datapath_leave of OP.datapath_id
    | Packet_in of OP.Port.t * int32 * Bitstring.t * OP.datapath_id
    (* | Flow_stats of OP.datapath_id * int32 * (OP.Flow.stats list) (*list
     * OP.Flow.stats*) *)
    (* Flow match | reason | duration_sec | duration_usec | packet_count |
     * byte_count *)
    | Flow_removed of OP.Match.t * OP.Flow_removed.reason * int32 * int32 * int64 * int64 * OP.datapath_id 
    | Flow_stats_reply of int32 * bool * (OP.Flow.stats list) * OP.datapath_id
    | Aggr_flow_stats_reply of int32 * int64 * int64 * int32 * OP.datapath_id
    | Port_stats_reply of int32 * (OP.Port.stats list) *  OP.datapath_id
    | Table_stats_reply of int32 * (OP.Stats.table list) * OP.datapath_id 
    (*      mfr_desc * hw_desc*sw_desc * serial_num*dp_desc *)
    | Desc_stats_reply of string * string * string * string *string * OP.datapath_id
    | Port_status of OP.Port.reason * OP.Port.phy * OP.datapath_id

  let string_of_event = function
    | Datapath_join dpid -> sp "Datapath_join: dpid:0x%012Lx" dpid
    | Datapath_leave dpid -> sp "Datapath_leave: dpid:0x%012Lx" dpid
    | Packet_in (port, buffer_id, bs, dpid) 
      -> (sp "Packet_in: port:%s ... dpid:0x%012Lx buffer_id:%ld" 
            (OP.Port.string_of_port port) dpid buffer_id ) 
    | Flow_removed (flow, reason, duration_sec, duration_usec, packet_count, byte_count, dpid) ->
      (sp "Flow_removed: flow: %s reason:%s duration:%ld.%ld packets:%s bytes:%s dpid:0x%012Lx"
         (OP.Match.match_to_string flow) (OP.Flow_removed.string_of_reason reason)  duration_sec duration_usec
         (Int64.to_string packet_count) (Int64.to_string byte_count)  dpid )
    | Flow_stats_reply(xid, more, flows, dpid) ->
      (sp "Flow stats reply: dpid:%012Lx more:%s flows:%d xid:%ld")
        dpid (string_of_bool more) (List.length flows) xid
    | Aggr_flow_stats_reply(xid, packet_count, byte_count, flow_count, dpid) ->
      (sp "aggr flow stats reply: dpid:%012Lx packets:%Ld bytes:%Ld flows:%ld
        xid:%ld") dpid packet_count byte_count flow_count xid
    | Port_stats_reply (xid, ports, dpid) ->
      (sp "port stats reply: dpid:%012Lx ports:%d xid%ld" dpid (List.length
                                                                  ports) xid)
    | Table_stats_reply (xid, tables, dpid) -> 
      (sp "table stats reply: dpid:%012Lx tables:%d xid%ld" dpid (List.length
                                                                    tables) xid)
    | Desc_stats_reply (mfr_desc, hw_desc, sw_desc, serial_num, dp_desc, dpid) ->
      (sp "table stats reply: dpid:%012Lx mfr_desc:%s hw_desc:%s sw_desc:%s
        serial_num:%s dp_desc:%s" dpid mfr_desc hw_desc sw_desc
         serial_num dp_desc)
    | Port_status (r, ph, dpid) ->
      (sp "post stats: port:%s status:%s dpid:%012Lx" ph.OP.Port.name
         (OP.Port.string_of_reason r) dpid)
        
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
  mutable flow_removed_cb:
    (state -> OP.datapath_id -> Event.e -> unit) list;
  mutable flow_stats_reply_cb:
    (state -> OP.datapath_id -> Event.e -> unit) list;
  mutable aggr_flow_stats_reply_cb:
    (state -> OP.datapath_id -> Event.e -> unit) list;
  mutable desc_stats_reply_cb:
    (state -> OP.datapath_id -> Event.e -> unit) list;
  mutable port_stats_reply_cb:
    (state -> OP.datapath_id -> Event.e -> unit) list;
  mutable table_stats_reply_cb:
    (state -> OP.datapath_id -> Event.e -> unit) list;
  mutable port_status_cb:
    (state -> OP.datapath_id -> Event.e -> unit) list;
}

let register_cb controller e cb =
  Event.(
    match e with 
      | DATAPATH_JOIN
        -> controller.datapath_join_cb <- List.append controller.datapath_join_cb [cb]
      | DATAPATH_LEAVE 
        -> controller.datapath_leave_cb <- List.append controller.datapath_leave_cb [cb]
      | PACKET_IN
        -> controller.packet_in_cb <- List.append controller.packet_in_cb [cb]
      | FLOW_REMOVED
        -> controller.flow_removed_cb <- List.append controller.flow_removed_cb [cb]
      | FLOW_STATS_REPLY 
        -> controller.flow_stats_reply_cb <- List.append controller.flow_stats_reply_cb [cb]
      | AGGR_FLOW_STATS_REPLY 
        -> (controller.aggr_flow_stats_reply_cb 
            <- List.append controller.aggr_flow_stats_reply_cb [cb]
        )
      | DESC_STATS_REPLY -> controller.desc_stats_reply_cb <- List.append
        controller.desc_stats_reply_cb [cb]
      | PORT_STATS_REPLY -> controller.port_stats_reply_cb <- List.append
        controller.port_stats_reply_cb [cb] 
      | TABLE_STATS_REPLY -> controller.table_stats_reply_cb  <- List.append
        controller.table_stats_reply_cb [cb]
      | PORT_STATUS_CHANGE -> controller.port_status_cb <- List.append
        controller.port_status_cb [cb] 
  )

let process_of_packet state (remote_addr, remote_port) ofp t = 
  OP.(
    let ep = { ip=remote_addr; port=remote_port } in
    match ofp with
      | Hello (h, _) (* Reply to a hello msg with a hello and a feature request *)
        -> (cp "HELLO";
            Channel.write_bitstring t (Header.build_h h) 
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
                  (OP.Header.string_of_h h) (OP.Packet_in.string_of_packet_in p));
            let dpid = Hashtbl.find state.channel_dp ep in
            let evt = Event.Packet_in (p.Packet_in.in_port, p.Packet_in.buffer_id , p.Packet_in.data, dpid) in
            List.iter (fun cb -> cb state dpid evt) state.packet_in_cb;
            return () )
      | Flow_removed (h, p)
        -> (cp (sp "+ %s|%s" 
                  (OP.Header.string_of_h h) (OP.Flow_removed.string_of_flow_removed p));
            let dpid = Hashtbl.find state.channel_dp ep in
            let evt = Event.Flow_removed (p.Flow_removed.of_match, p.Flow_removed.reason, p.Flow_removed.duration_sec,
                                          p.Flow_removed.duration_nsec, p.Flow_removed.packet_count, p.Flow_removed.byte_count
                                            , dpid) in
            List.iter (fun cb -> cb state dpid evt) state.flow_removed_cb;
            return ()
        )
      | Stats_resp(h, resp) -> (
        cp (sp "+ %s|%s" (OP.Header.string_of_h h) (OP.Stats.string_of_stats resp));
        match resp with 
          | OP.Stats.Flow_resp(resp_h, flows) ->
            (let dpid = Hashtbl.find state.channel_dp ep in
             let evt = Event.Flow_stats_reply(h.Header.xid,
                                              resp_h.Stats.more_to_follow, flows, dpid) in
             List.iter (fun cb -> cb state dpid evt) state.flow_stats_reply_cb;
             return ();
            )
          | OP.Stats.Aggregate_resp(resp_h, aggr) -> 
            (let dpid = Hashtbl.find state.channel_dp ep in
             let evt = Event.Aggr_flow_stats_reply(h.Header.xid,
                                                   aggr.Stats.packet_count, aggr.Stats.byte_count, aggr.Stats.flow_count, dpid) in
             List.iter (fun cb -> cb state dpid evt) state.aggr_flow_stats_reply_cb;
             return ();
            )
          | OP.Stats.Desc_resp (resp_h, aggr) ->
            (let dpid = Hashtbl.find state.channel_dp ep in
             let evt = Event.Desc_stats_reply(
               aggr.Stats.imfr_desc, aggr.Stats.hw_desc, aggr.Stats.sw_desc,
               aggr.Stats.serial_num, aggr.Stats.dp_desc, dpid) in
             List.iter (fun cb -> cb state dpid evt) state.desc_stats_reply_cb;
             return ();
            )
          | OP.Stats.Port_resp (resp_h, ports) ->
            (let dpid = Hashtbl.find state.channel_dp ep in
             let evt = Event.Port_stats_reply(h.Header.xid, ports, dpid) in
             List.iter (fun cb -> cb state dpid evt) state.port_stats_reply_cb;
             return ();
            )
          | OP.Stats.Table_resp (resp_h, tables) ->
            (let dpid = Hashtbl.find state.channel_dp ep in
             let evt = Event.Table_stats_reply(h.Header.xid, tables, dpid) in
             List.iter (fun cb -> cb state dpid evt) state.table_stats_reply_cb;
             return ();
            )
          | _ -> OS.Console.log "New stats response received";
            return ();
      ) 
      | Port_status(h, st) ->  
        (cp (sp "+ %s|%s" (OP.Header.string_of_h h) (OP.Port.string_of_status st));
         let dpid = Hashtbl.find state.channel_dp ep in
         let evt = Event.Port_status (st.Port.reason, st.Port.desc, dpid) in
         List.iter (fun cb -> cb state dpid evt) state.port_status_cb;
         return () )

      | _ -> OS.Console.log "New packet received"; return () 
  )

  (*
  (* Handle a single input frame *)
let packet_to_flow frame = 
  bitmatch frame with
  |{dmac:48:string; smac:48:string;
  0x0806:16;     (* ethertype *)
  1:16;          (* htype const 1 *)
  0x0800:16;     (* ptype const, ND used for IPv6 now *)
  6:8;           (* hlen const 6 *)
  4:8;           (* plen const, ND used for IPv6 now *)
  op:16;
  sha:48:string; spa:32;
  tha:48:string; tpa:32 } ->
    let sha = ethernet_mac_of_bytes sha in
let spa = ipv4_addr_of_uint32 spa in
let tha = ethernet_mac_of_bytes tha in
let tpa = ipv4_addr_of_uint32 tpa in
let op = match op with |1->`Request |2 -> `Reply |n -> `Unknown n in
let arp = { op; sha; spa; tha; tpa } in
Arp.input t.arp arp

      |{dmac:48:string; smac:48:string;
      etype:16; bits:-1:bitstring } -> 
        let frame = gen_frame dmac smac in
begin match etype with
| 0x0800 (* IPv4 *) -> t.ipv4 bits
| 0x86dd (* IPv6 *) -> return (Printf.printf "Ethif: discarding ipv6\n%!")
  | etype -> return (Printf.printf "Ethif: unknown frame %x\n%!" etype)
end
      |{_} ->
          return (Printf.printf "Ethif: dropping input\n%!")
  *)


let send_of_data controller dpid data = 
  let t = Hashtbl.find controller.dp_db dpid in
  Channel.write_bitstring t data >> Channel.flush t

let rec rd_data len t = 
  match len with
  | 0 -> return Bitstring.empty_bitstring
  | _ -> lwt data = (Channel.read_some ~len:len t) in 
lwt  more_data = (rd_data (len - ((Bitstring.bitstring_length data)/8)) t) in
return (Bitstring.concat [ data; more_data ])

let listen mgr ip port init =
  let src = (ip, port) in

  let controller (remote_addr, remote_port) t =
    cp (sp "+ %s:%d" (Nettypes.ipv4_addr_to_string remote_addr) remote_port);
    let st = { dp_db = Hashtbl.create 0; 
               channel_dp = Hashtbl.create 0; 
               datapath_join_cb = []; 
               datapath_leave_cb = []; 
               packet_in_cb = [];
               flow_removed_cb = []; 
               flow_stats_reply_cb = [];
               aggr_flow_stats_reply_cb = [];
               desc_stats_reply_cb = []; 
               port_stats_reply_cb = [];
               table_stats_reply_cb = [];
               port_status_cb = [];
             }
    in 
    init st;    
    let rec echo () =
      try_lwt
        lwt hbuf = Channel.read_some ~len:OP.Header.get_len t in
        let ofh = OP.Header.parse_h hbuf in
        let dlen = ofh.OP.Header.len - OP.Header.get_len in 
        lwt dbuf = rd_data dlen t in
        (* pr "post request %d received %d\n" dlen ((Bitstring.bitstring_length
         * dbuf)/8) ;*)
        let ofp = OP.parse ofh dbuf in
        process_of_packet st (remote_addr, remote_port) ofp t 
        >> echo ()
      with
        | Nettypes.Closed -> return ()
        | OP.Unparsed (m, bs) -> cp (sp "# unparsed! m=%s" m); echo ()

    in echo () 
  in
  Channel.listen mgr (`TCPv4 (src, controller));
