open V1

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
