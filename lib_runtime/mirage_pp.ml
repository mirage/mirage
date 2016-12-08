open Result
let pf pp = Format.fprintf pp

let pp_console_error pp = function
  | `Invalid_console str -> pf pp "invalid console %s" str

let unspecified pp m = pf pp "unspecified error - %s" m

let pp_network_error pp = function
  | `Msg message   -> unspecified pp message
  | `Unimplemented -> pf pp "operation not yet implemented"
  | `Disconnected  -> pf pp "device is disconnected"

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
  | `Routing message -> pf pp "routing error: %s" message

let pp_udp_error pp (`Msg message) = unspecified pp message

let pp_tcp_error pp = function
  | `Msg message   -> unspecified pp message
  | `Timeout       -> pf pp "connection attempt timed out"
  | `Refused       -> pf pp "connection attempt was refused"

let pp_flow_error pp = function
  | `Msg message   -> unspecified pp message

let pp_flow_write_error pp = function
  | `Msg message   -> unspecified pp message
  | `Closed        -> pf pp "attempted to write to a closed flow"

let pp_block_error pp = function
  | `Msg message   -> unspecified pp message
  | `Unimplemented -> pf pp "operation not yet implemented"
  | `Disconnected  -> pf pp "a required device was disconnected"

let pp_block_write_error pp = function
  | `Msg message   -> unspecified pp message
  | `Unimplemented -> pf pp "operation not yet implemented"
  | `Disconnected  -> pf pp "a required device was disconnected"
  | `Is_read_only  -> pf pp "attempted to write to a read-only disk"

let pp_fs_error pp = function
    | `Msg message         -> unspecified pp message
    | `Is_a_directory      -> pf pp "is a directory"
    | `Not_a_directory     -> pf pp "is not a directory"
    | `No_directory_entry  -> pf pp "a directory in the path does not exist"
    | `Format_unknown      -> pf pp "the device is not formatted for this filesystem"

let pp_fs_write_error pp = function
  | `Msg message         -> unspecified pp message
  | `Is_a_directory      -> pf pp "is a directory"
  | `Not_a_directory     -> pf pp "is not a directory"
  | `Directory_not_empty -> pf pp "directory is not empty"
  | `No_directory_entry  -> pf pp "a directory in the path does not exist"
  | `File_already_exists -> pf pp "file already exists"
  | `No_space            -> pf pp "device has no more free space"

let pp_kv_ro_error pp = function
  | `Msg message   -> unspecified pp message
  | `Unknown_key   -> pf pp "key not present in the store"

let reduce = function
  | Ok () -> Ok ()
  | Error (`Msg _) as e -> e
  | Error `Unimplemented -> Error (`Msg "unimplemented functionality discovered")
  | Error `Disconnected -> Error (`Msg "a required device was disconnected")
