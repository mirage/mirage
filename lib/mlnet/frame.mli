val recv : Mlnet_types.netif -> Xen.Page_stream.extent -> unit
val recv_thread : Mlnet_types.netif -> unit Lwt.t
