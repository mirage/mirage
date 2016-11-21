open Result
let say pp = Format.fprintf pp

let pp_console_error pp = function
  | `Invalid_console str -> say pp "invalid console %s" str

let unspecified pp m = say pp "unspecified error - %s" m

let pp_network_error pp = function
  | `Msg message   -> unspecified pp message
  | `Unimplemented -> say pp "operation not yet implemented"
  | `Disconnected  -> say pp "device is disconnected"

let pp_ethif_error = pp_network_error

let pp_arp_error pp = function
  | `Timeout -> Format.fprintf pp "Dynamic ARP timed out"

let pp_ip_error pp = function
  | `Msg message   -> unspecified pp message
  | `Unimplemented -> Format.fprintf pp "operation not yet implemented"
  | `Disconnected  -> Format.fprintf pp "device is disconnected"
  | `No_route      -> Format.fprintf pp "no route to destination"


let pp_icmp_error pp = function
  | `Msg message   -> unspecified pp message
  | `Routing message -> say pp "routing error: %s" message

let pp_udp_error pp (`Msg message) = unspecified pp message

let pp_tcp_error pp = function
  | `Msg message   -> unspecified pp message
  | `Timeout       -> say pp "connection attempt timed out"
  | `Refused       -> say pp "connection attempt was refused"

let pp_flow_error pp = function
  | `Msg message   -> unspecified pp message

let pp_flow_write_error pp = function
  | `Msg message   -> unspecified pp message
  | `Closed        -> say pp "attempted to write to a closed flow"

let pp_block_error pp = function
  | `Msg message   -> unspecified pp message
  | `Unimplemented -> say pp "operation not yet implemented"
  | `Disconnected  -> say pp "a required device was disconnected"

let pp_block_write_error pp = function
  | `Msg message   -> unspecified pp message
  | `Unimplemented -> say pp "operation not yet implemented"
  | `Disconnected  -> say pp "a required device was disconnected"
  | `Is_read_only  -> say pp "attempted to write to a read-only disk"

let reduce = function
  | Ok () -> Ok ()
  | Error (`Msg _) as e -> e
  | Error `Unimplemented -> Error (`Msg "unimplemented functionality discovered")
  | Error `Disconnected -> Error (`Msg "a required device was disconnected")
