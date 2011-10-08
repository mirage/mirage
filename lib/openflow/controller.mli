val sp : ('a, unit, string) format -> 'a
val pr : ('a, out_channel, unit) format -> 'a
val ep : ('a, out_channel, unit) format -> 'a
val cp : string -> unit
module OP :
  sig
    val sp : ('a, unit, string) format -> 'a
    val pr : ('a, out_channel, unit) format -> 'a
    val ep : ('a, out_channel, unit) format -> 'a
    exception Unparsable of string * Bitstring.bitstring
    exception Unparsed of string * Bitstring.bitstring
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
    type uint8 = char
    type uint16 = int
    type uint32 = int32
    type uint64 = int64
    val uint8_of_int : int -> char
    type ipv4 = uint32
    val ipv4_to_string : int32 -> string
    type byte = uint8
    val byte : int -> byte
    val int_of_byte : char -> int
    val int32_of_byte : char -> int32
    val int32_of_int : int -> int32
    type bytes = string
    type eaddr = bytes
    val bytes_to_hex_string : char array -> string array
    val eaddr_to_string : string -> string
    val eaddr_is_broadcast : string -> bool
    val bytes_of_bitstring : Bitstring.bitstring -> string
    val ipv4_addr_of_bytes : string -> int32
    type vendor = uint32
    type queue_id = uint32
    type datapath_id = uint64
    type msg_code =
      Ofpacket.msg_code =
        HELLO
      | ERROR
      | ECHO_REQ
      | ECHO_RESP
      | VENDOR
      | FEATURES_REQ
      | FEATURES_RESP
      | GET_CONFIG_REQ
      | GET_CONFIG_RESP
      | SET_CONFIG
      | PACKET_IN
      | FLOW_REMOVED
      | PORT_STATUS
      | PACKET_OUT
      | FLOW_MOD
      | PORT_MOD
      | STATS_REQ
      | STATS_RESP
      | BARRIER_REQ
      | BARRIER_RESP
      | QUEUE_GET_CONFIG_REQ
      | QUEUE_GET_CONFIG_RESP
    val msg_code_of_int : int -> msg_code
    val int_of_msg_code : msg_code -> int
    val string_of_msg_code : msg_code -> string
    module Header :
      sig
        type h =
          Ofpacket.Header.h = {
          ver : uint8;
          ty : msg_code;
          len : uint16;
          xid : uint32;
        }
        val get_len : int
        val parse_h : Bitstring.bitstring -> h
        val string_of_h : h -> string
        val create : msg_code -> uint16 -> uint32 -> h
        val get_xid : h -> uint32
        val get_ty : h -> msg_code
        val build_h : h -> Bitstring.bitstring
      end
    type table_id = Ofpacket.table_id = All | Emergency | Table of uint8
    val table_id_of_int : int -> table_id
    val int_of_table_id : table_id -> int
    val string_of_table_id : table_id -> string
    type port =
      Ofpacket.port =
        Max
      | In_port
      | Table
      | Normal
      | Flood
      | All
      | Controller
      | Local
      | No_port
      | Port of int16
    val port_of_int : int16 -> port
    val int_of_port : port -> int16
    val string_of_port : port -> string
    type action =
      Ofpacket.action =
        Output of (port * int)
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
      | VENDOR_ACT
    val action_of_int : int -> action
    val string_of_action : action -> string
    val len_of_action : action -> int
    val action_to_bitstring : action -> Bitstring.bitstring
    module Queue :
      sig
        type h = Ofpacket.Queue.h = { queue_id : queue_id; }
        type t = Ofpacket.Queue.t = NONE | MIN_RATE of uint16
      end
    module Port :
      sig
        type config =
          Ofpacket.Port.config = {
          port_down : bool;
          no_stp : bool;
          no_recv : bool;
          no_recv_stp : bool;
          no_flood : bool;
          no_fwd : bool;
          no_packet_in : bool;
        }
        val parse_config : string * int * int -> config
        type features =
          Ofpacket.Port.features = {
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
        val parse_features : string * int * int -> features
        type state =
          Ofpacket.Port.state = {
          link_down : bool;
          stp_listen : bool;
          stp_learn : bool;
          stp_forward : bool;
          stp_block : bool;
          stp_mask : bool;
        }
        val parse_state : string * int * int -> state
        type phy =
          Ofpacket.Port.phy = {
          port_no : uint16;
          hw_addr : eaddr;
          name : string;
          config : config;
          state : state;
          curr : features;
          advertised : features;
          supported : features;
          peer : features;
        }
        val max_name_len : int
        val phy_len : int
        val parse_phy : string * int * int -> phy
        val string_of_phy : phy -> string
        type stats =
          Ofpacket.Port.stats = {
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
        val parse_port_stats_reply : string * int * int -> stats list
        val string_of_port_stats_reply : stats list -> string
        type reason = Ofpacket.Port.reason = ADD | DEL | MOD
        val reason_of_int : int -> reason
        val int_of_reason : reason -> int
        val string_of_reason : reason -> string
        type status = Ofpacket.Port.status = { reason : reason; desc : phy; }
        val string_of_status : status -> string
        val status_of_bitstring : string * int * int -> status
      end
    module Switch :
      sig
        type capabilities =
          Ofpacket.Switch.capabilities = {
          flow_stats : bool;
          table_stats : bool;
          port_stats : bool;
          stp : bool;
          ip_reasm : bool;
          queue_stats : bool;
          arp_match_ip : bool;
        }
        val parse_capabilities : string * int * int -> capabilities
        type actions =
          Ofpacket.Switch.actions = {
          output : bool;
          set_vlan_id : bool;
          set_vlan_pcp : bool;
          strip_vlan : bool;
          set_dl_src : bool;
          set_dl_dst : bool;
          set_nw_src : bool;
          set_nw_dst : bool;
          set_nw_tos : bool;
          set_tp_src : bool;
          set_tp_dst : bool;
          enqueue : bool;
          vendor : bool;
        }
        val parse_actions : string * int * int -> actions
        type features =
          Ofpacket.Switch.features = {
          datapath_id : datapath_id;
          n_buffers : uint32;
          n_tables : byte;
          capabilities : capabilities;
          actions : actions;
          ports : Port.phy list;
        }
        val parse_features : string * int * int -> features
        type config =
          Ofpacket.Switch.config = {
          drop : bool;
          reasm : bool;
          miss_send_len : uint16;
        }
      end
    module Wildcards :
      sig
        type t =
          Ofpacket.Wildcards.t = {
          in_port : bool;
          dl_vlan : bool;
          dl_src : bool;
          dl_dst : bool;
          dl_type : bool;
          nw_proto : bool;
          tp_src : bool;
          tp_dst : bool;
          nw_src : byte;
          nw_dst : byte;
          dl_vlan_pcp : bool;
          nw_tos : bool;
        }
        val full_wildcard : t
        val exact_match : t
        val l2_match : t
        val l3_match : t
        val wildcard_to_bitstring : t -> Bitstring.bitstring
        val string_of_wildcard : t -> string
        val bitstring_to_wildcards : string * int * int -> t
      end
    module Match :
      sig
        type t =
          Ofpacket.Match.t = {
          wildcards : Wildcards.t;
          in_port : port;
          dl_src : eaddr;
          dl_dst : eaddr;
          dl_vlan : uint16;
          dl_vlan_pcp : byte;
          dl_type : uint16;
          nw_src : uint32;
          nw_dst : uint32;
          nw_tos : byte;
          nw_proto : byte;
          tp_src : uint16;
          tp_dst : uint16;
        }
        val match_to_bitstring : t -> Bitstring.bitstring
        val bitstring_to_match : string * int * int -> t
        val get_len : int
        val get_dl_src : t -> eaddr
        val get_dl_dst : t -> eaddr
        val create_flow_match :
          Wildcards.t ->
          ?in_port:int16 ->
          ?dl_src:eaddr ->
          ?dl_dst:eaddr ->
          ?dl_vlan:uint16 ->
          ?dl_vlan_pcp:byte ->
          ?dl_type:uint16 ->
          ?nw_tos:byte ->
          ?nw_proto:byte ->
          ?nw_src:uint32 ->
          ?nw_dst:uint32 -> ?tp_src:uint16 -> ?tp_dst:uint16 -> unit -> t
        val parse_from_raw_packet : port -> string * int * int -> t
        val match_to_string : t -> string
      end
    module Flow :
      sig
        type reason =
          Ofpacket.Flow.reason =
            IDLE_TIMEOUT
          | HARD_TIMEOUT
          | DELETE
        val reason_of_int : int -> reason
        val int_of_reason : reason -> int
        val string_of_reason : reason -> int
        type stats =
          Ofpacket.Flow.stats = {
          entry_length : uint16;
          table_id : byte;
          of_match : Match.t;
          duration_sec : uint32;
          duration_usec : uint32;
          priority : uint16;
          idle_timeout : uint16;
          hard_timeout : uint16;
          cookie : uint64;
          packet_count : uint64;
          byte_count : uint64;
          action : action list;
        }
        val parse_flow_stats : string * int * int -> stats list
        val string_of_flow_stat : stats -> string
      end
    module Packet_in :
      sig
        type reason = Ofpacket.Packet_in.reason = No_match | Action
        val reason_of_int : int -> reason
        val int_of_reason : reason -> int
        val string_of_reason : reason -> string
        type t =
          Ofpacket.Packet_in.t = {
          buffer_id : uint32;
          in_port : port;
          reason : reason;
          data : Bitstring.t;
        }
        val parse_packet_in : string * int * int -> t
        val string_of_packet_in : t -> string
      end
    module Packet_out :
      sig
        type t =
          Ofpacket.Packet_out.t = {
          of_header : Header.h;
          buffer_id : uint32;
          in_port : port;
          actions : action array;
          data : Bitstring.t;
        }
        val get_len : int
        val create :
          ?xid:uint32 ->
          ?buffer_id:uint32 ->
          ?actions:action array ->
          ?data:Bitstring.bitstring -> in_port:port -> unit -> t
        val packet_out_to_bitstring : t -> Bitstring.bitstring
      end
    module Flow_mod :
      sig
        type command =
          Ofpacket.Flow_mod.command =
            ADD
          | MODIFY
          | MODIFY_STRICT
          | DELETE
          | DELETE_STRICT
        val command_of_int : int -> command
        val int_of_command : command -> int
        val string_of_command : command -> string
        type flags =
          Ofpacket.Flow_mod.flags = {
          send_flow_rem : bool;
          emerg : bool;
          overlap : bool;
        }
        type t =
          Ofpacket.Flow_mod.t = {
          of_header : Header.h;
          of_match : Match.t;
          cookie : uint64;
          command : command;
          idle_timeout : uint16;
          hard_timeout : uint16;
          priority : uint16;
          buffer_id : int32;
          out_port : port;
          flags : flags;
          actions : action array;
        }
        val total_len : int
        val create :
          Match.t ->
          uint64 ->
          command ->
          ?priority:uint16 ->
          ?idle_timeout:uint16 ->
          ?hard_timeout:uint16 ->
          ?buffer_id:int ->
          ?out_port:port -> ?flags:flags -> action array -> unit -> t
        val flow_mod_to_bitstring : t -> Bitstring.bitstring
      end
    module Flow_removed :
      sig
        type reason =
          Ofpacket.Flow_removed.reason =
            IDLE_TIMEOUT
          | HARD_TIMEOUT
          | DELETE
        val reason_of_int : int -> reason
        val int_of_reason : reason -> int
        val string_of_reason : reason -> string
        type t =
          Ofpacket.Flow_removed.t = {
          of_match : Match.t;
          cookie : uint64;
          priority : uint16;
          reason : reason;
          duration_sec : uint32;
          duration_nsec : uint32;
          idle_timeout : uint16;
          packet_count : uint64;
          byte_count : uint64;
        }
        val flow_removed_of_bitstring : string * int * int -> t
        val string_of_flow_removed : t -> string
      end
    module Port_mod :
      sig
        type t =
          Ofpacket.Port_mod.t = {
          port_no : port;
          hw_addr : eaddr;
          config : Port.config;
          mask : Port.config;
          advertise : Port.features;
        }
      end
    module Stats :
      sig
        type aggregate =
          Ofpacket.Stats.aggregate = {
          packet_count : uint64;
          byte_count : uint64;
          flow_count : uint32;
        }
        type table =
          Ofpacket.Stats.table = {
          table_id : table_id;
          name : string;
          wildcards : Wildcards.t;
          max_entries : uint32;
          active_count : uint32;
          lookup_count : uint64;
          matched_count : uint64;
        }
        type queue =
          Ofpacket.Stats.queue = {
          port_no : uint16;
          queue_id : uint32;
          tx_bytes : uint64;
          tx_packets : uint64;
          tx_errors : uint64;
        }
        type desc =
          Ofpacket.Stats.desc = {
          imfr_desc : bytes;
          hw_desc : bytes;
          sw_desc : bytes;
          serial_num : bytes;
          dp_desc : bytes;
        }
        type req_hdr =
          Ofpacket.Stats.req_hdr = {
          ty : uint16;
          flags : uint16;
        }
        type stats_type =
          Ofpacket.Stats.stats_type =
            DESC
          | FLOW
          | AGGREGATE
          | TABLE
          | PORT
          | QUEUE
          | VENDOR
        val int_of_req_type : stats_type -> int
        val get_len : stats_type -> int
        val create_flow_stat_req :
          Match.t ->
          ?table_id:int ->
          ?out_port:port -> ?xid:Int32.t -> unit -> Bitstring.bitstring
        val create_aggr_flow_stat_req :
          Match.t ->
          ?table_id:int ->
          ?out_port:port -> ?xid:Int32.t -> unit -> Bitstring.bitstring
        val create_vendor_stat_req :
          ?xid:Int32.t -> unit -> Bitstring.bitstring
        val create_table_stat_req :
          ?xid:Int32.t -> unit -> Bitstring.bitstring
        val create_queue_stat_req :
          ?xid:Int32.t ->
          ?queue_id:int32 -> ?port:port -> unit -> Bitstring.bitstring
        val create_port_stat_req :
          ?xid:Int32.t -> ?port:port -> unit -> Bitstring.bitstring
        type req =
          Ofpacket.Stats.req =
            Desc_req of req_hdr
          | Flow_req of req_hdr * Match.t * table_id * port
          | Aggregate_req of req_hdr * Match.t * table_id * port
          | Table_req of req_hdr
          | Port_req of req_hdr * port
          | Queue_req of req_hdr * port * queue_id
          | Vendor_req of req_hdr
        type resp_hdr =
          Ofpacket.Stats.resp_hdr = {
          st_ty : stats_type;
          more_to_follow : bool;
        }
        val int_of_stats_type : stats_type -> int
        val stats_type_of_int : int -> stats_type
        type resp =
          Ofpacket.Stats.resp =
            Desc_resp of resp_hdr * desc
          | Flow_resp of resp_hdr * Flow.stats list
          | Aggregate_resp of resp_hdr * aggregate
          | Table_resp of resp_hdr * table list
          | Port_resp of resp_hdr * Port.stats list
          | Queue_resp of resp_hdr * queue list
          | Vendor_resp of resp_hdr
        val parse_table_stats_reply : string * int * int -> table list
        val string_of_table_stats_reply : table list -> string
        val parse_stats : string * int * int -> resp
        val string_of_flow_stats : Flow.stats list -> string
        val string_of_stats : resp -> string
      end
    type error_code =
      Ofpacket.error_code =
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
    val build_features_req : uint32 -> Bitstring.bitstring
    val build_echo_resp :
      Header.h -> Bitstring.bitstring -> Bitstring.bitstring
    type t =
      Ofpacket.t =
        Hello of Header.h * Bitstring.t
      | Error of Header.h * error_code
      | Echo_req of Header.h * Bitstring.t
      | Echo_resp of Header.h * Bitstring.t
      | Vendor of Header.h * vendor * Bitstring.t
      | Features_req of Header.h
      | Features_resp of Header.h * Switch.features
      | Get_config_req of Header.h
      | Get_config_resp of Header.h * Switch.config
      | Set_config of Header.h * Switch.config
      | Packet_in of Header.h * Packet_in.t
      | Flow_removed of Header.h * Flow_removed.t
      | Port_status of Header.h * Port.status
      | Packet_out of Header.h * Packet_out.t * Bitstring.t
      | Flow_mod of Header.h * Flow_mod.t
      | Port_mod of Header.h * Port_mod.t
      | Stats_req of Header.h * Stats.req
      | Stats_resp of Header.h * Stats.resp
      | Barrier_req of Header.h
      | Barrier_resp of Header.h
      | Queue_get_config_req of Header.h * port
      | Queue_get_config_resp of Header.h * port * Queue.t array
    val parse : Header.h -> Bitstring.t -> t
  end
module Event :
  sig
    type t =
        DATAPATH_JOIN
      | DATAPATH_LEAVE
      | PACKET_IN
      | FLOW_REMOVED
      | FLOW_STATS_REPLY
      | AGGR_FLOW_STATS_REPLY
      | DESC_STATS_REPLY
      | PORT_STATS_REPLY
      | TABLE_STATS_REPLY
      | PORT_STATUS_CHANGE
    type e =
        Datapath_join of OP.datapath_id
      | Datapath_leave of OP.datapath_id
      | Packet_in of OP.port * int32 * Bitstring.t * OP.datapath_id
      | Flow_removed of OP.Match.t * OP.Flow_removed.reason * int32 * 
          int32 * int64 * int64 * OP.datapath_id
      | Flow_stats_reply of int32 * bool * OP.Flow.stats list *
          OP.datapath_id
      | Aggr_flow_stats_reply of int32 * int64 * int64 * int32 *
          OP.datapath_id
      | Port_stats_reply of int32 * OP.Port.stats list * OP.datapath_id
      | Table_stats_reply of int32 * OP.Stats.table list * OP.datapath_id
      | Desc_stats_reply of string * string * string * string * string *
          OP.datapath_id
      | Port_status of OP.Port.reason * OP.Port.phy * OP.datapath_id
    val string_of_event : e -> string
  end
type endhost = { ip : Net.Nettypes.ipv4_addr; port : int; }
type state = {
  mutable dp_db : (OP.datapath_id, Net.Channel.t) Hashtbl.t;
  mutable channel_dp : (endhost, OP.datapath_id) Hashtbl.t;
  mutable datapath_join_cb :
    (state -> OP.datapath_id -> Event.e -> unit) list;
  mutable datapath_leave_cb :
    (state -> OP.datapath_id -> Event.e -> unit) list;
  mutable packet_in_cb : (state -> OP.datapath_id -> Event.e -> unit) list;
  mutable flow_removed_cb : (state -> OP.datapath_id -> Event.e -> unit) list;
  mutable flow_stats_reply_cb :
    (state -> OP.datapath_id -> Event.e -> unit) list;
  mutable aggr_flow_stats_reply_cb :
    (state -> OP.datapath_id -> Event.e -> unit) list;
  mutable desc_stats_reply_cb :
    (state -> OP.datapath_id -> Event.e -> unit) list;
  mutable port_stats_reply_cb :
    (state -> OP.datapath_id -> Event.e -> unit) list;
  mutable table_stats_reply_cb :
    (state -> OP.datapath_id -> Event.e -> unit) list;
  mutable port_status_cb : (state -> OP.datapath_id -> Event.e -> unit) list;
}
val register_cb :
  state -> Event.t -> (state -> OP.datapath_id -> Event.e -> unit) -> unit
val process_of_packet :
  state ->
  Net.Nettypes.ipv4_addr * int -> OP.t -> Net.Channel.t -> unit Lwt.t
val send_of_data : state -> OP.datapath_id -> Bitstring.t -> unit Lwt.t
val rd_data : int -> Net.Channel.t -> Bitstring.bitstring Lwt.t
val listen :
  Net.Manager.t ->
  Net.Nettypes.ipv4_addr option -> int -> (state -> 'a) -> unit Lwt.t
