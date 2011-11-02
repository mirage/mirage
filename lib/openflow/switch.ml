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
    fields: OP.Match.t list;
    counters: counters;
    actions: action list;
  }

end

module Table = struct
  type t = {
    tid: cookie;
    mutable entries: Entry.t list;
  }
end

module Switch = struct
  type port = {
    details: OP.Port.phy;
    device: device;
    (* port_id: (OS.Netif.id, int) Hashtbl.t; *)
  }

  type stats = {
    mutable n_frags: uint64;
    mutable n_hits: uint64;
    mutable n_missed: uint64;
    mutable n_lost: uint64;
  }

  type t = {
    mutable ports: (string, int) Hashtbl.t;
    table: Table.t;
    stats: stats;
    p_sflow: uint32; (** probability for sFlow sampling *)
  }

end

let process_frame intf_name frame = 
  (* roughly,
   * + examine frame
   * + extract OF headers
   * + match against st.table
   *   + if match, update counters, execute actions
   *   + else, forward to controller/drop, depending on config
   *)
  Printf.printf "packet received from dev %s\n" intf_name

let portnum = ref 0 

let add_port sw mgr intf = 
  Net.Manager.intercept intf process_frame;
  Hashtbl.add sw.Switch.ports (Net.Manager.get_intf intf) !portnum

let process_openflow st =
  (* this is processing from a Channel, so roughly
   * + read OpenFlow message off Channel,
   * + match message and handle accordingly, possibly emitting one or more
   *   messages as a result
   *)
  return ()

let listen mgr loc init =

  (* Switch initialization should be irrelevant to whether the switch is connected to a 
   * to a controller. *)
  let st = Switch.(
    { ports = (Hashtbl.create 0);
      table = Table.({ tid = 0_L; entries = [] });
      stats = { n_frags=0_L; n_hits=0_L; n_missed=0_L; n_lost=0_L };
      p_sflow = 0_l;
    })
  in
  init mgr st;

  let switch (rip, rpt) t = 
    let rs = ipv4_addr_to_string rip in
    Log.info "OpenFlow Switch" "+ %s:%d" rs rpt;
    return ()
    
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
  in    
  Net.Channel.listen mgr (`TCPv4 (loc, switch))
