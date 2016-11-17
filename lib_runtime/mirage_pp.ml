
let pp_console_error pp = function
  | `Invalid_console str -> Format.fprintf pp "invalid console %s" str

let pp_network_error pp = function
  | `Unknown message -> Format.fprintf pp "undiagnosed error - %s" message
  | `Unimplemented   -> Format.fprintf pp "operation not yet implemented"
  | `Disconnected    -> Format.fprintf pp "device is disconnected"
