
let pp_network_error pp = function
  | `Unknown message -> Format.fprintf pp "undiagnosed error - %s" message
  | `Unimplemented   -> Format.fprintf pp "operation not yet implemented"
  | `Disconnected    -> Format.fprintf pp "device is disconnected"
