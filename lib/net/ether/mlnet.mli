module Types :
  sig
    type bytes = string
    type ethernet_mac
    val ethernet_mac_of_bytes : string -> ethernet_mac
    val ethernet_mac_of_string : string -> ethernet_mac option
    val ethernet_mac_to_bytes : ethernet_mac -> bytes
    val ethernet_mac_to_string : ethernet_mac -> string
    val ethernet_mac_broadcast : ethernet_mac
    type ipv4_addr
    val ipv4_addr_of_bytes : string -> ipv4_addr
    val ipv4_addr_of_tuple : int * int * int * int -> ipv4_addr
    val ipv4_addr_of_string : string -> ipv4_addr option
    val ipv4_addr_to_bytes : ipv4_addr -> bytes
    val ipv4_addr_to_string : ipv4_addr -> string
    val ipv4_addr_of_uint32 : int32 -> ipv4_addr
    val ipv4_addr_to_uint32 : ipv4_addr -> int32
    val ipv4_blank : ipv4_addr
    val ipv4_broadcast : ipv4_addr
    val ipv4_localhost : ipv4_addr
    type 'a resp = OK of 'a | Err of string | Retry
    type sockaddr = TCP of ipv4_addr * int | UDP of ipv4_addr * int
  end
module Ethif :
  sig
    type t
    val listen : t -> 'a -> 'b Lwt.t
    val output : t -> Mpl.Ethernet.x -> unit Lwt.t
    val create : OS.Ethif.id -> (t * 'a Lwt.t) Lwt.t
    val attach :
      t ->
      [< `ARP of Mpl.Ethernet.ARP.o -> unit Lwt.t
       | `IPv4 of Mpl.Ipv4.o -> unit Lwt.t
       | `IPv6 of Mpl.Ethernet.IPv4.o -> unit Lwt.t ] ->
      unit
    val detach : t -> [< `ARP | `IPv4 | `IPv6 ] -> unit
    val mac : t -> Types.ethernet_mac
    val enumerate : unit -> OS.Ethif.id list Lwt.t
  end
module Arp :
  sig
    type t
    val set_bound_ips : t -> Types.ipv4_addr list -> unit Lwt.t
    val get_bound_ips : t -> Types.ipv4_addr list
    val create : Ethif.t -> t * unit Lwt.t
    val query : t -> Types.ipv4_addr -> Types.ethernet_mac Lwt.t
  end
module Ipv4 :
  sig
    type 'a ip_output =
        Mpl.Mpl_stdlib.env ->
        ttl:int ->
        checksum:int ->
        dest:int32 -> options:'a Mpl.Mpl_stdlib.data -> Mpl.Ipv4.o
    type t
    val output : t -> dest_ip:Types.ipv4_addr -> 'a ip_output -> unit Lwt.t
    val set_ip : t -> Types.ipv4_addr -> unit Lwt.t
    val get_ip : t -> Types.ipv4_addr
    val mac : t -> Types.ethernet_mac
    val set_netmask : t -> Types.ipv4_addr -> unit Lwt.t
    val set_gateways : t -> Types.ipv4_addr list -> unit Lwt.t
    val attach :
      t ->
      [ `ICMP of Mpl.Ipv4.o -> Mpl.Icmp.o -> unit Lwt.t
      | `TCP of Mpl.Ipv4.o -> Mpl.Tcp.o -> unit Lwt.t
      | `UDP of Mpl.Ipv4.o -> Mpl.Udp.o -> unit Lwt.t ] -> unit
    val detach : t -> [ `ICMP | `TCP | `UDP ] -> unit
  end
module Udp :
  sig
    type t
    val input : t -> Mpl.Ipv4.o -> Mpl.Udp.o -> unit Lwt.t
    val output :
      t ->
      dest_ip:Types.ipv4_addr ->
      (Mpl.Mpl_stdlib.env -> Mpl.Udp.o) -> unit Lwt.t
    val listen : t -> int -> (Mpl.Ipv4.o -> Mpl.Udp.o -> unit Lwt.t) -> unit
  end
module Tcp :
  sig
    type t
    val input : t -> Mpl.Ipv4.o -> Mpl.Tcp.o -> unit Lwt.t
    val output :
      t ->
      dest_ip:Types.ipv4_addr ->
      (Mpl.Mpl_stdlib.env -> Mpl.Tcp.o) -> unit Lwt.t
    val listen : t -> int -> (Mpl.Ipv4.o -> Mpl.Tcp.o -> unit Lwt.t) -> unit
  end
module type Flow =
  sig
    type t
    val read : t -> string -> int -> int -> int Lwt.t
    val really_read : t -> string -> int -> int -> unit Lwt.t
    val read_line : t -> string Lwt.t
    val read_all : t -> string Lwt.t
    val write : t -> string -> int -> int -> int Lwt.t
    val really_write : t -> string -> int -> int -> unit Lwt.t
    val write_all : t -> string -> unit Lwt.t
    val connect : Types.sockaddr -> t Lwt.t
    val with_connection : Types.sockaddr -> (t -> 'a Lwt.t) -> 'a Lwt.t
    val listen :
      (Types.sockaddr -> t -> unit Lwt.t) -> Types.sockaddr -> unit Lwt.t
    val close : t -> unit
  end
