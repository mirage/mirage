open V1

val pp_console_error: Format.formatter -> Console.error -> unit

val pp_network_error: Format.formatter -> Network.error -> unit
val pp_ethif_error  : Format.formatter -> Ethif.error -> unit
val pp_ip_error     : Format.formatter -> Ip.error -> unit
val pp_icmp_error   : Format.formatter -> Icmp.error -> unit
val pp_udp_error    : Format.formatter -> Udp.error -> unit
val pp_tcp_error    : Format.formatter -> Tcp.error -> unit
val pp_flow_error   : Format.formatter -> Flow.error -> unit
val pp_flow_write_error : Format.formatter -> Flow.write_error -> unit

val reduce : (unit, [`Msg of string | `Unimplemented | `Disconnected]) Result.result -> (unit, [> `Msg of string]) Result.result
