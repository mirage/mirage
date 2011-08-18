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

module Bitstring = struct
  include Bitstring
  let offset_of_bitstring bits = 
    let (_, offset, _) = bits in offset
end

let sp = Printf.sprintf
let pr = Printf.printf
let ep = Printf.eprintf

exception Unparsable of string * Bitstring.bitstring

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

(*
let test_hello_world () = 
	OS.Console.log "Hello World"

*)
(* XXX definitely of dubious merit - but we don't do arithmetic... *)
type uint16 = int
type uint32 = int32
type uint64 = int64

type ipv4 = int32
let ipv4_to_string i =   
  sp "%ld.%ld.%ld.%ld" 
    ((i &&& 0x0_ff000000_l) >>> 24) ((i &&& 0x0_00ff0000_l) >>> 16)
    ((i &&& 0x0_0000ff00_l) >>>  8) ((i &&& 0x0_000000ff_l)       )

type byte = char
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

type port = 
  | Max | In_port | Table | Normal | Flood | All 
  | Controller | Local | No_port
  | Port of uint16
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
  | 0x00030004 -> FLOW_MOD_UNSUPPORTED
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
  | FLOW_MOD_UNSUPPORTED     -> 0x00030004
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
| Hello | Error | Echo_req | Echo_resp | Vendor 
| Features_req | Features_resp
| Get_config_req | Get_config_resp | Set_config
| Packet_in | Flow_removed | Port_status | Packet_out
| Flow_mod | Port_mod | Stats_req | Stats_resp
| Barrier_req | Barrier_resp 
| Queue_get_config_req | Queue_get_config_resp
let msg_code_of_int = function
  |  0 -> Hello 
  |  1 -> Error 
  |  2 -> Echo_req
  |  3 -> Echo_resp
  |  4 -> Vendor 
  |  5 -> Features_req
  |  6 -> Features_resp
  |  7 -> Get_config_req
  |  8 -> Get_config_resp
  |  9 -> Set_config
  | 10 -> Packet_in
  | 11 -> Flow_removed
  | 12 -> Port_status
  | 13 -> Packet_out
  | 14 -> Flow_mod
  | 15 -> Port_mod
  | 16 -> Stats_req
  | 17 -> Stats_resp
  | 18 -> Barrier_req
  | 19 -> Barrier_resp 
  | 20 -> Queue_get_config_req
  | 21 -> Queue_get_config_resp
  | _ -> invalid_arg "msg_of_int"
and int_of_msg_code = function
  | Hello                 ->  0
  | Error                 ->  1
  | Echo_req              ->  2
  | Echo_resp             ->  3
  | Vendor                ->  4
  | Features_req          ->  5
  | Features_resp         ->  6
  | Get_config_req        ->  7
  | Get_config_resp       ->  8
  | Set_config            ->  9
  | Packet_in             -> 10
  | Flow_removed          -> 11
  | Port_status           -> 12
  | Packet_out            -> 13
  | Flow_mod              -> 14
  | Port_mod              -> 15
  | Stats_req             -> 16
  | Stats_resp            -> 17
  | Barrier_req           -> 18
  | Barrier_resp          -> 19
  | Queue_get_config_req  -> 20
  | Queue_get_config_resp -> 21
and string_of_msg_code = function
  | Hello                 -> sp "Hello"
  | Error                 -> sp "Error"
  | Echo_req              -> sp "Echo_req"
  | Echo_resp             -> sp "Echo_resp"
  | Vendor                -> sp "Vendor"
  | Features_req          -> sp "Features_req"
  | Features_resp         -> sp "Features_resp"
  | Get_config_req        -> sp "Get_config_req"
  | Get_config_resp       -> sp "Get_config_resp"
  | Set_config            -> sp "Set_config"
  | Packet_in             -> sp "Packet_in"
  | Flow_removed          -> sp "Flow_removed"
  | Port_status           -> sp "Port_status"
  | Packet_out            -> sp "Packet_out"
  | Flow_mod              -> sp "Flow_mod"
  | Port_mod              -> sp "Port_mod"
  | Stats_req             -> sp "Stats_req"
  | Stats_resp            -> sp "Stats_resp"
  | Barrier_req           -> sp "Barrier_req"
  | Barrier_resp          -> sp "Barrier_resp"
  | Queue_get_config_req  -> sp "Queue_get_config_req"
  | Queue_get_config_resp -> sp "Queue_get_config_resp"

type vendor = uint32
type queue_id = uint32

type features = {
  datapath_id : uint64;
  n_buffers : uint32;
  n_tables : byte;
  unused_caps : bytes;
  arp_match_ip : bool;
  queue_stats: bool;
  ip_reasm: bool;
  stp: bool;
  port_stats: bool;
  table_stats: bool;
  flow_stats: bool;
  actions_supported: uint32;
}

type config = {
  reasm: bool;
  drop: bool;
  miss_send_len: uint16;
}

type in_reason = No_match | Action
let in_reason_of_int = function
  | 0 -> No_match
  | 1 -> Action
  | _ -> invalid_arg "in_reason_of_int"
and int_of_in_reason = function
  | No_match -> 0
  | Action   -> 1
and string_of_in_reason = function
  | No_match -> sp "NO_MATCH"
  | Action   -> sp "ACTION"
  
type packet_in = {
  buffer_id : uint32;
  total_len : uint16;
  in_port : port;
  reason : in_reason;
}

type wildcards = {
	nw_tos: bool;
	dl_vlan_pcp: bool;
	nw_dst: byte;
	nw_src: byte;
	tp_dst: bool; 
	tp_src: bool; 
	nw_proto: bool; 
	dl_type: bool; 
	dl_dst: bool; 
	dl_src: bool; 
	dl_vlan: bool; 
	wildcard_in_port: bool; 
}

type of_match = {
	wildcards: wildcards;
	match_in_port: port;
	dl_src: eaddr;
	dl_dst: eaddr;
	dl_vlan: uint16;
	dl_vlan_pcp: byte;
	dl_type: uint16;
	nw_tos: byte;
	nw_proto: byte;
	nw_src: uint32;
	nw_dst: uint32;
	tp_src: uint16;
	tp_dst: uint16;
}

type removed_reason = IDLE_TIMEOUT | HARD_TIMEOUT | DELETE
let removed_reason_of_int = function
  | 0 -> IDLE_TIMEOUT
  | 1 -> HARD_TIMEOUT
  | 2 -> DELETE
  | _ -> invalid_arg "removed_reason_of_int"
and int_of_removed_reason = function
  | IDLE_TIMEOUT -> 0
  | HARD_TIMEOUT -> 1
  | DELETE -> 2
and string_of_removed_reason = function
  | IDLE_TIMEOUT -> 0
  | HARD_TIMEOUT -> 1
  | DELETE -> 2

type flow = {
  of_match : of_match;
  cookie : uint64;
  priority : uint16;
  flow_reason : removed_reason;
  duration_sec: uint32;
  duration_usec: uint32;
  idle_timeout : uint16;
  packet_count : uint64;
  byte_count : uint64;
}
  
type port_config = {
	no_packet_in: bool;
	no_fwd: bool;
	no_flood: bool;
	no_recv_stp: bool;
	no_recv: bool;
	no_stp: bool;
	port_down: bool;
}

type phy_port_feature = {
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

type phy_port = {
	port_no: uint16;
	hw_addr: eaddr;
	name: string;
	config: port_config;  
	stp_forward: bool;
	stp_learn: bool;
	link_down: bool;
	curr: phy_port_feature;
	advertised: phy_port_feature;
	supported: phy_port_feature;
	peer: phy_port_feature;
}

type port_status_reason = ADD | DEL | MOD
let port_status_reason_of_int = function
  | 0 -> ADD
  | 1 -> DEL
  | 2 -> MOD
  | _ -> invalid_arg "port_status_reason_of_int"
and int_of_port_status_reason = function
  | ADD -> 0
  | DEL -> 1
  | MOD -> 2
and string_of_port_status_reason = function
  | ADD -> sp "ADD"
  | DEL -> sp "DEL"
  | MOD -> sp "MOD"

type port_status = {
  port_reason: port_status_reason;
  phy_port : phy_port;
}

type packet_out = {
  packet_out_buffer_id : uint32;
  packet_out_in_port : port;
  actions_len : uint16;
  actions: bytes;
}

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

type flow_mod = {
  of_match : of_match;
  cookie : uint64;
  command : command;
  idle_timeout : uint16;
  hard_timeout : uint16;
  priority : uint16;
  flow_mod_buffer_id : uint32;
  out_port : port;
  emerg: bool;
  overlap: bool;
  send_flow_rem : bool;
}

type port_mod = {
  port_no : port;
  hw_addr : eaddr;
  config : port_config;
  mask : port_config;
  advertise : phy_port_feature;
}

type table_id = All | Emergency 
let table_id_of_int = function
  | 0xff -> All
  | 0xfe -> Emergency
  | _ -> invalid_arg "table_id_of_int"
and int_of_table_id = function
  | All -> 0xff
  | Emergency -> 0xfe
and string_of_table_id = function
  | All -> sp "All"
  | Emergency -> sp "Emergency"

type stats_req_payload = 
  | Desc
  | Flow of of_match * table_id * port
  | Aggregate of of_match * table_id * port
  | Table
  | Port of port
  | Queue of port * queue_id
  | Vendor

type stats_req_h = {
  ty : uint16;
  flags: uint16;
}

type desc = {
  mfr_desc: bytes;
  hw_desc: bytes;
  sw_desc: bytes;
  serial_num: bytes;
  dp_desc: bytes;
}

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

type flow_stats = {
  entry_length : uint16;
  table_id: byte;
  of_match: of_match;
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

type aggregate_stats = {
  packet_count: uint64;
  byte_count: uint64;
  flow_count: uint32;
}

type table_stats = {
  table_id: byte;
  name : string;
  wildcards : wildcards;
  max_entries: uint32;
  active_count: uint32;
  lookup_count: uint64;
  matched_count: uint64;
}

type port_stats = {
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

type queue_stats = {
  port_no: uint16;
  queue_id: uint32;
  tx_bytes: uint64;
  tx_packets: uint64;
  tx_errors: uint64;
}

type stats_resp_payload = 
  | Desc of desc
  | Flow of flow_stats
  | Aggregate of aggregate_stats
  | Table of table_stats
  | Port of port_stats
  | Queue of queue_stats
  | Vendor

type stats_resp_h = {
  st_ty : uint16;
  more_to_follow : bool;
}

type payload =
  | Hello of bytes
  | Error of error_code
  | Echo_req of bytes
  | Echo_resp of bytes
  | Vendor of vendor * bytes
  | Features_req of bytes
  | Features_resp of features * bytes
  | Get_config_req
  | Get_config_resp of config    
  | Set_config of config    
  | Packet_in of packet_in * bytes
  | Flow_removed of flow
  | Port_status of port_status
  | Packet_out of packet_out * bytes
  | Flow_mod of flow_mod * bytes
  | Port_mod of port_mod
  | Stats_req of stats_req_h * stats_req_payload
  | Stats_resp of stats_resp_h * stats_resp_payload
  | Barrier_req
  | Barrier_resp
  | Queue_get_config_req of port
  | Queue_get_config_resp of port * bytes    

type h = {
  version : byte;
  ty : msg_code;
  length : uint16;
  xid : uint32;
	data : payload;
}

let parse_of_header bits = 
	let base = Bitstring.offset_of_bitstring bits in 
		( bitmatch bits with 
			| { 1 : 8 : int; of_type:8;
					len:16; xid:32; bits:-1:bitstring} -> (
				(* TODO: Raise an exeption and close connection if openfow version is not valid *)
				let of_pkt = {version= (char_of_int 1);ty=(msg_code_of_int of_type);length=len;xid=xid; data=Hello("")} in 
				of_pkt
			)
			| { _ } -> raise (Unparsable ("parse_of", bits))
		)	
 
let parse_of bits = 
	let base = Bitstring.offset_of_bitstring bits in 
		( bitmatch bits with  
			| { 1:8; 6:8; len:16; xid:32; datapath_id:64; n_buffers:32; n_tables:8; 
					unused_caps: 24:string; arp_match_ip : 1; queue_stats: 1; ip_reasm: 1; 
					stp: 1; port_stats:1; table_stats: 1; flow_stats: 1; actions: 32; 
					bits:-1:bitstring}  -> (
										 {version= (char_of_int 1);ty=(msg_code_of_int 6);length=len;xid=xid; 
										 data=Features_resp({datapath_id = datapath_id;n_buffers = n_buffers;
														 n_tables = (char_of_int n_tables); unused_caps = unused_caps;
 														 arp_match_ip = arp_match_ip;queue_stats = queue_stats;
														 ip_reasm = ip_reasm;stp = stp;port_stats = port_stats;
														 table_stats = table_stats; flow_stats = flow_stats;
														 actions_supported = actions }, "")}
					)
			| { 1:8; 10:8; len:16; xid:32; buffer_id:32; total_len:16; in_port : 16; reason:8;
					bits:-1:bitstring}  -> (
										 {version= (char_of_int 1);ty=(msg_code_of_int 10);length=len;xid=xid; 
										 data=Packet_in({buffer_id=buffer_id;total_len=total_len;
										 in_port=(port_of_int in_port); 
  									 reason=(in_reason_of_int reason)}, (bytes_of_bitstring bits))}
				)			
		| { 1:8; 0:8; len:16; xid:32; bits:-1:bitstring} -> 
				(* TODO: Raise an exeption and close connection if openfow version is not valid *)
				({version=(char_of_int 1);ty=(msg_code_of_int 0);length=len;xid=xid; data=Hello("")})
				|  { 1:8; 2:8; len:16; xid:32; bits:-1:bitstring} -> 
				({version=(char_of_int 1);ty=(msg_code_of_int 2);length=len;xid=xid; data=Echo_req("")})
				| { version:8; of_type:8; len:16; xid:32; bits:-1:bitstring} -> 
				({version=(char_of_int version);ty=(msg_code_of_int of_type);length=len;xid=xid; data=Hello("")})
				| {_ } -> raise (Unparsable ("parse_of", bits))
)	

