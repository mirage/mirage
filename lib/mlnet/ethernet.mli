module ARP :
  sig
    val recv : Netfront.netfront -> Mpl_ethernet.Ethernet.ARP.o -> unit
  end
module Frame : sig val recv : Netfront.netfront -> string -> unit Lwt.t end
