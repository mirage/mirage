open Result

let pp_console_error pp = function
  | `Invalid_console str -> Format.fprintf pp "invalid console %s" str

let unspecified pp m = Format.fprintf pp "unspecified error - %s" m

let pp_network_error pp = function
  | `Msg message   -> unspecified pp message
  | `Unimplemented -> Format.fprintf pp "operation not yet implemented"
  | `Disconnected  -> Format.fprintf pp "device is disconnected"

let pp_ethif_error = pp_network_error

let pp_arp_error pp = function
  | `Timeout -> Format.fprintf pp "Dynamic ARP timed out"

let pp_ip_error = pp_ethif_error

let pp_icmp_error pp = function
  | `Msg message   -> unspecified pp message
  | `Routing message -> Format.fprintf pp "routing error: %s" message

let pp_udp_error pp (`Msg message) = unspecified pp message

let pp_tcp_error pp = function
  | `Msg message   -> unspecified pp message
  | `Timeout       -> Format.fprintf pp "connection attempt timed out"
  | `Refused       -> Format.fprintf pp "connection attempt was refused"

let pp_flow_error pp = function
  | `Msg message   -> unspecified pp message

let pp_flow_write_error pp = function
  | `Msg message   -> unspecified pp message
  | `Closed        -> Format.fprintf pp "attempted to write to a closed flow"

let reduce = function
  | Ok () -> Ok ()
  | Error (`Msg _) as e -> e
  | Error `Unimplemented -> Error (`Msg "unimplemented functionality discovered")
  | Error `Disconnected -> Error (`Msg "a required device was disconnected")
