open V1

let pp_network_error = Mirage_device.pp_error
let pp_ethif_error = Mirage_device.pp_error

let pp_arp_error ppf = function
  | `Timeout -> Fmt.string ppf "Dynamic ARP timed out"

let pp_ip_error ppf = function
  | #Mirage_device.error as e -> Mirage_device.pp_error ppf e
  | `No_route -> Fmt.string ppf "no route to destination"

let pp_icmp_error ppf = function
  | `Routing message -> Fmt.pf ppf "routing error: %s" message

let pp_tcp_error ppf = function
  | `Timeout -> Fmt.string ppf "connection attempt timed out"
  | `Refused -> Fmt.string ppf "connection attempt was refused"

let pp_tcp_write_error ppf = function
  | #Mirage_flow.write_error as e -> Mirage_flow.pp_write_error ppf e
  | #V1.Tcp.error as e            -> pp_tcp_error ppf e

let pp_fs_error ppf = function
    | `Is_a_directory      -> Fmt.string ppf "is a directory"
    | `Not_a_directory     -> Fmt.string ppf "is not a directory"
    | `No_directory_entry  ->
      Fmt.string ppf "a directory in the path does not exist"

let pp_fs_write_error ppf = function
  | #Fs.error as e       -> pp_fs_error ppf e
  | `Directory_not_empty -> Fmt.string ppf "directory is not empty"
  | `File_already_exists -> Fmt.string ppf "file already exists"
  | `No_space            -> Fmt.string ppf "device has no more free space"

let pp_kv_ro_error ppf = function
  | `Unknown_key k -> Fmt.pf ppf "key %s not present in the store" k
