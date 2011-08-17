val sp : ('a, unit, string) format -> 'a
val pr : ('a, out_channel, unit) format -> 'a
val ep : ('a, out_channel, unit) format -> 'a
exception Unparsable of string * Bitstring.bitstring
val ( |> ) : 'a -> ('a -> 'b) -> 'b
val ( >> ) : ('a -> 'b) -> ('b -> 'c) -> 'a -> 'c
val ( ||> ) : 'a list -> ('a -> 'b) -> 'b list
val ( +++ ) : int32 -> int32 -> int32
val ( &&& ) : int32 -> int32 -> int32
val ( ||| ) : int32 -> int32 -> int32
val ( ^^^ ) : int32 -> int32 -> int32
val ( <<< ) : int32 -> int -> int32
val ( >>> ) : int32 -> int -> int32
val join : string -> string list -> string
val stop : 'a * 'b -> 'a
type int16 = int
type uint16 = int
type uint32 = int32
type uint64 = int64
type ipv4 = int32
val ipv4_to_string : int32 -> string
type byte = char
val byte : int -> byte
val int_of_byte : char -> int
val int32_of_byte : char -> int32
val int32_of_int : int -> int32
type bytes = string
type eaddr = bytes
val bytes_to_hex_string : char array -> string array
val bytes_of_bitstring : Bitstring.bitstring -> string
val ipv4_addr_of_bytes : string -> int32
type port =
    Max
  | In_port
  | Table
  | Normal
  | Flood
  | All
  | Controller
  | Local
  | No_port
  | Port of uint16
val port_of_int : uint16 -> port
val int_of_port : port -> uint16
val string_of_port : port -> string
type error_code =
    HELLO_INCOMPATIBLE
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
val error_code_of_int : int -> error_code
val int_of_error_code : error_code -> int
val string_of_error_code : error_code -> string
type msg_code =
    Hello
  | Error
  | Echo_req
  | Echo_resp
  | Vendor
  | Features_req
  | Features_resp
  | Get_config_req
  | Get_config_resp
  | Set_config
  | Packet_in
  | Flow_removed
  | Port_status
  | Packet_out
  | Flow_mod
  | Port_mod
  | Stats_req
  | Stats_resp
  | Barrier_req
  | Barrier_resp
  | Queue_get_config_req
  | Queue_get_config_resp
val msg_code_of_int : int -> msg_code
val int_of_msg_code : msg_code -> int
val string_of_msg_code : msg_code -> string
type vendor = uint32
type queue_id = uint32
type features = {
  datapath_id : uint64;
  n_buffers : uint32;
  n_tables : byte;
  unused_caps : bytes;
  arp_match_ip : bool;
  queue_stats : bool;
  ip_reasm : bool;
  stp : bool;
  port_stats : bool;
  table_stats : bool;
  flow_stats : bool;
  actions_supported : uint32;
}
type config = { reasm : bool; drop : bool; miss_send_len : uint16; }
type in_reason = No_match | Action
val in_reason_of_int : int -> in_reason
val int_of_in_reason : in_reason -> int
val string_of_in_reason : in_reason -> string
type packet_in = {
  buffer_id : uint32;
  total_len : uint16;
  in_port : port;
  reason : in_reason;
}
type wildcards = {
  nw_tos : bool;
  dl_vlan_pcp : bool;
  nw_dst : byte;
  nw_src : byte;
  tp_dst : bool;
  tp_src : bool;
  nw_proto : bool;
  dl_type : bool;
  dl_dst : bool;
  dl_src : bool;
  dl_vlan : bool;
  in_port : bool;
}
type of_match = {
  wildcards : wildcards;
  in_port : port;
  dl_src : eaddr;
  dl_dst : eaddr;
  dl_vlan : uint16;
  dl_vlan_pcp : byte;
  dl_type : uint16;
  nw_tos : byte;
  nw_proto : byte;
  nw_src : uint32;
  nw_dst : uint32;
  tp_src : uint16;
  tp_dst : uint16;
}
type removed_reason = IDLE_TIMEOUT | HARD_TIMEOUT | DELETE
val removed_reason_of_int : int -> removed_reason
val int_of_removed_reason : removed_reason -> int
val string_of_removed_reason : removed_reason -> int
type flow = {
  of_match : of_match;
  cookie : uint64;
  priority : uint16;
  reason : removed_reason;
  duration_sec : uint32;
  duration_usec : uint32;
  idle_timeout : uint16;
  packet_count : uint64;
  byte_count : uint64;
}
type port_config = {
  no_packet_in : bool;
  no_fwd : bool;
  no_flood : bool;
  no_recv_stp : bool;
  no_recv : bool;
  no_stp : bool;
  port_down : bool;
}
type phy_port_feature = {
  pause_asym : bool;
  pause : bool;
  autoneg : bool;
  fiber : bool;
  copper : bool;
  f_10GB_FD : bool;
  f_1GB_FD : bool;
  f_1GB_HD : bool;
  f_100MB_FD : bool;
  f_100MB_HD : bool;
  f_10MB_FD : bool;
  f_10MB_HD : bool;
}
type phy_port = {
  port_no : uint16;
  hw_addr : eaddr;
  name : string;
  config : port_config;
  stp_forward : bool;
  stp_learn : bool;
  link_down : bool;
  curr : phy_port_feature;
  advertised : phy_port_feature;
  supported : phy_port_feature;
  peer : phy_port_feature;
}
type port_status_reason = ADD | DEL | MOD
val port_status_reason_of_int : int -> port_status_reason
val int_of_port_status_reason : port_status_reason -> int
val string_of_port_status_reason : port_status_reason -> string
type port_status = { reason : port_status_reason; phy_port : phy_port; }
type packet_out = {
  buffer_id : uint32;
  in_port : port;
  actions_len : uint16;
  actions : bytes;
}
type command = ADD | MODIFY | MODIFY_STRICT | DELETE | DELETE_STRICT
val command_of_int : int -> command
val int_of_command : command -> int
val string_of_command : command -> string
type flow_mod = {
  of_match : of_match;
  cookie : uint64;
  command : command;
  idle_timeout : uint16;
  hard_timeout : uint16;
  priority : uint16;
  buffer_id : uint32;
  out_port : port;
  emerg : bool;
  overlap : bool;
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
val table_id_of_int : int -> table_id
val int_of_table_id : table_id -> int
val string_of_table_id : table_id -> string
type stats_req_payload =
    Desc
  | Flow of of_match * table_id * port
  | Aggregate of of_match * table_id * port
  | Table
  | Port of port
  | Queue of port * queue_id
  | Vendor
type stats_req_h = { ty : uint16; flags : uint16; }
type desc = {
  mfr_desc : bytes;
  hw_desc : bytes;
  sw_desc : bytes;
  serial_num : bytes;
  dp_desc : bytes;
}
type action =
    OUTPUT
  | SET_VLAN_VID
  | SET_VLAN_PCP
  | STRIP_VLAN
  | SET_DL_SRC
  | SET_DL_DST
  | SET_NW_SRC
  | SET_NW_DST
  | SET_NW_TOS
  | SET_TP_SRC
  | SET_TP_DST
  | ENQUEUE
  | VENDOR
val action_of_int : int -> action
val int_of_action : action -> int
val string_of_action : action -> string
type flow_stats = {
  entry_length : uint16;
  table_id : byte;
  of_match : of_match;
  duration_sec : uint32;
  duration_usec : uint32;
  priority : uint16;
  idle_timeout : uint16;
  hard_timeout : uint16;
  cookie : uint64;
  packet_count : uint64;
  byte_count : uint64;
  action : action;
}
type aggregate_stats = {
  packet_count : uint64;
  byte_count : uint64;
  flow_count : uint32;
}
type table_stats = {
  table_id : byte;
  name : string;
  wildcards : wildcards;
  max_entries : uint32;
  active_count : uint32;
  lookup_count : uint64;
  matched_count : uint64;
}
type port_stats = {
  port_no : uint16;
  rx_packets : uint64;
  tx_packets : uint64;
  rx_bytes : uint64;
  tx_bytes : uint64;
  rx_dropped : uint64;
  tx_dropped : uint64;
  rx_errors : uint64;
  tx_errors : uint64;
  rx_frame_err : uint64;
  rx_over_err : uint64;
  rx_crc_err : uint64;
  collisions : uint64;
}
type queue_stats = {
  port_no : uint16;
  queue_id : uint32;
  tx_bytes : uint64;
  tx_packets : uint64;
  tx_errors : uint64;
}
type stats_resp_payload =
    Desc of desc
  | Flow of flow_stats
  | Aggregate of aggregate_stats
  | Table of table_stats
  | Port of port_stats
  | Queue of queue_stats
  | Vendor
type stats_resp_h = { st_ty : uint16; more_to_follow : bool; }
type payload =
    Hello of bytes
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
val parse_of_header : Bitstring.bitstring -> h
val parse_of : Bitstring.bitstring -> h
