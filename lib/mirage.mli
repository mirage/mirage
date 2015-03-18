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


type key = Mirage_key.key

(** {2 Module combinators} *)

type 'a typ
(** The type of values representing module types. *)

val (@->): 'a typ -> 'b typ -> ('a -> 'b) typ
(** Construct a functor type from a type and an existing functor
    type. This corresponds to prepending a parameter to the list of
    functor parameters. For example,

    {[ kv_ro @-> ip @-> kv_ro ]}

    describes a functor type that accepts two arguments -- a kv_ro and
    an ip device -- and returns a kv_ro.
*)

type 'a impl
(** The type of values representing module implementations. *)

val ($): ('a -> 'b) impl -> 'a impl -> 'b impl
(** [m $ a] applies the functor [a] to the functor [m]. *)

val foreign: string -> ?libraries:string list -> ?packages:string list -> 'a typ -> 'a impl
(** [foreign name libs packs constr typ] states that the module named
    by [name] has the module type [typ]. If [libs] is set, add the
    given set of ocamlfind libraries to the ones loaded by default. If
    [packages] is set, add the given set of OPAM packages to the ones
    loaded by default. *)

val typ: 'a impl -> 'a typ
(** Return the module signature of a given implementation. *)



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


(** {2 Entropy} *)

type entropy
(** Abstract type for entropy sources. *)

val entropy: entropy typ
(** The [V1.ENTROPY] module signature. *)

val default_entropy: entropy impl
(** Pick the strongest entropy source available. *)

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

val netif: string -> network impl
(** A custom network interface. *)



(** {2 Ethernet configuration} *)

(** Implementations of the [V1.ETHIF] signature. *)
(* XXX: is that meaningful to expose this level ? *)
type ethernet
val ethernet : ethernet typ
val etif: network impl -> ethernet impl



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

val create_ipv4: ?clock:clock impl -> ?time:time impl -> network impl -> ipv4_config -> ipv4 impl
(** Use an IPv4 address. *)

val default_ipv4: network impl -> ipv4 impl
(** Default local IP listening on the given network interfaces:
    - address: 10.0.0.2
    - netmask: 255.255.255.0
    - gateways: [10.0.0.1] *)

type ipv6_config = (Ipaddr.V6.t, Ipaddr.V6.Prefix.t list) ip_config
(** Types for manual IPv6 manual configuration. *)

val create_ipv6: ?time:time impl -> ?clock:clock impl -> network impl -> ipv6_config -> ipv6 impl
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
val socket_udpv4: Ipaddr.V4.t option -> udpv4 impl



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
val socket_tcpv4: Ipaddr.V4.t option -> tcpv4 impl



(** {Network stack configuration} *)

(** Implementation of the [V1.STACKV4] signature. *)

type stackv4

val stackv4: stackv4 typ

val direct_stackv4_with_default_ipv4:
  ?clock:clock impl ->
  ?random:random impl ->
  ?time:time impl ->
  console impl -> network impl -> stackv4 impl

val direct_stackv4_with_static_ipv4:
  ?clock:clock impl ->
  ?random:random impl ->
  ?time:time impl ->
  console impl -> network impl -> ipv4_config -> stackv4 impl

val direct_stackv4_with_dhcp:
  ?clock:clock impl ->
  ?random:random impl ->
  ?time:time impl ->
  console impl -> network impl -> stackv4 impl

val socket_stackv4: console impl -> Ipaddr.V4.t list -> stackv4 impl

(** {Resolver configuration} *)

type resolver
val resolver: resolver typ
val resolver_dns : ?ns:Ipaddr.V4.t -> ?ns_port:int -> stackv4 impl -> resolver impl
val resolver_unix_system : resolver impl

(** {Vchan configuration} *)
type vchan
val vchan: vchan typ
val vchan_localhost : ?uuid:string -> unit -> vchan impl
val vchan_xen : ?uuid:string -> unit -> vchan impl
val vchan_default : ?uuid:string -> unit -> vchan impl

(** {TLS configuration} *)
type conduit_tls
val tls_over_conduit : entropy impl -> conduit_tls impl

(** {Conduit configuration} *)

type conduit
val conduit: conduit typ
val conduit_direct : ?vchan:vchan impl -> ?tls:conduit_tls impl -> stackv4 impl -> conduit impl

type conduit_client = [
  | `TCP of Ipaddr.t * int
  | `Vchan of string list
]

type conduit_server = [
  | `TCP of [ `Port of int ]
  | `Vchan of string list
]

(** {HTTP configuration} *)

type http
val http: http typ
val http_server: conduit_server -> conduit impl -> http impl


(** {2 Tracing} *)

type tracing

val mprof_trace : size:int -> unit -> tracing
(** Use mirage-profile to trace the unikernel.
   On Unix, this creates and mmaps a file called "trace.ctf".
   On Xen, it shares the trace buffer with dom0. *)


(** {2 Jobs} *)

type job
(** Type for job values. *)

val job: job typ
(** Reprensention of [JOB]. *)

val register: ?tracing:tracing -> string -> job impl list -> unit
(** [register name jobs] registers the application named by [name]
    which will executes the given [jobs].
    @param tracing enables tracing if present (see {!mprof_trace}). *)

type t = {
  name: string;
  root: string;
  jobs: job impl list;
  tracing: tracing option;
}
(** Type for values representing a project description. *)

val load: string option -> t
(** Read a config file. If no name is given, search for use
    [config.ml]. *)

(** {2 Device configuration} *)

type mode = [
  | `Unix
  | `Xen
  | `MacOSX
]
(** Configuration mode. *)

val set_mode: mode -> unit
(** Set the configuration mode for the current project. *)

val get_mode: unit -> mode

module Impl: sig

  (** Configurable device. *)

  val name: 'a impl -> string
  (** The unique variable name of the value of type [t]. *)

  val module_name: 'a impl -> string
  (** The unique module name for the given implementation. *)

  val packages: 'a impl -> string list
  (** List of OPAM packages to install for this device. *)

  val libraries: 'a impl -> string list
  (** List of ocamlfind libraries. *)

  val configure: 'a impl -> unit
  (** Generate some code to create a value with the right
      configuration settings. *)

  val clean: 'a impl -> unit
  (** Remove all the autogen files. *)

end

(** {2 Project configuration} *)

val manage_opam_packages: bool -> unit
(** Tell Irminsule to manage the OPAM configuration
    (ie. install/remove missing packages). *)

val no_opam_version_check: bool -> unit
(** Bypass the check of opam's version. *)

val add_to_opam_packages: string list -> unit
(** Add some base OPAM package to install *)

val add_to_ocamlfind_libraries: string list -> unit
(** Link with the provided additional libraries. *)

val packages: t -> string list
(** List of OPAM packages to install for this project. *)

val libraries: t -> string list
(** List of ocamlfind libraries. *)

val add_to_bootvars: ?doc:string -> ?default:string -> string -> unit

val bootvars: t -> key list
(** List of boot vars. *)

val configure: t -> unit
(** Generate some code to create a value with the right
    configuration settings. *)

val clean: t -> unit
(** Remove all the autogen files. *)

val build: t -> unit
(** Call [make build] in the right directory. *)

(** {2 Extensions} *)

module type CONFIGURABLE = sig

  (** Signature for configurable devices. *)

  type t
  (** Abstract type for configurable devices. *)

  val name: t -> string
  (** Return the unique variable name holding the state of the given
      device. *)

  val module_name: t -> string
  (** Return the name of the module implementing the given device. *)

  val packages: t -> string list
  (** Return the list of OPAM packages which needs to be installed to
      use the given device. *)

  val libraries: t -> string list
  (** Return the list of ocamlfind libraries to link with the
      application to use the given device. *)

  val keys: t -> key list

  val configure: t -> unit
  (** Configure the given device. *)

  val clean: t -> unit
  (** Clean all the files generated to use the given device. *)

  val update_path: t -> string -> t
  (** [update_path t root] prefixes all the path appearing in [t] with
      the the prefix [root]. *)

end

val implementation: 'a -> 'b -> (module CONFIGURABLE with type t = 'b) -> 'a impl
(** Extend the library with an external configuration. *)

val append_main: ('a, unit, string, unit) format4 -> 'a
(** Add some string to [main.ml]. *)

val newline_main: unit -> unit
(** Add a newline to [main.ml]. *)

module Io_page: CONFIGURABLE
(** Implementation of IO page allocators. *)

module Clock: CONFIGURABLE
(** Implementation of clocks. *)

module Time: CONFIGURABLE
(** Implementation of timers. *)

module Random: CONFIGURABLE
(** Implementation of timers. *)

module Console: CONFIGURABLE
(** Implementation of consoles. *)

module Crunch: CONFIGURABLE
(** Implementation of crunch a local filesystem. *)

module Direct_kv_ro: CONFIGURABLE
(** Implementation of direct access to the filesystem as a key/value
    read-only store. *)

module Block: CONFIGURABLE
(** Implementation of raw block device. *)

module Fat: CONFIGURABLE
(** Implementatin of the Fat filesystem. *)

module Network: CONFIGURABLE
(** Implementation of network configuration. *)

module Ethif: CONFIGURABLE

module IPV4: CONFIGURABLE
module IPV6: CONFIGURABLE

module UDP_direct: functor (V : sig type t end) -> CONFIGURABLE
module UDPV4_socket: CONFIGURABLE

module TCP_direct: functor (V : sig type t end) -> CONFIGURABLE
module TCPV4_socket: CONFIGURABLE

module STACKV4_direct: CONFIGURABLE
module STACKV4_socket: CONFIGURABLE

module HTTP: CONFIGURABLE

module Job: CONFIGURABLE

(** {2 Generation of fresh names} *)

module Name: sig

  val create: string -> string
  (** [create base] creates a fresh name using the given [base]. *)

  val of_key: string -> base:string -> string
  (** [find_or_create key base] returns a unique name corresponding to
      the key. *)

end
