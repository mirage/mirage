(*
 * Copyright (c) 2013 Thomas Gazagnaire <thomas@gazagnaire.org>
 * Copyright (c) 2013 Anil Madhavapeddy <anil@recoil.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *)

(** Configuration library.

    [Mirage_types] defines a set of well-defined module signatures
    which are used by the various mirage libraries to implement a
    large collection of devices. *)

include Functoria.S

(** Configuration keys. *)
module Key : sig
  include Functoria.KEY

  val target: [ `Unix | `Xen | `MacOSX ] key
  (** Key setting the configuration mode for the current project. *)

  val is_xen: bool value
  (** Is true iff the {!target} keys takes the value [`Xen]. *)

  val tracing: int key
  (** Key setting the tracing level. *)

end

(** {2 General mirage devices} *)

val get_mode: unit -> [ `Unix | `Xen | `MacOSX ]
(** Current configuration mode.

    Deprecated, use {!Key.target} instead.
 *)

val tracing : job impl
(** Tracking implementation. *)

val mprof_trace : size:int -> unit -> int
(** Use mirage-profile to trace the unikernel.
    On Unix, this creates and mmaps a file called "trace.ctf".
    On Xen, it shares the trace buffer with dom0.

    Deprecated. Is the identity over size.
*)

(** {3 Application registering} *)

val register :
  ?tracing:int ->
  ?keys:Key.t list ->
  ?libraries:string list ->
  ?packages:string list -> string -> job impl list -> unit


(** {2 Time} *)

type time
(** Abstract type for timers. *)

val time: time typ
(** The [V1.TIME] module signature. *)

val default_time: time impl
(** The default timer implementation. *)



(** {2 Clocks} *)

type clock
(** Abstract type for clocks. *)

val clock: clock typ
(** The [V1.CLOCK] module signature. *)

val default_clock: clock impl
(** The default mirage-clock implementation. *)



(** {2 Random} *)

type random
(** Abstract type for random sources. *)

val random: random typ
(** The [V1.RANDOM] module signature. *)

val default_random: random impl
(** Passthrough to the OCaml Random generator. *)


(** {2 Consoles} *)

(** Implementations of the [V1.CONSOLE] signature. *)

type console
(** Abstract type for consoles. *)

val console: console typ
(** The [V1.CONSOLE] module signature. *)

val default_console: console impl
(** Default console implementation. *)

val custom_console: string -> console impl
(** Custom console implementation. *)



(** {2 Memory allocation interface} *)

type io_page
(** Abstract type for page-aligned buffers. *)

val io_page: io_page typ
(** The [V1.IO_PAGE] module signature. *)

val default_io_page: io_page impl
(** The default [Io_page] implementation. *)



(** {2 Block devices} *)

(** Implementations of the [V1.BLOCK] signature. *)

type block
(** Abstract type for raw block device configurations. *)

val block: block typ
(** The [V1.BLOCK] module signature. *)

val block_of_file: string -> block impl
(** Use the given filen as a raw block device. *)



(** {2 Static key/value stores} *)

(** Implementations of the [V1.KV_RO] signature. *)

type kv_ro
(** Abstract type for read-only key/value store. *)

val kv_ro: kv_ro typ
(** The [V1.KV_RO] module signature. *)

val crunch: string -> kv_ro impl
(** Crunch a directory. *)

val archive: block impl -> kv_ro impl

val archive_of_files: ?dir:string -> unit -> kv_ro impl

val direct_kv_ro: string -> kv_ro impl
(** Direct access to the underlying filesystem as a key/value
    store. For Xen backends, this is equivalent to [crunch]. *)



(** {2 Filesystem} *)

(** Implementations of the [V1.FS] signature. *)

type fs
(** Abstract type for filesystems. *)

val fs: fs typ
(** The [V1.FS] module signature. *)

val fat: ?io_page:io_page impl -> block impl -> fs impl
(** Consider a raw block device as a FAT filesystem. *)

val fat_of_files: ?dir:string -> ?regexp:string -> unit -> fs impl
(** [fat_files dir ?dir ?regexp ()] collects all the files matching
    the shell pattern [regexp] in the directory [dir] into a FAT
    image. By default, [dir] is the current working directory and
    [regexp] is {i *} *)

val kv_ro_of_fs: fs impl -> kv_ro impl
(** Consider a filesystem implementation as a read-only key/value
    store. *)



(** {2 Network interfaces} *)

(** Implementations of the [V1.NETWORK] signature. *)

type network
(** Abstract type for network configurations. *)

val network: network typ
(** Representation of [Mirage_types.NETWORK]. *)

val tap0: network impl
(** The '/dev/tap0' interface. *)

val netif: ?group:string -> string -> network impl
(** A custom network interface. *)



(** {2 Ethernet configuration} *)

(** Implementations of the [V1.ETHIF] signature. *)
type ethernet
val ethernet : ethernet typ
val etif: network impl -> ethernet impl

(** {2 ARP configuration} *)

(** Implementation of the [V1.ARPV4] signature. *)
type arpv4
val arpv4 : arpv4 typ
val arp: ?clock: clock impl -> ?time: time impl -> ethernet impl -> arpv4 impl

(** {2 IP configuration} *)

(** Implementations of the [V1.IP] signature. *)

type v4
type v6

type 'a ip
type ipv4 = v4 ip
type ipv6 = v6 ip
(** Abstract type for IP configurations. *)

val ipv4: ipv4 typ
(** The [V1.IPV4] module signature. *)

val ipv6: ipv6 typ
(** The [V1.IPV6] module signature. *)

type ('ipaddr, 'prefix) ip_config = {
  address: 'ipaddr;
  netmask: 'prefix;
  gateways: 'ipaddr list;
}
(** Types for IP manual configuration. *)

type ipv4_config = (Ipaddr.V4.t, Ipaddr.V4.t) ip_config
(** Types for IPv4 manual configuration. *)

val create_ipv4:
  ?clock:clock impl -> ?time:time impl ->
  ?group:string -> network impl -> ipv4_config -> ipv4 impl
(** Use an IPv4 address. *)

val default_ipv4: ?group:string -> network impl -> ipv4 impl
(** Default local IP listening on the given network interfaces:
    - address: 10.0.0.2
    - netmask: 255.255.255.0
    - gateways: [10.0.0.1] *)

type ipv6_config = (Ipaddr.V6.t, Ipaddr.V6.Prefix.t list) ip_config
(** Types for IPv6 manual configuration. *)

val create_ipv6:
  ?time:time impl -> ?clock:clock impl ->
  ?group:string -> network impl -> ipv6_config -> ipv6 impl
(** Use an IPv6 address. *)



(** {UDP configuration} *)

(** Implementation of the [V1.UDP] signature. *)

type 'a udp
type udpv4 = v4 udp
type udpv6 = v6 udp
val udp: 'a udp typ
val udpv4: udpv4 typ
val udpv6: udpv6 typ
val direct_udp: 'a ip impl -> 'a udp impl
val socket_udpv4: ?group:string -> Ipaddr.V4.t option -> udpv4 impl



(** {TCP configuration} *)

(** Implementation of the [V1.TCP] signature. *)

type 'a tcp
type tcpv4 = v4 tcp
type tcpv6 = v6 tcp
val tcp: 'a tcp typ
val tcpv4: tcpv4 typ
val tcpv6: tcpv6 typ
val direct_tcp:
  ?clock:clock impl ->
  ?random:random impl ->
  ?time:time impl ->
  'a ip impl -> 'a tcp impl
val socket_tcpv4: ?group:string -> Ipaddr.V4.t option -> tcpv4 impl



(** {Network stack configuration} *)

(** Implementation of the [V1.STACKV4] signature. *)

type stackv4

val stackv4: stackv4 typ

val direct_stackv4_with_default_ipv4:
  ?clock:clock impl ->
  ?random:random impl ->
  ?time:time impl ->
  ?group:string ->
  console impl -> network impl -> stackv4 impl

val direct_stackv4_with_static_ipv4:
  ?clock:clock impl ->
  ?random:random impl ->
  ?time:time impl ->
  ?group:string ->
  console impl -> network impl -> ipv4_config -> stackv4 impl

val direct_stackv4_with_dhcp:
  ?clock:clock impl ->
  ?random:random impl ->
  ?time:time impl ->
  ?group:string ->
  console impl -> network impl -> stackv4 impl

val socket_stackv4:
  ?group:string -> console impl -> Ipaddr.V4.t list -> stackv4 impl

val generic_stackv4 :
  ?group:string -> console impl -> network impl -> stackv4 impl

(** {Resolver configuration} *)

type resolver
val resolver: resolver typ
val resolver_dns :
  ?ns:Ipaddr.V4.t -> ?ns_port:int -> ?time:time impl -> stackv4 impl -> resolver impl
val resolver_unix_system : resolver impl

(** {Conduit configuration} *)

type conduit
val conduit: conduit typ
val conduit_direct : ?tls:bool -> stackv4 impl -> conduit impl

(** {HTTP configuration} *)

type http
val http: http typ
val http_server: conduit impl -> http impl

(** {Argv configuration} *)

val argv: Functoria.Devices.argv impl
(** Dynamic argv implementation that resolves either to
    the xen or the unix implementation. *)


(**/*)

val launch : unit -> unit
