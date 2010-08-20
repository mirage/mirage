type bytes = string

type ethernet_mac
val ethernet_mac_of_bytes : string -> ethernet_mac
val ethernet_mac_of_string : string -> ethernet_mac option
val ethernet_mac_to_bytes : ethernet_mac -> bytes
val ethernet_mac_to_string : ethernet_mac -> string
val ethernet_mac_broadcast: ethernet_mac

type ipv4_addr
val ipv4_addr_of_bytes : string -> ipv4_addr
val ipv4_addr_of_tuple : (int * int * int * int) -> ipv4_addr
val ipv4_addr_of_string : string -> ipv4_addr option
val ipv4_addr_to_bytes : ipv4_addr -> bytes
val ipv4_addr_to_string : ipv4_addr -> string
val ipv4_addr_of_uint32 : int32 -> ipv4_addr
val ipv4_addr_to_uint32 : ipv4_addr -> int32
val ipv4_blank : ipv4_addr
val ipv4_broadcast : ipv4_addr

module DHCP : sig
   (* An active DHCP lease *)
   type info = {
     xid: int32;
     ip: ipv4_addr;
     netmask: ipv4_addr option;
     gw: ipv4_addr list;
     dns: ipv4_addr list;
     lease_until: float;
   }

   type state =
    |Disabled               (* DHCP not active *)
    |Request_sent of int32  (* Request sent with xid int32, waiting offer *)
    |Offer_accepted of info (* Offer accepted, waiting for ack *)
    |Lease_held of info     (* Lease currently held *)
 
end
 
type netif_state =
   |Netif_obtaining_ip   (* Interface is obtaining an IP address *)
   |Netif_up             (* Interface is active *)
   |Netif_down           (* Interface is disabled *)
   |Netif_shutting_down  (* Interface is shutting down *)

type netif = {
    nf: Xen.Netfront.netfront;
    mutable dhcp: DHCP.state;
    dhcp_cond: unit Lwt_condition.t;
    mutable state: netif_state;
    mutable ip: ipv4_addr;
    mutable netmask: ipv4_addr;
    mutable gw: ipv4_addr;
    mac: ethernet_mac;
    recv: Xen.Page_stream.t;
    recv_cond: unit Lwt_condition.t;
    env_pool: string Lwt_pool.t;
    xmit: string -> unit Lwt.t;
}

val netfront_of_netif : netif -> Xen.Netfront.netfront
