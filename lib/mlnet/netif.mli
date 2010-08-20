val default_netif : Mlnet_types.netif option ref
val create_static :
  ?default:bool -> ip:Mlnet_types.ipv4_addr ->
  netmask:Mlnet_types.ipv4_addr -> gw:Mlnet_types.ipv4_addr list -> Xen.Netfront.netfront_id -> (Mlnet_types.netif * unit Lwt.t) Lwt.t
val create_dhcp :
  ?default:bool -> Xen.Netfront.netfront_id -> (Mlnet_types.netif * unit Lwt.t) Lwt.t
val fold_active : ('a -> Mlnet_types.netif -> 'a) -> 'a -> 'a
val set_default : Mlnet_types.netif -> bool -> unit
