type bytes = string

type ethernet_mac
val ethernet_mac_of_bytes : string -> ethernet_mac
val ethernet_mac_of_string : string -> ethernet_mac option
val ethernet_mac_to_bytes : ethernet_mac -> bytes
val ethernet_mac_to_string : ethernet_mac -> string

type ipv4_addr
val ipv4_addr_of_bytes : string -> ipv4_addr
val ipv4_addr_of_tuple : (int * int * int * int) -> ipv4_addr
val ipv4_addr_of_string : string -> ipv4_addr option
val ipv4_addr_to_bytes : ipv4_addr -> bytes
val ipv4_addr_to_string : ipv4_addr -> string

type netif_state =
   |Netif_up             (* Interface is active *)
   |Netif_down           (* Interface is disabled *)
   |Netif_shutting_down  (* Interface is shutting down *)

type netif = {
    nf: Xen.Netfront.netfront;
    mutable state: netif_state;
    ip: ipv4_addr;
    netmask: ipv4_addr;
    gw: ipv4_addr;
    mac: ethernet_mac;
    recv: Xen.Page_stream.t;
    recv_cond: unit Lwt_condition.t;
    recv_pool: string Lwt_pool.t;
    xmit: Xen.Page_stream.t;
}

val netfront_of_netif : netif -> Xen.Netfront.netfront
