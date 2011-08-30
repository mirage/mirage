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

let sp = Printf.sprintf
let pr = Printf.printf
let ep = Printf.eprintf

exception Unparsable of string * Bitstring.bitstring
exception Unparsed of string * Bitstring.bitstring

let (|>) x f = f x (* pipe *)
let (>>) f g x = g (f x) (* functor pipe *)
let (||>) l f = List.map f l (* element-wise pipe *)

let (+++) x y = Int32.add x y

let (&&&) x y = Int32.logand x y
let (|||) x y = Int32.logor x y
let (^^^) x y = Int32.logxor x y
let (<<<) x y = Int32.shift_left x y
let (>>>) x y = Int32.shift_right_logical x y

let join c l = String.concat c l
let stop (x, bits) = x (* drop remainder to stop parsing and demuxing *) 

type int16 = int

(* Of dubious merit - but we don't do arithmetic so prefer the
   documentation benefits for now *)
type uint8  = char
type uint16 = int
type uint32 = int32
type uint64 = int64

let uint8_of_int i = Char.chr i

(* Network specific types *)

type ipv4 = uint32
let ipv4_to_string i =   
  sp "%ld.%ld.%ld.%ld" 
    ((i &&& 0x0_ff000000_l) >>> 24) ((i &&& 0x0_00ff0000_l) >>> 16)
    ((i &&& 0x0_0000ff00_l) >>>  8) ((i &&& 0x0_000000ff_l)       )

type byte = uint8
let byte (i:int) : byte = Char.chr i
let int_of_byte b = int_of_char b
let int32_of_byte b = b |> int_of_char |> Int32.of_int
let int32_of_int (i:int) = Int32.of_int i

type bytes = string
type eaddr = bytes
let bytes_to_hex_string bs = 
  bs |> Array.map (fun b -> sp "%02x." (int_of_byte b))
let bytes_of_bitstring bits = Bitstring.string_of_bitstring bits
let ipv4_addr_of_bytes bs = 
  ((bs.[0] |> int32_of_byte <<< 24) ||| (bs.[1] |> int32_of_byte <<< 16) 
    ||| (bs.[2] |> int32_of_byte <<< 8) ||| (bs.[3] |> int32_of_byte))

(* ********************************************************************** *)

type vendor = uint32
type queue_id = uint32
type datapath_id = uint64

type table_id = All | Emergency | Table of uint8
let table_id_of_int = function
  | 0xff -> All
  | 0xfe -> Emergency
  | i when ((0 <= i) && (i < 0xfe)) -> Table (byte i)
  | _ -> invalid_arg "table_id_of_int"
and int_of_table_id = function
  | All -> 0xff
  | Emergency -> 0xfe
  | Table i -> int_of_byte i
and string_of_table_id = function
  | All -> sp "All"
  | Emergency -> sp "Emergency"
  | Table i -> sp "Table (%d)" (int_of_byte i)

type action = 
  | OUTPUT 
  | SET_VLAN_VID | SET_VLAN_PCP | STRIP_VLAN 
  | SET_DL_SRC | SET_DL_DST 
  | SET_NW_SRC | SET_NW_DST | SET_NW_TOS 
  | SET_TP_SRC | SET_TP_DST
  | ENQUEUE | VENDOR
let action_of_int = function
  |  0 -> OUTPUT 
  |  1 -> SET_VLAN_VID
  |  2 -> SET_VLAN_PCP
  |  3 -> STRIP_VLAN 
  |  4 -> SET_DL_SRC
  |  5 -> SET_DL_DST 
  |  6 -> SET_NW_SRC
  |  7 -> SET_NW_DST
  |  8 -> SET_NW_TOS 
  |  9 -> SET_TP_SRC
  | 10 -> SET_TP_DST
  | 11 -> ENQUEUE
  | 0xffff -> VENDOR
  | _ -> invalid_arg "action_of_int"
and int_of_action = function
  | OUTPUT       -> 0
  | SET_VLAN_VID -> 1
  | SET_VLAN_PCP -> 2
  | STRIP_VLAN   -> 3
  | SET_DL_SRC   -> 4
  | SET_DL_DST   -> 5
  | SET_NW_SRC   -> 6
  | SET_NW_DST   -> 7
  | SET_NW_TOS   -> 8
  | SET_TP_SRC   -> 9
  | SET_TP_DST   -> 10
  | ENQUEUE      -> 11
  | VENDOR       -> 0xffff
and string_of_action = function
  | OUTPUT       -> sp "OUTPUT"
  | SET_VLAN_VID -> sp "SET_VLAN_VID"
  | SET_VLAN_PCP -> sp "SET_VLAN_PCP"
  | STRIP_VLAN   -> sp "STRIP_VLAN"
  | SET_DL_SRC   -> sp "SET_DL_SRC"
  | SET_DL_DST   -> sp "SET_DL_DST"
  | SET_NW_SRC   -> sp "SET_NW_SRC"
  | SET_NW_DST   -> sp "SET_NW_DST"
  | SET_NW_TOS   -> sp "SET_NW_TOS"
  | SET_TP_SRC   -> sp "SET_TP_SRC"
  | SET_TP_DST   -> sp "SET_TP_DST"
  | ENQUEUE      -> sp "ENQUEUE"
  | VENDOR       -> sp "VENDOR"

type port = 
  | Max | In_port | Table | Normal | Flood | All 
  | Controller | Local | No_port
  | Port of int16
let port_of_int = function
  | 0xff00 -> Max
  | 0xfff8 -> In_port
  | 0xfff9 -> Table
  | 0xfffa -> Normal
  | 0xfffb -> Flood
  | 0xfffc -> All
  | 0xfffd -> Controller
  | 0xfffe -> Local
  | 0xffff -> No_port
  | p      -> Port p
and int_of_port = function
  | Max        -> 0xff00
  | In_port    -> 0xfff8
  | Table      -> 0xfff9
  | Normal     -> 0xfffa
  | Flood      -> 0xfffb
  | All        -> 0xfffc
  | Controller -> 0xfffd
  | Local      -> 0xfffe
  | No_port    -> 0xffff
  | Port p     -> p
and string_of_port = function
  | Max        -> sp "MAX"
  | In_port    -> sp "IN_PORT"
  | Table      -> sp "TABLE"
  | Normal     -> sp "NORMAL"
  | Flood      -> sp "FLOOD"
  | All        -> sp "ALL"
  | Controller -> sp "CONTROLLER"
  | Local      -> sp "LOCAL"
  | No_port    -> sp "NO_PORT"
  | Port p     -> sp "PORT(%d)" p

module Queue = struct
  type h = {
    queue_id: queue_id;
  }

  type t = NONE | MIN_RATE of uint16
end

module Port = struct
  type config = {
    port_down: bool;
    no_stp: bool;
    no_recv: bool;
    no_recv_stp: bool;
    no_flood: bool;
    no_fwd: bool;
    no_packet_in: bool;
  }
  let parse_config bits = 
    (bitmatch bits with
      | { port_down:1; no_stp:1; no_recv:1; no_recv_stp:1; 
          no_flood:1; no_fwd:1; no_packet_in:1
        } -> { port_down; no_stp; no_recv; no_recv_stp; no_flood;
               no_fwd; no_packet_in;
             }
    )

  type features = {
    pause_asym: bool;
    pause: bool;
    autoneg: bool;
    fiber: bool;
    copper: bool;
    f_10GB_FD: bool;
    f_1GB_FD: bool;
    f_1GB_HD: bool;
    f_100MB_FD: bool;
    f_100MB_HD: bool;
    f_10MB_FD: bool;
    f_10MB_HD: bool;
  }
  let parse_features bits = 
    (bitmatch bits with
      | { pause_asym:1; pause:1; autoneg:1; fiber:1; copper:1;
          f_10GB_FD:1; f_1GB_FD:1; f_1GB_HD:1;
          f_100MB_FD:1; f_100MB_HD:1; f_10MB_FD:1; f_10MB_HD:1
        } -> { pause_asym; pause; autoneg; fiber; copper;
               f_10GB_FD; f_1GB_FD; f_1GB_HD; f_100MB_FD; f_100MB_HD;
               f_10MB_FD; f_10MB_HD;
             }
    )

  type state = {
    link_down: bool;
    stp_listen: bool;
    stp_learn: bool;
    stp_forward: bool;
    stp_block: bool;
    stp_mask: bool;
  }
  let parse_state bits = 
    (bitmatch bits with
      | { link_down:1; stp_listen:1; stp_learn:1; stp_forward:1;
          stp_block:1; stp_mask:1
        } -> { link_down; stp_listen; stp_learn; stp_forward;
               stp_block; stp_mask; 
             }
    )

  type phy = {
    port_no: uint16;
    hw_addr: eaddr;
    name: string;
    config: config;  
    state: state;    
    curr: features;
    advertised: features;
    supported: features;
    peer: features;
  }
  let max_name_len = 16
  let phy_len = 48
  let parse_phy bits = 
    (bitmatch bits with
      | { port_no:16; hw_addr:(6*8):string; 
          name:(max_name_len*8):string;
          config:32:bitstring;
          state:32:bitstring;
          curr:32:bitstring;
          advertised:32:bitstring;
          supported:32:bitstring;
          peer:32:bitstring
        } -> { port_no; hw_addr; name;
               config = parse_config config;
               state = parse_state state;
               curr = parse_features curr;
               advertised = parse_features advertised;
               supported = parse_features supported;
               peer = parse_features peer;
             }
    )
     
  type stats = {
    port_no: uint16;
    rx_packets: uint64;
    tx_packets: uint64;
    rx_bytes: uint64;
    tx_bytes: uint64;
    rx_dropped: uint64;
    tx_dropped: uint64;
    rx_errors: uint64;
    tx_errors: uint64;
    rx_frame_err: uint64;
    rx_over_err: uint64;
    rx_crc_err: uint64;
    collisions: uint64;
  }

  type reason = ADD | DEL | MOD
  let reason_of_int = function
    | 0 -> ADD
    | 1 -> DEL
    | 2 -> MOD
    | _ -> invalid_arg "reason_of_int"
  and int_of_reason = function
    | ADD -> 0
    | DEL -> 1
    | MOD -> 2
  and string_of_reason = function
    | ADD -> sp "ADD"
    | DEL -> sp "DEL"
    | MOD -> sp "MOD"

  type status = {
    reason: reason;
    desc: phy;
  }
end

module Switch = struct
  type capabilities = {
    flow_stats: bool;
    table_stats: bool;
    port_stats: bool;    
    stp: bool;
    ip_reasm: bool;
    queue_stats: bool;    
    arp_match_ip: bool;
  }
  let parse_capabilities bits = 
    (bitmatch bits with
      | { arp_match_ip:1; queue_stats:1; ip_reasm:1; 
          stp:1; port_stats:1; table_stats:1; flow_stats:1
        } -> { arp_match_ip; queue_stats; ip_reasm; stp; 
               port_stats; table_stats; flow_stats
             }                    
    )

  type actions = {
    output: bool;
    set_vlan_id: bool;
    set_vlan_pcp: bool;
    strip_vlan: bool;
    set_dl_src: bool;
    set_dl_dst: bool;
    set_nw_src: bool;
    set_nw_dst: bool;
    set_nw_tos: bool;
    set_tp_src: bool;
    set_tp_dst: bool;
    enqueue: bool;
    vendor: bool;
  }
  let parse_actions bits = 
    (bitmatch bits with
      | { (0xffff):16 }
        -> { output=false; set_vlan_id=false; set_vlan_pcp=false; strip_vlan=false; 
             set_dl_src=false; set_dl_dst=false; set_nw_src=false; set_nw_dst=false; 
             set_nw_tos=false; set_tp_src=false; set_tp_dst=false; enqueue=false; 
             vendor=true;
           }
          
      | { output:1; set_vlan_id:1; set_vlan_pcp:1; strip_vlan:1; 
          set_dl_src:1; set_dl_dst:1; set_nw_src:1; set_nw_dst:1; 
          set_nw_tos:1; set_tp_src:1; set_tp_dst:1; enqueue:1
        }
        -> { output; set_vlan_id; set_vlan_pcp; strip_vlan;
             set_dl_src; set_dl_dst; set_nw_src; set_nw_dst;
             set_nw_tos; set_tp_src; set_tp_dst; enqueue; 
             vendor=false
           } 
    )                   

  type features = {
    datapath_id: datapath_id;
    n_buffers: uint32;
    n_tables: byte;    
    capabilities: capabilities;
    actions: actions;
    ports: Port.phy list;
  }
  let parse_features bits = 
    let parse_phys bits = 
      let rec aux ports bits = 
        match Bitstring.bitstring_length bits with
          | 0 -> ports
          | l when (l >= 8*Port.phy_len) 
              -> (let p = Port.parse_phy bits in
                  aux 
                    (p :: ports) 
                    (bits |> Bitstring.dropbits (8*Port.phy_len))
              )
          | _ -> raise (Unparsable("parse_phys", bits))
      in 
      aux [] bits
    in
    (bitmatch bits with
	  | { datapath_id:64; 
          n_buffers:32; 
          n_tables:8; 
		  _:24; (* pad *)
          capabilities:32:bitstring;
          actions:32:bitstring;
          phys:-1:bitstring
        } -> { datapath_id = datapath_id; 
               n_buffers = n_buffers;
			   n_tables = (byte n_tables); 
 			   capabilities = parse_capabilities capabilities;
               actions = parse_actions actions;
               ports = parse_phys phys;
             }
    )

  type config = {
    drop: bool;
    reasm: bool;
    miss_send_len: uint16;
  }
end

module Wildcards = struct
  type t = {
    in_port: bool; 
    dl_vlan: bool; 
    dl_src: bool; 
    dl_dst: bool; 
    dl_type: bool; 
    nw_proto: bool; 
    tp_src: bool; 
    tp_dst: bool; 
    
    nw_src: byte; (* XXX *)
    nw_dst: byte; (* XXX *)
    
    dl_vlan_pcp: bool;
    nw_tos: bool;
  }
end     

module Match = struct
  type t = {
    wildcards: Wildcards.t;
    in_port: port;
    dl_src: eaddr;
    dl_dst: eaddr;
    dl_vlan: uint16;
    dl_vlan_pcp: byte;
    dl_type: uint16;
    nw_src: uint32;
    nw_dst: uint32;
    nw_tos: byte;
    nw_proto: byte;
    tp_src: uint16;
    tp_dst: uint16;
  }
end

module Flow = struct
  type reason = IDLE_TIMEOUT | HARD_TIMEOUT | DELETE
  let reason_of_int = function
    | 0 -> IDLE_TIMEOUT
    | 1 -> HARD_TIMEOUT
    | 2 -> DELETE
    | _ -> invalid_arg "reason_of_int"
  and int_of_reason = function
    | IDLE_TIMEOUT -> 0
    | HARD_TIMEOUT -> 1
    | DELETE -> 2
  and string_of_reason = function
    | IDLE_TIMEOUT -> 0
    | HARD_TIMEOUT -> 1
    | DELETE -> 2

  type stats = {
    entry_length: uint16;
    table_id: byte;
    of_match: Match.t;
    duration_sec: uint32;
    duration_usec: uint32;
    priority: uint16;
    idle_timeout: uint16;
    hard_timeout: uint16;
    cookie: uint64;
    packet_count: uint64;
    byte_count: uint64;
    action: action;
  }

  type t = {
    cookie: uint64;
    priority: uint16;
    reason: reason;
    table_id: byte;
    duration_sec: uint32;
    duration_usec: uint32;
    idle_timeout: uint16;
    packet_count: uint64;
    byte_count: uint64;
  }
end

module Packet_in = struct
  type reason = No_match | Action
  let reason_of_int = function
    | 0 -> No_match
    | 1 -> Action
    | _ -> invalid_arg "reason_of_int"
  and int_of_reason = function
    | No_match -> 0
    | Action   -> 1
  and string_of_reason = function
    | No_match -> sp "NO_MATCH"
    | Action   -> sp "ACTION"
      
  type t = {
    buffer_id: uint32;
    in_port: port;
    reason: reason;
    data: Bitstring.t;
  }
  let parse_packet_in bits = 
    (bitmatch bits with
      | { buffer_id:32; _:16; in_port:16; reason:8; _:8; 
          data:-1:bitstring }
        -> { buffer_id;
             in_port=(port_of_int in_port);
             reason=(reason_of_int reason);
             data
           }
    )
  let string_of_packet_in p = 
    sp "Packet_in: buffer_id:%ld in_port:%s reason:%s"
      p.buffer_id (string_of_port p.in_port) (string_of_reason p.reason)
end

module Packet_out = struct
  type t = {
    buffer_id: uint32;
    in_port: port;
    actions: action array;
  }
end

module Flow_mod = struct
  type command = ADD | MODIFY | MODIFY_STRICT | DELETE | DELETE_STRICT
  let command_of_int = function
    | 0 -> ADD
    | 1 -> MODIFY
    | 2 -> MODIFY_STRICT
    | 3 -> DELETE
    | 4 -> DELETE_STRICT
    | _ -> invalid_arg "command_of_int"
  and int_of_command = function
    | ADD -> 0
    | MODIFY -> 1
    | MODIFY_STRICT -> 2
    | DELETE -> 3
    | DELETE_STRICT -> 4
  and string_of_command = function
    | ADD -> sp "ADD"
    | MODIFY -> sp "MODIFY"
    | MODIFY_STRICT -> sp "MODIFY_STRICT"
    | DELETE -> sp "DELETE"
    | DELETE_STRICT -> sp "DELETE_STRICT"

  type flags = {
    send_flow_rem: bool;
    emerg: bool;
    overlap: bool;
  }
  
  type t = {
    cookie: uint64;
    cookie_mask: uint64;
    table_id: byte;
    command: command;
    idle_timeout: uint16;
    hard_timeout: uint16;
    priority: uint16;
    buffer_id: uint32;
    out_port: port;
    out_group: uint32;
    flags: flags;
    of_match: Match.t;
  }
end

module Port_mod = struct
  type t = {
    port_no: port;
    hw_addr: eaddr;
    config: Port.config;
    mask: Port.config;
    advertise: Port.features;
  }
end

module Stats = struct
  type aggregate = {
    packet_count: uint64;
    byte_count: uint64;
    flow_count: uint32;
  }

  type table = {
    table_id: table_id;
    name: string;
    wildcards: Wildcards.t;
    max_entries: uint32;
    active_count: uint32;
    lookup_count: uint64;
    matched_count: uint64;
  }
  
  type queue = {
    port_no: uint16;
    queue_id: uint32;
    tx_bytes: uint64;
    tx_packets: uint64;
    tx_errors: uint64;
  }

  type desc = {
    mfr_desc: bytes;
    hw_desc: bytes;
    sw_desc: bytes;
    serial_num: bytes;
    dp_desc: bytes;
  }

  type req_hdr = {
    ty : uint16;
    flags: uint16;
  }

  type req = 
    | Desc of req_hdr
    | Flow of req_hdr * Match.t * table_id * port
    | Aggregate of req_hdr * Match.t * table_id * port
    | Table of req_hdr
    | Port of req_hdr * port
    | Queue of req_hdr * port * queue_id
    | Vendor of req_hdr

  type resp_hdr = {
    st_ty: uint16;
    more_to_follow: bool;
  }

  type resp = 
    | Desc of resp_hdr * desc
    | Flow of resp_hdr * Flow.stats
    | Aggregate of resp_hdr * aggregate
    | Table of resp_hdr * table
    | Port of resp_hdr * Port.stats
    | Queue of resp_hdr * queue
    | Vendor of resp_hdr
end

type error_code = 
  | HELLO_INCOMPATIBLE
  | HELLO_EPERM
  | REQUEST_BAD_VERSION
  | REQUEST_BAD_TYPE
  | REQUEST_BAD_STAT
  | REQUEST_BAD_VENDOR
  | REQUEST_BAD_SUBTYPE
  | REQUEST_REQUEST_EPERM
  | REQUEST_BAD_LEN
  | REQUEST_BUFFER_EMPTY
  | REQUEST_BUFFER_UNKNOWN
  | ACTION_BAD_TYPE
  | ACTION_BAD_LEN
  | ACTION_BAD_VENDOR
  | ACTION_BAD_VENDOR_TYPE
  | ACTION_BAD_OUT_PORT
  | ACTION_BAD_ARGUMENT
  | ACTION_EPERM
  | ACTION_TOO_MANY
  | ACTION_BAD_QUEUE
  | FLOW_MOD_ALL_TABLES_FULL
  | FLOW_MOD_OVERLAP
  | FLOW_MOD_EPERM
  | FLOW_MOD_EMERG_TIMEOUT
  | FLOW_MOD_BAD_COMMAND
  | FLOW_MOD_UNSUPPORTED
  | PORT_MOD_BAD_PORT
  | PORT_MOD_BAD_HW_ADDR
  | QUEUE_OP_BAD_PORT
  | QUEUE_OP_BAD_QUEUE
  | QUEUE_OP_EPERM	
let error_code_of_int = function
  | 0x00000000 -> HELLO_INCOMPATIBLE
  | 0x00000001 -> HELLO_EPERM
  | 0x00010000 -> REQUEST_BAD_VERSION
  | 0x00010001 -> REQUEST_BAD_TYPE
  | 0x00010002 -> REQUEST_BAD_STAT
  | 0x00010003 -> REQUEST_BAD_VENDOR
  | 0x00010004 -> REQUEST_BAD_SUBTYPE
  | 0x00010005 -> REQUEST_REQUEST_EPERM
  | 0x00010006 -> REQUEST_BAD_LEN
  | 0x00010007 -> REQUEST_BUFFER_EMPTY
  | 0x00010008 -> REQUEST_BUFFER_UNKNOWN
  | 0x00020000 -> ACTION_BAD_TYPE
  | 0x00020001 -> ACTION_BAD_LEN
  | 0x00020002 -> ACTION_BAD_VENDOR
  | 0x00020003 -> ACTION_BAD_VENDOR_TYPE
  | 0x00020004 -> ACTION_BAD_OUT_PORT
  | 0x00020005 -> ACTION_BAD_ARGUMENT
  | 0x00020006 -> ACTION_EPERM
  | 0x00020007 -> ACTION_TOO_MANY
  | 0x00020008 -> ACTION_BAD_QUEUE
  | 0x00030000 -> FLOW_MOD_ALL_TABLES_FULL
  | 0x00030001 -> FLOW_MOD_OVERLAP
  | 0x00030002 -> FLOW_MOD_EPERM
  | 0x00030003 -> FLOW_MOD_EMERG_TIMEOUT
  | 0x00030004 -> FLOW_MOD_BAD_COMMAND
  | 0x00030005 -> FLOW_MOD_UNSUPPORTED
  | 0x00040000 -> PORT_MOD_BAD_PORT
  | 0x00040001 -> PORT_MOD_BAD_HW_ADDR
  | 0x00050000 -> QUEUE_OP_BAD_PORT
  | 0x00050001 -> QUEUE_OP_BAD_QUEUE
  | 0x00050002 -> QUEUE_OP_EPERM	
  | _ -> invalid_arg "error_code_of_int"
and int_of_error_code = function
  | HELLO_INCOMPATIBLE       -> 0x00000000
  | HELLO_EPERM              -> 0x00000001
  | REQUEST_BAD_VERSION      -> 0x00010000
  | REQUEST_BAD_TYPE         -> 0x00010001
  | REQUEST_BAD_STAT         -> 0x00010002
  | REQUEST_BAD_VENDOR       -> 0x00010003
  | REQUEST_BAD_SUBTYPE      -> 0x00010004
  | REQUEST_REQUEST_EPERM    -> 0x00010005
  | REQUEST_BAD_LEN          -> 0x00010006
  | REQUEST_BUFFER_EMPTY     -> 0x00010007
  | REQUEST_BUFFER_UNKNOWN   -> 0x00010008
  | ACTION_BAD_TYPE          -> 0x00020000
  | ACTION_BAD_LEN           -> 0x00020001
  | ACTION_BAD_VENDOR        -> 0x00020002
  | ACTION_BAD_VENDOR_TYPE   -> 0x00020003
  | ACTION_BAD_OUT_PORT      -> 0x00020004
  | ACTION_BAD_ARGUMENT      -> 0x00020005
  | ACTION_EPERM             -> 0x00020006
  | ACTION_TOO_MANY          -> 0x00020007
  | ACTION_BAD_QUEUE         -> 0x00020008
  | FLOW_MOD_ALL_TABLES_FULL -> 0x00030000
  | FLOW_MOD_OVERLAP         -> 0x00030001
  | FLOW_MOD_EPERM           -> 0x00030002
  | FLOW_MOD_EMERG_TIMEOUT   -> 0x00030003
  | FLOW_MOD_BAD_COMMAND     -> 0x00030004
  | FLOW_MOD_UNSUPPORTED     -> 0x00030005
  | PORT_MOD_BAD_PORT        -> 0x00040000
  | PORT_MOD_BAD_HW_ADDR     -> 0x00040001
  | QUEUE_OP_BAD_PORT        -> 0x00050000
  | QUEUE_OP_BAD_QUEUE       -> 0x00050001
  | QUEUE_OP_EPERM           -> 0x00050002
and string_of_error_code = function
  | HELLO_INCOMPATIBLE       -> sp "HELLO_INCOMPATIBLE"
  | HELLO_EPERM              -> sp "HELLO_EPERM"
  | REQUEST_BAD_VERSION      -> sp "REQUEST_BAD_VERSION"
  | REQUEST_BAD_TYPE         -> sp "REQUEST_BAD_TYPE"
  | REQUEST_BAD_STAT         -> sp "REQUEST_BAD_STAT"
  | REQUEST_BAD_VENDOR       -> sp "REQUEST_BAD_VENDOR"
  | REQUEST_BAD_SUBTYPE      -> sp "REQUEST_BAD_SUBTYPE"
  | REQUEST_REQUEST_EPERM    -> sp "REQUEST_REQUEST_EPERM"
  | REQUEST_BAD_LEN          -> sp "REQUEST_BAD_LEN"
  | REQUEST_BUFFER_EMPTY     -> sp "REQUEST_BUFFER_EMPTY"
  | REQUEST_BUFFER_UNKNOWN   -> sp "REQUEST_BUFFER_UNKNOWN"
  | ACTION_BAD_TYPE          -> sp "ACTION_BAD_TYPE"
  | ACTION_BAD_LEN           -> sp "ACTION_BAD_LEN"
  | ACTION_BAD_VENDOR        -> sp "ACTION_BAD_VENDOR"
  | ACTION_BAD_VENDOR_TYPE   -> sp "ACTION_BAD_VENDOR_TYPE"
  | ACTION_BAD_OUT_PORT      -> sp "ACTION_BAD_OUT_PORT"
  | ACTION_BAD_ARGUMENT      -> sp "ACTION_BAD_ARGUMENT"
  | ACTION_EPERM             -> sp "ACTION_EPERM"
  | ACTION_TOO_MANY          -> sp "ACTION_TOO_MANY"
  | ACTION_BAD_QUEUE         -> sp "ACTION_BAD_QUEUE"
  | FLOW_MOD_ALL_TABLES_FULL -> sp "FLOW_MOD_ALL_TABLES_FULL"
  | FLOW_MOD_OVERLAP         -> sp "FLOW_MOD_OVERLAP"
  | FLOW_MOD_EPERM           -> sp "FLOW_MOD_EPERM"
  | FLOW_MOD_EMERG_TIMEOUT   -> sp "FLOW_MOD_EMERG_TIMEOUT"
  | FLOW_MOD_BAD_COMMAND     -> sp "FLOW_MOD_BAD_COMMAND"
  | FLOW_MOD_UNSUPPORTED     -> sp "FLOW_MOD_UNSUPPORTED"
  | PORT_MOD_BAD_PORT        -> sp "PORT_MOD_BAD_PORT"
  | PORT_MOD_BAD_HW_ADDR     -> sp "PORT_MOD_BAD_HW_ADDR"
  | QUEUE_OP_BAD_PORT        -> sp "QUEUE_OP_BAD_PORT"
  | QUEUE_OP_BAD_QUEUE       -> sp "QUEUE_OP_BAD_QUEUE"
  | QUEUE_OP_EPERM           -> sp "QUEUE_OP_EPERM"

type msg_code =
  | HELLO | ERROR | ECHO_REQ | ECHO_RESP | VENDOR 
  | FEATURES_REQ | FEATURES_RESP
  | GET_CONFIG_REQ | GET_CONFIG_RESP | SET_CONFIG
  | PACKET_IN | FLOW_REMOVED | PORT_STATUS | PACKET_OUT
  | FLOW_MOD | PORT_MOD | STATS_REQ | STATS_RESP
  | BARRIER_REQ | BARRIER_RESP 
  | QUEUE_GET_CONFIG_REQ | QUEUE_GET_CONFIG_RESP
let msg_code_of_int = function
  |  0 -> HELLO 
  |  1 -> ERROR 
  |  2 -> ECHO_REQ
  |  3 -> ECHO_RESP
  |  4 -> VENDOR 
  |  5 -> FEATURES_REQ
  |  6 -> FEATURES_RESP
  |  7 -> GET_CONFIG_REQ
  |  8 -> GET_CONFIG_RESP
  |  9 -> SET_CONFIG
  | 10 -> PACKET_IN
  | 11 -> FLOW_REMOVED
  | 12 -> PORT_STATUS
  | 13 -> PACKET_OUT
  | 14 -> FLOW_MOD
  | 15 -> PORT_MOD
  | 16 -> STATS_REQ
  | 17 -> STATS_RESP
  | 18 -> BARRIER_REQ
  | 19 -> BARRIER_RESP 
  | 20 -> QUEUE_GET_CONFIG_REQ
  | 21 -> QUEUE_GET_CONFIG_RESP
  | _ -> invalid_arg "msg_of_int"
and int_of_msg_code = function
  | HELLO                 ->  0
  | ERROR                 ->  1
  | ECHO_REQ              ->  2
  | ECHO_RESP             ->  3
  | VENDOR                ->  4
  | FEATURES_REQ          ->  5
  | FEATURES_RESP         ->  6
  | GET_CONFIG_REQ        ->  7
  | GET_CONFIG_RESP       ->  8
  | SET_CONFIG            ->  9
  | PACKET_IN             -> 10
  | FLOW_REMOVED          -> 11
  | PORT_STATUS           -> 12
  | PACKET_OUT            -> 13
  | FLOW_MOD              -> 14
  | PORT_MOD              -> 15
  | STATS_REQ             -> 16
  | STATS_RESP            -> 17
  | BARRIER_REQ           -> 18
  | BARRIER_RESP          -> 19
  | QUEUE_GET_CONFIG_REQ  -> 20
  | QUEUE_GET_CONFIG_RESP -> 21
and string_of_msg_code = function
  | HELLO                 -> sp "Hello"
  | ERROR                 -> sp "Error"
  | ECHO_REQ              -> sp "Echo_req"
  | ECHO_RESP             -> sp "Echo_resp"
  | VENDOR                -> sp "Vendor"
  | FEATURES_REQ          -> sp "Features_req"
  | FEATURES_RESP         -> sp "Features_resp"
  | GET_CONFIG_REQ        -> sp "Get_config_req"
  | GET_CONFIG_RESP       -> sp "Get_config_resp"
  | SET_CONFIG            -> sp "Set_config"
  | PACKET_IN             -> sp "Packet_in"
  | FLOW_REMOVED          -> sp "Flow_removed"
  | PORT_STATUS           -> sp "Port_status"
  | PACKET_OUT            -> sp "Packet_out"
  | FLOW_MOD              -> sp "Flow_mod"
  | PORT_MOD              -> sp "Port_mod"
  | STATS_REQ             -> sp "Stats_req"
  | STATS_RESP            -> sp "Stats_resp"
  | BARRIER_REQ           -> sp "Barrier_req"
  | BARRIER_RESP          -> sp "Barrier_resp"
  | QUEUE_GET_CONFIG_REQ  -> sp "Queue_get_config_req"
  | QUEUE_GET_CONFIG_RESP -> sp "Queue_get_config_resp"


type h = {
  ver: uint8;
  ty: msg_code;
  len: uint16;
  xid: uint32;
}
let h_len = 8
let parse_h bits = 
  (bitmatch bits with
	| { 1:8:int; t:8; len:16; xid:32 }
      -> { ver=byte 1; ty=msg_code_of_int t; len; xid }
    | { _ } -> raise (Unparsable ("parse_h", bits))
  )
let string_of_h h =
  sp "ver:%d type:%s len:%d xid:0x%08lx" 
    (int_of_byte h.ver) (string_of_msg_code h.ty) h.len h.xid

let build_h h = 
  BITSTRING { (int_of_byte h.ver):8; (int_of_msg_code h.ty):8;
              h.len:16; h.xid:32
            }

let build_features_req xid = 
  build_h { ver=(byte 1); ty=FEATURES_REQ; len=8; xid }

let build_echo_resp h bs = 
  let rh = build_h { h with ty=ECHO_RESP } in
  BITSTRING { rh:(8*h_len):bitstring; bs:-1:bitstring }  

type t =
  | Hello of h * Bitstring.t
  | Error of h * error_code
  | Echo_req of h * Bitstring.t
  | Echo_resp of h * Bitstring.t
  | Vendor of h * vendor * Bitstring.t

  | Features_req of h
  | Features_resp of h * Switch.features
  | Get_config_req of h
  | Get_config_resp of h * Switch.config    
  | Set_config of h * Switch.config    

  | Packet_in of h * Packet_in.t
  | Flow_removed of h * Flow.t
  | Port_status of h * Port.status

  | Packet_out of h * Packet_out.t * Bitstring.t
  | Flow_mod of h * Flow_mod.t
  | Port_mod of h * Port_mod.t

  | Stats_req of h * Stats.req
  | Stats_resp of h * Stats.resp

  | Barrier_req of h
  | Barrier_resp of h

  | Queue_get_config_req of h * port
  | Queue_get_config_resp of h * port * Queue.t array

let parse h bits = 
  match h.ty with
    | HELLO -> Hello (h, bits)
    | ERROR -> raise (Unparsed ("ERROR", bits))
    | ECHO_REQ -> Echo_req (h, bits)
    | ECHO_RESP -> Echo_resp (h, bits)
    | VENDOR -> raise (Unparsed ("VENDOR", bits))
    
    | FEATURES_REQ -> Features_req (h)
    | FEATURES_RESP -> Features_resp (h, Switch.parse_features bits)
    | GET_CONFIG_REQ -> raise (Unparsed ("GET_CONFIG_REQ", bits))
    | GET_CONFIG_RESP -> raise (Unparsed ("GET_CONFIG_RESP", bits))
    | SET_CONFIG -> raise (Unparsed ("SET_CONFIG", bits))

    | PACKET_IN -> Packet_in (h, Packet_in.parse_packet_in bits)

    | _ -> raise (Unparsed ("_", bits))

(*
  (bitmatch bits with  
	| { 1:8; 10:8; len:16; xid:32; buffer_id:32; total_len:16; in_port : 16; reason:8;
		bits:-1:bitstring}  
      -> Packet_in({ version=(char_of_int 1);
                     ty=(msg_code_of_int 10);
                     length=len;
                     xid=xid; 
                   },
                   { bid=buffer_id;len=total_len;
					 inp=(port_of_int in_port); 
  					 reason=(in_reason_of_int reason)
                   }, (bytes_of_bitstring bits))
*)
