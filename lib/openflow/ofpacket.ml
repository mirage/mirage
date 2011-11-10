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

(* XXX of dubious merit - but we don't do arithmetic so prefer the
   documentation benefits for now *)
type uint8  = char
type uint16 = int
type uint32 = int32
type uint64 = int64

let uint8_of_int i = Char.chr i

(* XXX network specific types that should have a proper home *)

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

let eaddr_to_string s = 
  let l = String.length s in
  let hp s i = sp "%02x" (int_of_char s.[i]) in
  String.concat ":" (Array.init l (fun i -> hp s i) |> Array.to_list)

let eaddr_is_broadcast s =
  match s with
    | "\xFF\xFF\xFF\xFF\xFF\xFF" -> true
    | _ -> false

let bytes_of_bitstring bits = Bitstring.string_of_bitstring bits
let ipv4_addr_of_bytes bs = 
  ((bs.[0] |> int32_of_byte <<< 24) ||| (bs.[1] |> int32_of_byte <<< 16) 
    ||| (bs.[2] |> int32_of_byte <<< 8) ||| (bs.[3] |> int32_of_byte))

(*********************************************************************** *)

(* for readability *)
type vendor = uint32
type queue_id = uint32
type datapath_id = uint64

module Header = struct 
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

  let get_len = 8 

  let parse_h bits = 
    (bitmatch bits with
      | { 1:8:int; t:8; len:16; xid:32 }
        -> { ver=byte 1; ty=msg_code_of_int t; len; xid }
      | { _ } -> raise (Unparsable ("parse_h", bits))
    )

  let string_of_h h =
    sp "ver:%d type:%s len:%d xid:0x%08lx" 
      (int_of_byte h.ver) (string_of_msg_code h.ty) h.len h.xid

  let create ty len xid  =
    { ver=byte 1; ty; len; xid }

  let get_xid m = m.xid
  let get_ty m = m.ty

  let build_h h = 
    BITSTRING { (int_of_byte h.ver):8; (int_of_msg_code h.ty):8;
                h.len:16; h.xid:32
              }
end
    
(*
module Output = struct
  type t = {
    port:port;
    max_len: int;
  }
  let get_len = 8
  let bitstring_of_output port max_len =
    {port=(port_of_int port); max_len=max_len}
  let output_to_bitstring m = 
    match m with  
      | Output.t m 
        -> (BITSTRING{0:16; 8:16; (int_of_port m.port):16; m.max_len:16})
      | _            -> Bitstring.empty_bitstring 

end
*)

module Queue = struct
  type h = {
    queue_id: queue_id;
  }

  type t = NONE | MIN_RATE of uint16
end

module Port = struct
  type t = 
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

  let string_of_phy ph = 
    (sp "port_no:%d,hw_addr:%s,name:%s" 
       ph.port_no (eaddr_to_string ph.hw_addr) ph.name)

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

  let rec parse_port_stats_reply data = 
    bitmatch data with 
      | {port_no:16; _:48; rx_packets:64; tx_packets:64;
         rx_bytes:64; tx_bytes:64; rx_dropped:64; tx_dropped:64;
         rx_errors:64; tx_errors:64; rx_frame_err:64; rx_over_err:64;
         rx_crc_err:64; collisions:64;data_left:-1:bitstring} -> 
        List.append [{port_no; rx_packets; tx_packets; rx_bytes; 
                      tx_bytes; rx_dropped; tx_dropped; rx_errors; tx_errors; 
                      rx_frame_err; rx_over_err; rx_crc_err; collisions;}] 
          (parse_port_stats_reply data_left)
      | {_} ->
        []

  let rec string_of_port_stats_reply ports = 
    match ports with 
      | [] -> ""
      | h::q -> (
        sp "port_no:%d,rx_packets:%Ld,tx_packets:%Ld,rx_bytes:%Ld,\
            tx_bytes:%Ld,rx_dropped:%Ld,tx_dropped:%Ld,rx_errors:%Ld,\
            tx_errors:%Ld,rx_frame_err:%Ld,rx_over_err:%Ld,rx_crc_err:%Ld,\
            collisions:%Ld\n%s" 
          h.port_no 
          h.rx_packets h.tx_packets h.rx_bytes h.tx_bytes 
          h.rx_dropped h.tx_dropped h.rx_errors h.tx_errors 
          h.rx_frame_err h.rx_over_err h.rx_crc_err h.collisions
          (string_of_port_stats_reply q))

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

  let string_of_status st = 
    (sp "Port status,reason:%s,%s" (string_of_reason st.reason)
       (string_of_phy st.desc) )

  let status_of_bitstring bits =
    bitmatch bits with 
      | {reason:8:int;_:56;data:-1:bitstring} ->
        {reason=(reason_of_int reason); desc=(parse_phy data)}

      | {_} -> invalid_arg "Failed to parse port status message"
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
        -> { output=false; 
             set_vlan_id=false; set_vlan_pcp=false; strip_vlan=false; 
             set_dl_src=false; set_dl_dst=false; 
             set_nw_src=false; set_nw_dst=false; set_nw_tos=false; 
             set_tp_src=false; set_tp_dst=false; 
             enqueue=false; vendor=true; 
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
  let full_wildcard = 
    { in_port=true; dl_vlan=true; dl_src=true; 
      dl_dst=true; dl_type=true; nw_proto=true; 
      tp_src=true; tp_dst=true; nw_src=(char_of_int 32); 
      nw_dst=(char_of_int 32); dl_vlan_pcp=true; nw_tos=true;
    }
  let exact_match = 
    { in_port=false; dl_vlan=false; dl_src=false; 
      dl_dst=false; dl_type=false; nw_proto=false; 
      tp_src=false; tp_dst=false; nw_src=(char_of_int 0); 
      nw_dst=(char_of_int 0); dl_vlan_pcp=false; nw_tos=false;
    }
  let l2_match = 
    { in_port=false;dl_vlan=false;dl_src=false;dl_dst=false;
      dl_type=false;nw_proto=true;tp_src=true;tp_dst=true;
      nw_src=(char_of_int 32);nw_dst=(char_of_int 32);dl_vlan_pcp=false; 
      nw_tos=true
    }
  let l3_match = 
    { in_port=false;dl_vlan=false;dl_vlan_pcp=false;dl_src=false;
      dl_dst=false;dl_type=false;nw_proto=false;nw_tos=false;
      nw_src=(char_of_int 0);nw_dst=(char_of_int 0);tp_src=true;tp_dst=true;
    }

  let wildcard_to_bitstring m = 
    (BITSTRING {
      0:10; m.nw_tos:1;m.dl_vlan_pcp:1;(int_of_char m.nw_dst):6;
      (int_of_char m.nw_src):6;m.tp_dst:1;m.tp_src:1;m.nw_proto:1;
      m.dl_type:1;m.dl_dst:1;m.dl_src:1;m.dl_vlan:1;m.in_port:1
    })

  let string_of_wildcard h = 
    sp "in_port:%s,dl_vlan:%s,dl_src:%s,dl_dst:%s,dl_type:%s,\
        nw_proto:%s,tp_src:%s,tp_dst:%s,nw_src:%d,nw_dst:%d,\
        dl_vlan_pcp:%s,nw_tos:%s" 
      (string_of_bool h.in_port) 
      (string_of_bool h.dl_vlan) (string_of_bool h.dl_src)
      (string_of_bool h.dl_dst) (string_of_bool h.dl_type)
      (string_of_bool h.nw_proto) (string_of_bool h.tp_src)
      (string_of_bool h.tp_dst) (int_of_char h.nw_src) 
      (int_of_char h.nw_dst) (string_of_bool h.dl_vlan_pcp) 
      (string_of_bool h.nw_tos)
      
  let bitstring_to_wildcards bits = 
    (bitmatch bits with
      | { _:10; nw_tos:1; dl_vlan_pcp:1; nw_dst:6; nw_src:6; 
          tp_dst:1; tp_src:1; nw_proto:1; dl_type:1;
          dl_dst:1; dl_src:1; dl_vlan:1; in_port:1 
        } -> { nw_tos;dl_vlan_pcp;
               nw_dst=(char_of_int nw_dst); nw_src=(char_of_int nw_src); 
               tp_dst; tp_src; nw_proto; 
               dl_type; dl_dst; dl_src; dl_vlan; in_port;
             }
    )
end     

module Match = struct
  type t = {
    wildcards: Wildcards.t;
    in_port: Port.t;
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

  let match_to_bitstring m = 
    Bitstring.concat [
      (Wildcards.wildcard_to_bitstring m.wildcards);  
      (BITSTRING{(Port.int_of_port m.in_port):16; m.dl_src:48:string;
                 m.dl_dst:48:string; m.dl_vlan:16; 
                 (int_of_char m.dl_vlan_pcp):8; 0:8;
                 m.dl_type:16; (int_of_char m.nw_tos):8; 
                 (int_of_char m.nw_proto):8; 
                 0:16; m.nw_src:32; m.nw_dst:32; m.tp_src:16; m.tp_dst:16 })]
  let bitstring_to_match bits = 
    (bitmatch bits with
      | { wildcards:32:bitstring;
          in_port:16; 
          dl_src:48:string; dl_dst:48:string; dl_vlan:16; dl_vlan_pcp:8; 
          _:8;
          dl_type:16; nw_tos:8; nw_proto:8; _:16; nw_src:32; nw_dst:32; 
          tp_src:16; tp_dst:16 } 
        -> { wildcards = (Wildcards.bitstring_to_wildcards wildcards); 
             in_port=(Port.port_of_int in_port); dl_src; dl_dst; dl_vlan;         
             dl_vlan_pcp=(char_of_int dl_vlan_pcp); 
             dl_type; nw_src; nw_dst; nw_tos=(char_of_int nw_tos); 
             nw_proto=(char_of_int nw_proto); tp_src; tp_dst;} 
    )

  let get_len = 40 (*4+2+6+6+2+1+1+2+1+1+2+4+4+2+2*)
  let get_dl_src m = m.dl_src
  let get_dl_dst m = m.dl_dst

  let null_eaddr = "\x00\x00\x00\x00\x00\x00"
  let create_flow_match wildcards
      ?(in_port = 0) ?(dl_src=null_eaddr) ?(dl_dst=null_eaddr) 
      ?(dl_vlan=0xffff) ?(dl_vlan_pcp=(char_of_int 0)) ?(dl_type=0) 
      ?(nw_tos=(char_of_int 0)) 
      ?(nw_proto=(char_of_int 0)) 
      ?(nw_src=(Int32.of_int 0)) ?(nw_dst=(Int32.of_int 0)) 
      ?(tp_src=0) ?(tp_dst=0)
      () = 
    { wildcards; in_port=(Port.port_of_int in_port); 
      dl_src; dl_dst; dl_vlan; dl_vlan_pcp; dl_type; 
      nw_src; nw_dst; nw_tos; nw_proto; tp_src; tp_dst; }

  let parse_from_raw_packet in_port bits = 
    bitmatch bits with
        (* TODO: add 802.11q case *)
        (* TCP *)
        {dmac:48:string; smac:48:string; 0x0800:16; 4:4; ihl:4; tos:8; 
         _:56; 6:8; _:16; 
         nw_src:32; nw_dst:32; _:(ihl-5)*32:; tp_src:16; tp_dst:16;
         _:-1:bitstring }
        -> { wildcards =Wildcards.exact_match; 
             in_port=in_port;dl_src=smac; dl_dst=dmac; dl_vlan=0xffff;
             dl_vlan_pcp=(char_of_int 0);dl_type=0x0800; nw_src=nw_src; 
             nw_dst=nw_dst; nw_tos=(char_of_int tos); 
             nw_proto=(char_of_int 6); tp_src=tp_src;
             tp_dst=tp_dst}
      (* UDP *)
      | {dmac:48:string; smac:48:string; 0x0800:16; 4:4; ihl:4; tos:8; 
         _:56; 17:8; _:16; 
         nw_src:32; nw_dst:32; _:(ihl-5)*32; tp_src:16; tp_dst:16; 
         _:-1:bitstring } 
        -> { wildcards =Wildcards.exact_match; in_port=in_port;
             dl_src=smac; dl_dst=dmac; dl_vlan=0xffff;
             dl_vlan_pcp=(char_of_int 0);dl_type=0x0800; nw_src=nw_src; 
             nw_dst=nw_dst; nw_tos=(char_of_int tos); 
             nw_proto=(char_of_int 17); tp_src=tp_src; tp_dst=tp_dst
           }
      (* IP *)
      | {dmac:48:string; smac:48:string; 0x0800:16; 4:4; ihl:4; tos:8; 
         _:56; nw_proto:8; _:16; 
         nw_src:32; nw_dst:32; _:(ihl-5)*32:bitstring; _:-1:bitstring } ->
        {wildcards =Wildcards.l3_match; in_port=in_port;dl_src=smac; 
         dl_dst=dmac; dl_vlan=0xffff;
         dl_vlan_pcp=(char_of_int 0);dl_type=0x0800; nw_src=nw_src; 
         nw_dst=nw_dst; nw_tos=(char_of_int tos); 
         nw_proto=(char_of_int nw_proto); tp_src=0;
         tp_dst=0}
      (* Ethernet only *)
      | {dmac:48:string; smac:48:string; etype:16; _:-1:bitstring}
        -> { wildcards=Wildcards.l2_match; 
             in_port=in_port;dl_src=smac; dl_dst=dmac; dl_vlan=0xffff;
             dl_vlan_pcp=(char_of_int 0);dl_type=etype; 
             nw_src=(Int32.of_int 0); 
             nw_dst=(Int32.of_int 0); nw_tos=(char_of_int 0); 
             nw_proto=(char_of_int 0); tp_src=0;
             tp_dst=0}

  let match_to_string m = 
    match (m.dl_type, (int_of_char m.nw_proto)) with
      | (0x0800, 17) 
        -> (sp "dl_src:%s,dl_dst:%s,dl_type:ip,nw_src:%s,nw_dst:%s,\
               nw_tos:%d,nw_proto:%d,tp_dst:%d,tp_src:%d" 
              (eaddr_to_string m.dl_src) (eaddr_to_string m.dl_dst) 
              (ipv4_to_string m.nw_src) (ipv4_to_string m.nw_dst)
              (Char.code m.nw_tos) (Char.code m.nw_proto) m.tp_dst 
              m.tp_src 
        )
      | (0x0800, _) 
        -> (sp "dl_src:%s,dl_dst:%s,dl_type:ip,nw_src:%s,\
                          nw_dst:%s,nw_tos:%d,nw_proto:%d" 
              (eaddr_to_string m.dl_src) (eaddr_to_string m.dl_dst) 
              (ipv4_to_string m.nw_src) (ipv4_to_string m.nw_dst)
              (Char.code m.nw_tos) (Char.code m.nw_proto)
        )
      | (_, _) -> (sp "dl_src:%s,dl_dst:%s,dl_type:0x%x"
                     (eaddr_to_string m.dl_src) 
                     (eaddr_to_string m.dl_dst) m.dl_type  
      )

end

module Flow = struct
  type action = 
    | Output of (Port.t * int)
    | SET_VLAN_VID | SET_VLAN_PCP | STRIP_VLAN 
    | SET_DL_SRC | SET_DL_DST 
    | SET_NW_SRC | SET_NW_DST | SET_NW_TOS 
    | SET_TP_SRC | SET_TP_DST
    | ENQUEUE |VENDOR_ACT 

  let action_of_int = function
    |  0 -> Output((Port.port_of_int 0),0)
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
    | 0xffff -> VENDOR_ACT
    | _ -> invalid_arg "action_of_int"
  and int_of_action = function 
    | Output _     -> 0 
    | SET_VLAN_VID -> 1 
    | SET_VLAN_PCP -> 2
    | STRIP_VLAN -> 3
    | SET_DL_SRC -> 4
    | SET_DL_DST -> 5
    | SET_NW_SRC -> 6
    | SET_NW_DST -> 7
    | SET_NW_TOS -> 8
    | SET_TP_SRC -> 9
    | SET_TP_DST -> 10
    | ENQUEUE -> 11
    | VENDOR_ACT -> 0xffff
  and string_of_action = function
    | Output (port, max_len) 
      -> sp "OUTPUT %d %d " (Port.int_of_port port) max_len
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
    | VENDOR_ACT   -> sp "VENDOR"
  let len_of_action = function
    | Output (_,_) -> 8
    | _            -> 8   
  let action_to_bitstring m =
    match m with  
      | Output (port, max_len)
        -> (BITSTRING{0:16; 8:16; (Port.int_of_port port):16; max_len:16})
      | _ -> Bitstring.empty_bitstring 

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
    action: (action list);
  }

  let parse_flow_stats bits =
    (* A recursive function to parse each entry *) 
    let rec parse_flow_stat bits =  
      (bitmatch bits with 
        | { entry_length:16; table_id:8; _:8; 
            of_match:(Match.get_len)*8:bitstring; duration_sec:32;
            duration_usec:32;priority:16;idle_timeout:16;
            hard_timeout:16; _:48; cookie:64;
            packet_count:64;byte_count:64; 
            _:(entry_length - Match.get_len - 48)*8:bitstring;
            data:-1:bitstring
          } -> (List.append [{entry_length; table_id=(char_of_int table_id); 
                              of_match=(Match.bitstring_to_match of_match); 
                              duration_sec;
                              duration_usec;priority;idle_timeout;
                              hard_timeout;cookie;
                              packet_count;byte_count;action=[];}] 
                  (parse_flow_stat data))
        | {_} -> [] 
      ) in 
    parse_flow_stat bits

  let string_of_flow_stat flow = 
    sp "table_id:%d,%s,duration:%ld.%ld,priority:%d,idle:%d,hard:%d,\
        cookie:%Ld,packets:%Ld,bytes:%Ld" 
      (int_of_char flow.table_id) (Match.match_to_string flow.of_match)
      flow.duration_sec flow.duration_usec
      flow.priority flow.idle_timeout flow.hard_timeout flow.cookie 
      flow.packet_count flow.byte_count

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
    in_port: Port.t;
    reason: reason;
    data: Bitstring.t;
  }
  let parse_packet_in bits = 
    (bitmatch bits with
      | { buffer_id:32; _:16; in_port:16; reason:8; _:8; 
          data:-1:bitstring }
        -> { buffer_id;
             in_port=(Port.port_of_int in_port);
             reason=(reason_of_int reason);
             data
           }
    )
  let string_of_packet_in p = 
    sp "Packet_in: buffer_id:%ld in_port:%s reason:%s"
      p.buffer_id (Port.string_of_port p.in_port) (string_of_reason p.reason)
end

module Packet_out = struct
  type t = {
    of_header : Header.h;
    buffer_id: uint32;
    in_port: Port.t;
    actions: Flow.action array;
    data : Bitstring.t;
  }

  let get_len = Header.get_len + 8
  let create ?(xid = (Int32.of_int 0)) ?(buffer_id =( Int32.of_int (-1) )) 
      ?(actions = [| |] ) 
      ?(data=Bitstring.empty_bitstring) ~in_port () =
    let size = ref (get_len + ((Bitstring.bitstring_length data) / 8)) in 
    (Array.iter (fun a -> size:= !size + (Flow.len_of_action a) ) actions);
    {of_header=(Header.(create PACKET_OUT (!size) xid)); buffer_id; in_port; 
     actions; data;} 

  let packet_out_to_bitstring m =
    let action_len = ref (0) in
    (Array.iter (fun a -> action_len := !action_len + (Flow.len_of_action a)) 
       m.actions);
    let packet = ( 
      [(Header.build_h m.of_header); 
       (BITSTRING{m.buffer_id:32; 
                  (Port.int_of_port m.in_port):16; 
                  (!action_len):16})
      ] @ (
        Array.to_list (Array.map (fun a -> (Flow.action_to_bitstring a)) 
                         m.actions)
      ) @ [m.data] ) 
    in 
    Bitstring.concat packet
end

(* this is a message only from the controller to the switch so
 * we can allow to parse inline the packet *)
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
    of_header: Header.h;
    of_match: Match.t;
    cookie: uint64;
    (*cookie_mask: uint64;
      table_id: byte; *)
    command: command;
    idle_timeout: uint16;
    hard_timeout: uint16;
    priority: uint16;
    buffer_id: int32;
    out_port: Port.t;
    (* out_group: uint32; *)
    flags: flags;
    actions: Flow.action array;
  }

  let total_len = 
    let ret = 24 + (Header.get_len) + (Match.get_len) in 
    ret

  let create flow_match cookie command ?(priority = 0) 
      ?(idle_timeout = 60) ?(hard_timeout = 0)
      ?(buffer_id =  -1 ) ?(out_port = Port.No_port) 
      ?(flags ={send_flow_rem=false;emerg=false;overlap=false;}) actions () =
    let size = ref (total_len) in 
    (Array.iter (fun a -> size:= !size + (Flow.len_of_action a) ) actions);

    {of_header=(Header.(create FLOW_MOD  !size (Int32.of_int 0))); 
     of_match=flow_match; cookie; command=command; 
     idle_timeout; hard_timeout; priority; buffer_id=(Int32.of_int buffer_id); 
     out_port;flags; actions;}

  let flow_mod_to_bitstring m =
    (* Fix flags *)
    let packet = ( List.append [(Header.build_h m.of_header); 
                                (Match.match_to_bitstring m.of_match);
                                (BITSTRING{m.cookie:64; (int_of_command m.command):16; 
                                           m.idle_timeout:16;m.hard_timeout:16; 
                                           m.priority:16; m.buffer_id:32; 
                                           (Port.int_of_port m.out_port):16; 0:13; 
                                           m.flags.overlap:1; m.flags.emerg:1; m.flags.send_flow_rem:1})]
                     (Array.to_list (Array.map (fun a -> (Flow.action_to_bitstring a) ) m.actions ) ) ) in 
    Bitstring.concat packet
end

module Flow_removed = struct
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
    | IDLE_TIMEOUT -> "IDLE_TIMEOUT"
    | HARD_TIMEOUT -> "HARD_TIMEOUT"
    | DELETE -> "DELETE"


  type t = { 
    of_match:Match.t;
    cookie:uint64;
    priority:uint16;
    reason:reason;
    duration_sec:uint32;
    duration_nsec:uint32;
    idle_timeout:uint16;
    packet_count:uint64;
    byte_count:uint64;
  }
  let flow_removed_of_bitstring bits =
    (bitmatch bits with
      | { of_match:(Match.get_len * 8):bitstring;
          cookie:64; priority:16; reason:8; _:8; duration_sec:32;
          duration_nsec:32; idle_timeout:16; _:16; packet_count:64; byte_count:64}
        -> { of_match=(Match.bitstring_to_match of_match);
             cookie; priority; reason=(reason_of_int reason); duration_sec; duration_nsec; 
             idle_timeout; packet_count; byte_count;}
    )

  let string_of_flow_removed m = 
    sp "flow:%s cookie:%s priority:%d reason:%s duration:%s.%s ifle_timeout:%d packet:%s bytes:%s"   
      (Match.match_to_string m.of_match) (Int64.to_string m.cookie) 
      m.priority (string_of_reason m.reason) (Int32.to_string m.duration_sec) 
      (Int32.to_string m.duration_nsec)  m.idle_timeout (Int64.to_string m.packet_count)
      (Int64.to_string  m.byte_count)
end

module Port_mod = struct
  type t = {
    port_no: Port.t;
    hw_addr: eaddr;
    config: Port.config;
    mask: Port.config;
    advertise: Port.features;
  }
end

module Stats = struct
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
    imfr_desc: bytes;
    hw_desc: bytes;
    sw_desc: bytes;
    serial_num: bytes;
    dp_desc: bytes;
  }

  type req_hdr = {
    ty : uint16;
    flags: uint16;
  }

  type stats_type = DESC | FLOW | AGGREGATE | TABLE | PORT | QUEUE | VENDOR

        (*  type flow = {
        (*    length: int; *)
            table_id: uint8;
            of_match: Match.t;
            duration_sec: uint32;
            duration_usec: uint32;
            priority: uint16;
            idle_timeout: uint16;
            hard_timeout: uint16;
            cookie: uint64;
            packet_count: uint64;
            byte_count: uint64;
            }
        *)

  let int_of_req_type typ = 
    match typ with 
      | DESC -> 0
      | FLOW -> 1
      | AGGREGATE -> 2
      | TABLE -> 3
      | PORT -> 4
      | QUEUE -> 5
      | VENDOR -> 6
        
  let get_len typ =
    match typ with
      | FLOW -> (Header.get_len + 4 + Match.get_len + 4 )
      | AGGREGATE -> (Header.get_len + 4 + Match.get_len + 4 )
      | PORT ->  (Header.get_len + 12)
      | QUEUE -> (Header.get_len + 12)
      | _ -> (Header.get_len + 4)


  let create_flow_stat_req flow_match
      ?(table_id=0xff) ?(out_port=Port.No_port) ?(xid=(Int32.of_int 0)) () = 
    let snd_xid = if xid==(Int32.of_int 0) then (Random.int32 Int32.max_int) else xid in 
    let header = Header.build_h (Header.create Header.STATS_REQ (get_len FLOW) snd_xid) in 
    BITSTRING{(header):(Header.get_len * 8):bitstring; (int_of_req_type FLOW):16;0:16;
              (Match.match_to_bitstring flow_match):(Match.get_len * 8):bitstring;
              table_id:8;0:8;(Port.int_of_port out_port):16}

  let create_aggr_flow_stat_req flow_match ?(table_id=0xff) ?(out_port=Port.No_port) 
      ?(xid=(Int32.of_int 0)) () = 
    let snd_xid = (if xid==(Int32.of_int 0) then (Random.int32 Int32.max_int) else xid) in 
    let header = (Header.build_h (Header.create Header.STATS_REQ (get_len AGGREGATE) snd_xid)) in 
    BITSTRING{(header):(Header.get_len * 8):bitstring; (int_of_req_type AGGREGATE):16;0:16;
              (Match.match_to_bitstring flow_match):(Match.get_len * 8):bitstring;
              table_id:8;0:8;(Port.int_of_port out_port):16}

  let create_vendor_stat_req ?(xid=(Int32.of_int 0)) () = 
    let snd_xid = (if xid==(Int32.of_int 0) then (Random.int32 Int32.max_int) else xid) in 
    let header = (Header.build_h (Header.create Header.STATS_REQ (get_len VENDOR) snd_xid)) in 
    BITSTRING{(header):(Header.get_len * 8):bitstring; (int_of_req_type
                                                          DESC):16;0:16}

  let create_table_stat_req ?(xid=(Int32.of_int 0)) () = 
    let snd_xid = (if xid==(Int32.of_int 0) then (Random.int32 Int32.max_int) else xid) in 
    let header = (Header.build_h (Header.create Header.STATS_REQ (get_len TABLE) snd_xid)) in 
    BITSTRING{(header):(Header.get_len * 8):bitstring; (int_of_req_type TABLE):16;0:16}

  let create_queue_stat_req ?(xid=(Int32.of_int 0))
      ?(queue_id=0xffffffffl) ?(port=Port.No_port) () =
    let snd_xid = (if xid==(Int32.of_int 0) then (Random.int32 Int32.max_int) else xid) in 
    let header = (Header.build_h (Header.create Header.STATS_REQ (get_len QUEUE) snd_xid)) in 
    BITSTRING{(header):(Header.get_len * 8):bitstring; (int_of_req_type QUEUE):16;0:16;
              (Port.int_of_port port):16;0:16;queue_id:32}

  let create_port_stat_req ?(xid=(Int32.of_int 0)) ?(port=Port.No_port) () = 
    let snd_xid = (if xid==(Int32.of_int 0) then (Random.int32 Int32.max_int) else xid) in 
    let header = (Header.build_h (Header.create Header.STATS_REQ (get_len PORT) snd_xid)) in 
    BITSTRING{(header):(Header.get_len * 8):bitstring; (int_of_req_type PORT):16;
              0:16;(Port.int_of_port port):16;(Int64.of_int 0):48}

  type req = 
    | Desc_req of req_hdr
    | Flow_req of req_hdr *  Match.t * table_id * Port.t
    | Aggregate_req of req_hdr * Match.t * table_id * Port.t
    | Table_req of req_hdr
    | Port_req of req_hdr * Port.t
    | Queue_req of req_hdr * Port.t * queue_id
    | Vendor_req of req_hdr


  type resp_hdr = {
    st_ty: stats_type;
    more_to_follow: bool;
  }

  let int_of_stats_type = function
    | DESC -> 0
    | FLOW -> 1
    | AGGREGATE -> 2 
    | TABLE -> 3 
    | PORT -> 4
    | QUEUE -> 5
    | VENDOR -> 0xffff

  let stats_type_of_int = function
    | 0 -> DESC
    | 1 -> FLOW
    | 2 -> AGGREGATE
    | 3 -> TABLE
    | 4 -> PORT
    | 5 -> QUEUE
    | 0xffff -> VENDOR
    | _ -> invalid_arg "stats type invalid int"

  type resp = 
    | Desc_resp of resp_hdr * desc
    | Flow_resp of resp_hdr * (Flow.stats list)
    | Aggregate_resp of resp_hdr * aggregate
    | Table_resp of resp_hdr * (table list)
    | Port_resp of resp_hdr * (Port.stats list)
    | Queue_resp of resp_hdr * (queue list)
    | Vendor_resp of resp_hdr

  let rec parse_table_stats_reply data = 
    bitmatch data with 
      | {table_id:8; _:24; name:32*8:string; wildcards:32:bitstring; 
         max_entries:32;active_count:32;lookup_count:64;matched_count:64; 
         data_left:-1:bitstring} -> 
        List.append [{table_id=(table_id_of_int table_id); name;
                      wildcards=(Wildcards.bitstring_to_wildcards wildcards); max_entries;active_count;
                      lookup_count;matched_count;}] (parse_table_stats_reply data_left)
      | {_} -> []
          
  let rec string_of_table_stats_reply tables =
    match tables with
      | [] -> ""
      | h::q -> sp "table_id:%s,name:%s,wildcard:%s,max_entries:%ld,
          active_count:%ld,lookup_count:%Ld,matched_count:%Ld\n%s" 
        (string_of_table_id h.table_id) h.name (Wildcards.string_of_wildcard
                                                  h.wildcards) h.max_entries h.active_count h.lookup_count 
        h.matched_count (string_of_table_stats_reply q) 

  let parse_stats bits =
    ( bitmatch bits with 
      | {0:16; _:15; more_to_follow:1; imfr_desc:256:string;
         hw_desc:256:string; sw_desc:256:string; serial_num:32:string;
         dp_desc:256:string} ->
        Desc_resp({st_ty=DESC; more_to_follow=false;}, {imfr_desc; hw_desc;
                                                        sw_desc; serial_num; dp_desc;})
      | {1:16; _:15; more_to_follow:1; flows:-1:bitstring}
        -> Flow_resp({st_ty=FLOW; more_to_follow;}, (Flow.parse_flow_stats flows))
      | {2:16; _:15; more_to_follow:1; data:-1:bitstring} ->
        ( bitmatch data with 
          | { packet_count:64; byte_count:64; flow_count:32 } ->
            Aggregate_resp({st_ty=AGGREGATE; more_to_follow;},
                           {packet_count;  byte_count; flow_count;})
          | {_} -> invalid_arg "Failed to parse aggr data" )
      | {3:16; _:15; more_to_follow:1; data:-1:bitstring} ->
        Table_resp({st_ty=TABLE; more_to_follow},
                   (parse_table_stats_reply data) )
      | {4:16; more_to_follow:1; data:-1:bitstring} ->
        Port_resp({st_ty=PORT;more_to_follow},
                  (Port.parse_port_stats_reply data)) 
      | {ty:16; 0:15; more_to_follow:1} -> 
        Vendor_resp({st_ty=(stats_type_of_int ty);
                     more_to_follow;}))

  let rec string_of_flow_stats flows = 
    match flows with 
        [] -> ""
      | flow::flow_list -> sp "%s\n%s" (Flow.string_of_flow_stat
                                          flow) (string_of_flow_stats flow_list)

  let string_of_stats stats =
    match stats with
        Desc_resp(hdr, desc) ->
          (sp "Stats Desc %s %s %s %s %s" desc.imfr_desc desc.hw_desc
             desc.sw_desc desc.serial_num desc.dp_desc)
      | Flow_resp(hdr, flows) -> 
        (sp "Stats Flows %s" (string_of_flow_stats flows))
      | Aggregate_resp (hdr, aggr) ->
        (sp "Aggr flow stats %Ld %Ld %ld" aggr.packet_count
           aggr.byte_count aggr.flow_count)
      | Port_resp(resp, ports) ->
        (sp "port stats %s" (Port.string_of_port_stats_reply ports))
      | Table_resp(resp, tables) ->
        (sp "table stats %s" ) (string_of_table_stats_reply tables)
      | Vendor_resp(resp) ->
        (sp "vendor resp")
      | _ -> invalid_arg "Invalide stats resp object"

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


let build_features_req xid = 
  Header.build_h (Header.(create FEATURES_REQ 8 xid))

let build_echo_resp h bs = 
  let rh = Header.(build_h (create ECHO_RESP get_len (get_xid h))) in
  BITSTRING { rh:(8*(Header.get_len)):bitstring; bs:-1:bitstring }

type t =
  | Hello of Header.h * Bitstring.t
  | Error of Header.h  * error_code
  | Echo_req of Header.h  * Bitstring.t
  | Echo_resp of Header.h  * Bitstring.t
  | Vendor of Header.h  * vendor * Bitstring.t

  | Features_req of Header.h
  | Features_resp of Header.h  * Switch.features
  | Get_config_req of Header.h 
  | Get_config_resp of Header.h  * Switch.config    
  | Set_config of Header.h  * Switch.config    

  | Packet_in of Header.h  * Packet_in.t
  | Flow_removed of Header.h  * Flow_removed.t
  | Port_status of Header.h  * Port.status

  | Packet_out of Header.h  * Packet_out.t * Bitstring.t
  | Flow_mod of Header.h  * Flow_mod.t
  | Port_mod of Header.h  * Port_mod.t

  | Stats_req of Header.h  * Stats.req
  | Stats_resp of Header.h  * Stats.resp

  | Barrier_req of Header.h 
  | Barrier_resp of Header.h 

  | Queue_get_config_req of Header.h * Port.t
  | Queue_get_config_resp of Header.h * Port.t * Queue.t array

let parse h bits = 
  Header.(match (get_ty h) with
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
    | FLOW_REMOVED -> Flow_removed(h, (Flow_removed.flow_removed_of_bitstring bits))
    | STATS_RESP -> Stats_resp (h, (Stats.parse_stats bits))
    | PORT_STATUS -> Port_status(h, (Port.status_of_bitstring bits)) 
    | _ -> raise (Unparsed ("_", bits))
  )
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
