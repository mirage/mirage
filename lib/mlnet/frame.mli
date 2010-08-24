val recv : Mlnet_types.netif -> Xen.Hw_page.sub -> unit
val recv_thread : Mlnet_types.netif -> unit Lwt.t
