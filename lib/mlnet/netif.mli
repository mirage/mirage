val default_netif : Mlnet_types.netif option ref
val create :
  ?default:bool ->
  ?up:bool ->
  ip:Mlnet_types.ipv4_addr ->
  netmask:Mlnet_types.ipv4_addr -> gw:Mlnet_types.ipv4_addr -> Netfront.netfront_id -> (Mlnet_types.netif * unit Lwt.t) Lwt.t
val fold_active : ('a -> Mlnet_types.netif -> 'a) -> 'a -> 'a
val set_default : Mlnet_types.netif -> bool -> unit
