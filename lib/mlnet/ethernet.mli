module Netif :
  sig
    type t

    val create :
      ?default:bool ->
      ?up:bool ->
      ip:Mlnet_types.IPv4.addr ->
      netmask:Mlnet_types.IPv4.addr ->
      gw:Mlnet_types.IPv4.addr -> Netfront.netfront_id -> t Lwt.t

    val set_default : t -> bool -> unit
  end

module ARP :
  sig
    val recv : Netfront.netfront -> Mpl_ethernet.Ethernet.ARP.o -> unit
  end

module Frame : 
  sig 
    val recv : Netfront.netfront -> string -> unit Lwt.t 
  end

