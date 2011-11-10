(*
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
open Net
open Nettypes

module OP = Ofpacket

let sp = Printf.sprintf
let pr = Printf.printf
let ep = Printf.eprintf
let cp = OS.Console.log

(* XXX should really standardise these *)
type uint16 = OP.uint16
type uint32 = OP.uint32
type uint64 = OP.uint64
type byte   = OP.byte
type eaddr  = OP.eaddr

type port = uint16
type cookie = uint64

type device = string (* XXX placeholder! *)

module Entry = struct
  type table_counter = {
    n_active: uint32;
    n_lookups: uint64;
    n_matches: uint64;
  }

  type flow_counter = {
    n_packets: uint64;
    n_bytes: uint64;
    secs: uint32;
    nsecs: uint32;
  }

  type port_counter = {
    rx_packets: uint64;
    tx_packets: uint64;
    rx_bytes: uint64;
    tx_bytes: uint64;
    rx_drops: uint64;
    tx_drops: uint64;
    rx_errors: uint64;
    tx_errors: uint64;
    rx_alignment_errors: uint64;
    rx_overrun_errors: uint64;
    rx_crc_errors: uint64;
    n_collisions: uint64;
  }

  type queue_counter = {
    tx_packets: uint64;
    tx_bytes: uint64;
    tx_overrun_errors: uint64;
  }

  type counters = {
    per_table: table_counter list;
    per_flow: flow_counter list;
    per_port: port_counter list;
    per_queue: queue_counter list;
  }

  let init_flow_counters () =
    {n_packets=(Int64.of_int 0);
    n_bytes= (Int64.of_int 0);
    secs=(Int32.of_int 0);
    nsecs=(Int32.of_int 0);}

  type action = 
    (** Required actions *)
    | FORWARD of OP.Port.t
    | DROP
    (** Optional actions *)
    | ENQUEUE of OP.Queue.h
    (** Modify field actions *)
    | SET_VLAN_ID of uint16
    | SET_VLAN_PRIO of uint16
    | STRIP_VLAN_HDR
    | SET_DL_SRC of eaddr
    | SET_DL_DST of eaddr
    | SET_NW_SRC of Nettypes.ipv4_addr
    | SET_NW_DST of Nettypes.ipv4_addr
    | SET_NW_TOS of byte
    | SET_TP_SRC of port
    | SET_TP_DST of port

  type t = { 
    (* fields: OP.Match.t list; *)
    counters: flow_counter;
    actions: action list;
  }

end

module Table = struct
  type t = {
    tid: cookie;
    mutable entries: (OP.Match.t, Entry.t) Hashtbl.t;
  }
end

module Switch = struct
  type port = {
    (* details: OP.Port.phy; *)
    port_id: int;
    port_name: string;
    mgr: Net.Manager.t;
    (* device: device; *)
    (* port_id: (OS.Netif.id, int) Hashtbl.t; *)
  }

  type stats = {
    mutable n_frags: uint64;
    mutable n_hits: uint64;
    mutable n_missed: uint64;
    mutable n_lost: uint64;
  }

  type t = {
    mutable ports: (string, port) Hashtbl.t;
    mutable int_ports: (int, port) Hashtbl.t;
    mutable port_feat : OP.Port.phy list;
    mutable controllers: (Net.Channel.t) list;
    table: Table.t;
    stats: stats;
    p_sflow: uint32; (** probability for sFlow sampling *)
  }

end

let st = Switch.(
  { ports = (Hashtbl.create 0); int_ports = (Hashtbl.create 0);
    table = Table.({ tid = 0_L; entries = (Hashtbl.create 0) });
    stats = { n_frags=0_L; n_hits=0_L; n_missed=0_L; n_lost=0_L };
    p_sflow = 0_l; controllers=[]; port_feat = [];
  })

let add_flow tuple actions = 
  if (Hashtbl.mem st.Switch.table.Table.entries tuple) then
    Printf.printf "Tuple already exists" 
  else
    Hashtbl.add st.Switch.table.Table.entries tuple 
      Entry.({actions; counters=(init_flow_counters ())})

let rec set_frame_bits frame start len bits = 
  match len with 
      (*TODO: Make the pattern match more accurate, read the match syntax*)
    | 0 -> return ()
    | len ->
        Bitstring.put frame (start + len - 1) (Bitstring.get bits (len - 1));
        set_frame_bits frame start (len-1) bits

let forward_frame st tupple port frame =
  (* Printf.printf "Outputing frame to port %s\n" (OP.Port.string_of_port
   * port);*)
  match port with 
    | OP.Port.Port(port) -> 
        if Hashtbl.mem st.Switch.int_ports port then
          let out_p = ( Hashtbl.find st.Switch.int_ports port)  in
            (Net.Manager.send_raw out_p.Switch.mgr out_p.Switch.port_name [frame];
            return ())
            else
              return (Printf.printf "Port %d not registered \n" port)
    | OP.Port.No_port -> return ()
    | OP.Port.In_port ->
        let port = (OP.Port.int_of_port tupple.OP.Match.in_port) in 
          if Hashtbl.mem st.Switch.int_ports port then
            let out_p = ( Hashtbl.find st.Switch.int_ports port)  in
              (Net.Manager.send_raw out_p.Switch.mgr out_p.Switch.port_name [frame];
              return ())
              else
                return (Printf.printf "Port %d not registered \n" port)
                  (*           | Table
                   *           | Normal
                   *           | Flood
                   *           | All 
                   *           | Controller -> generate a packet out. 
                   *           | Local -> can I inject this frame to the network
                   *           stack?  *)
    | _ -> return (Printf.printf "Not implemented output port\n")

let rec apply_of_actions st tuple actions frame = 
  match actions with 
    | [] -> return ()
    | head :: actions -> 
        match head with
          | Entry.FORWARD (port) ->
              forward_frame st tuple port frame; 
              apply_of_actions st tuple actions frame
          | Entry.SET_DL_SRC(eaddr) ->
             (* Printf.printf "setting src mac addr to %s\n" (OP.eaddr_to_string
              * eaddr); *)
              set_frame_bits frame 48 48 (OP.bitstring_of_eaddr eaddr);
              apply_of_actions st tuple actions frame
          | Entry.SET_DL_DST(eaddr) ->
             (* Printf.printf "setting dst mac addr to %s\n" (OP.eaddr_to_string
              * eaddr); *)
              set_frame_bits frame 0 48 (OP.bitstring_of_eaddr eaddr);
              apply_of_actions st tuple actions frame
          | _ ->
              (Printf.printf "Unsupported action\n");
              apply_of_actions st tuple actions frame


let portnum = ref 0

let process_frame intf_name frame = 
  (* roughly,
   * + examine frame
   * + extract OF headers
   * + match against st.table
   *   + if match, update counters, execute actions
   *   + else, forward to controller/drop, depending on config
   *)
  if (Hashtbl.mem st.Switch.ports intf_name ) then
    let p = (Hashtbl.find st.Switch.ports intf_name) in
    let in_port = (OP.Port.port_of_int p.Switch.port_id) in (* Hashtbl.find   in *)
    let tupple = (OP.Match.parse_from_raw_packet in_port frame ) in 
      if (Hashtbl.mem st.Switch.table.Table.entries tupple) then 
        let entry = (Hashtbl.find st.Switch.table.Table.entries tupple) in
          (* st.Switch.stats.Switch.n_hits <- (st.Switch.stats.Switch.n_hits + 
           * (Int64.of_int 1)); *)
          (apply_of_actions st tupple entry.Entry.actions frame);
         else
           (Printf.printf "generating Packet_out\n"; 
            (* st.Switch.stats.Switch.n_missed <-
             * st.Switch.stats.Switch.n_missed + 1;*)
            let addr = "\x11\x11\x11\x11\x11\x11" in 
              add_flow tupple [(Entry.SET_DL_SRC (addr));
                               (Entry.SET_DL_DST (addr));
                               (Entry.FORWARD (OP.Port.port_of_int 2)) ; ]; 
              return ())

         else
           return ()

let add_port sw mgr intf = 
  Net.Manager.intercept intf process_frame;
  incr portnum;
  let port =  Switch.({port_id=(!portnum); mgr=mgr; 
                       port_name=(Net.Manager.get_intf intf);}) in  
    Hashtbl.add sw.Switch.int_ports !portnum port; 
    Hashtbl.add sw.Switch.ports port.Switch.port_name port;
    sw.Switch.port_feat <- sw.Switch.port_feat @ 
    [(OP.Port.init_port_phy ~port_no:(!portnum) ~name:(port.Switch.port_name) () )]

let process_openflow st =
  (* this is processing from a Channel, so roughly
   * + read OpenFlow message off Channel,
   * + match message and handle accordingly, possibly emitting one or more
   *   messages as a result
   *)

  return ()

type endhost = {
  ip: Nettypes.ipv4_addr;
  port: int;
}

let errornum = ref 1 

let process_of_packet state (remote_addr, remote_port) ofp t = 
    (* let ep = { ip=remote_addr; port=remote_port } in *)
    match ofp with
      | OP.Hello (h, _) (* Reply to HELLO with a HELLO and a feature request *)
        -> (cp "HELLO";
            Channel.write_bitstring t (OP.Header.build_h h) 
            >> Channel.write_bitstring t (OP.build_features_req 0_l) 
            >> Channel.flush t
        )
      | OP.Echo_req (h, bs)  (* Reply to ECHO requests *)
        -> (cp "ECHO_REQ";
            Channel.write_bitstring t (OP.build_echo_resp h bs)
            >> Channel.flush t
        )
      | OP.Features_req (h)  
        -> (cp "FEAT_REQ";
            let res = (OP.Switch.gen_reply_features h Int64.one st.Switch.port_feat) in 
                      Channel.write_bitstring t res;
                      Channel.flush t
        )
      | OP.Get_config_req(h) 
        -> let resp = OP.Switch.init_switch_config in
            Channel.write_bitstring t (OP.Switch.bitstring_of_switch_config 
                                         h.OP.Header.xid resp);
            Channel.flush t
(*
      | OP.Flow_mod(h,fm) 
        -> Printf.printf "Flow modification received\n"
 *)
      | _ -> 
          OS.Console.log "New packet received"; 
          incr errornum; 
          let err = (BITSTRING{(OP.Header.build_h 
                                        (OP.Header.create  OP.Header.ERROR 
                                           (OP.Header.get_len + 4 )  
                                           (Int32.of_int !errornum))):(OP.Header.get_len*8):bitstring;
                                            (* OFPET_BAD_REQUEST
                                            * OFPBRC_BAD_TYPE*)
                                            1:16; 1:16})  in 
            Channel.write_bitstring t err;
            Channel.flush t; 
            return () 
  

let rec rd_data len t = 
  match len with
    | 0 -> return Bitstring.empty_bitstring
    | _ -> lwt data = (Channel.read_some ~len:len t) in 
           let nbytes = ((Bitstring.bitstring_length data)/8) in
           lwt more_data = (rd_data (len - nbytes) t) in
           return (Bitstring.concat [ data; more_data ])


let listen mgr loc init =
  let controller (remote_addr, remote_port) t =
    let rs = Nettypes.ipv4_addr_to_string remote_addr in
    Log.info "OpenFlow Controller" "+ %s:%d" rs remote_port; 
    init mgr st; 
      st.Switch.controllers <- (st.Switch.controllers @ [t]);
    let rec echo () =
      try_lwt
        lwt hbuf = Channel.read_some ~len:OP.Header.get_len t in
        let ofh  = OP.Header.parse_h hbuf in
        let dlen = ofh.OP.Header.len - OP.Header.get_len in 
        lwt dbuf = rd_data dlen t in
        let ofp  = OP.parse ofh dbuf in
        process_of_packet st (remote_addr, remote_port) ofp t  
        >> echo ()
      with
        | Nettypes.Closed -> 
            (* TODO Need to remove the t from st.Switch.controllers *)
            return ()
        | OP.Unparsed (m, bs) -> cp (sp "# unparsed! m=%s" m); echo ()

    in echo () 
  in
  Channel.listen mgr (`TCPv4 (loc, controller))


  (* Switch initialization should be irrelevant to whether the switch is connected to a 
   * to a controller. *)
  (*  st <- Switch.(
   { ports = (Hashtbl.create 0);
   table = Table.({ tid = 0_L; entries = [] });
   stats = { n_frags=0_L; n_hits=0_L; n_missed=0_L; n_lost=0_L };
   p_sflow = 0_l;
   })
   in *)
(* let listen mgr loc init =

  let switch (rip, rpt) t = 
    let rs = ipv4_addr_to_string rip in
      Log.info "OpenFlow Switch" "+ %s:%d" rs rpt;
      return ()  in    
    Net.Channel.listen mgr (`TCPv4 (loc, switch))*)

  (* having initialised state, now need to 
   * + install input handler for each device
   * + wait on any device having input, and process when ready
   *)
  (*    
   let rec input device = 
   lwt frame = return () in
   process_frame st frame
   >> input device
   in
   input dummy (* how to handle multiple devices *)
   <?> process_openflow st *)
 
