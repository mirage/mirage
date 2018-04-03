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

(** Mirage combinators.

    [Mirage] devices a set of devices and combinator to to define
    portable applications across all platforms that MirageOS
    supports.

   {e Release %%VERSION%% } *)


(** Configuration keys. *)
module Key : module type of struct include Mirage_key end

include Functoria_app.DSL

(** {2 General mirage devices} *)

type tracing
(** The type for tracing. *)

val tracing: tracing typ
(** Implementation of the {!tracing} type. *)

val mprof_trace : size:int -> unit -> tracing impl
(** Use mirage-profile to trace the unikernel. On Unix, this creates
    and mmaps a file called "trace.ctf". On Xen, it shares the trace
    buffer with dom0.

    @param size: size of the ring buffer to use. *)

type qubesdb

val qubesdb: qubesdb typ
(** For the Qubes target, the Qubes database from which to look up
 *  dynamic runtime configuration information. *)

val default_qubesdb: qubesdb impl
(** A default qubes database, guessed from the usual valid configurations. *)


(** {2 Time} *)

type time
(** Abstract type for timers. *)

val time: time typ
(** Implementations of the [Mirage_types.TIME] signature. *)

val default_time: time impl
(** The default timer implementation. *)



(** {2 Clocks} *)

type pclock
(** Abstract type for POSIX clocks. *)

val pclock: pclock typ
(** Implementations of the {!Mirage_types.PCLOCK} signature. *)

val default_posix_clock: pclock impl
(** The default mirage-clock PCLOCK implementation. *)

type mclock
(** Abstract type for monotonic clocks *)

val mclock: mclock typ
(** Implementations of the {!Mirage_types.MCLOCK} signature. *)

val default_monotonic_clock: mclock impl
(** The default mirage-clock MCLOCK implementation. *)



(** {2 Log reporters} *)

type reporter
(** The type for log reporters. *)

val reporter: reporter typ
(** Implementation of the log {!reporter} type. *)

val default_reporter:
  ?clock:pclock impl -> ?ring_size:int -> ?level:Logs.level ->
  unit -> reporter impl
(** [default_reporter ?clock ?level ()] is the log reporter that
    prints log messages to the console, timestampted with [clock]. If
    not provided, the default clock is {!default_posix_clock}. [level] is
    the default log threshold. It is [Logs.Info] if not
    specified. *)

val no_reporter: reporter impl
(** [no_reporter] disable log reporting. *)



(** {2 Random} *)

type random
(** Abstract type for random sources. *)

val random: random typ
(** Implementations of the [Mirage_types.RANDOM] signature. *)

val stdlib_random: random impl
(** Passthrough to the OCaml Random generator. *)

val nocrypto_random: random impl
(** Passthrough to the Fortuna PRNG implemented in nocrypto. *)

val default_random: random impl
(** Default PRNG device to be used in unikernels.  It defaults to {!stdlib}, but
    users can override using the {!Key.prng} command line argument.
*)



(** {2 Consoles} *)

type console
(** Abstract type for consoles. *)

val console: console typ
(** Implementations of the [Mirage_types.CONSOLE] signature. *)

val default_console: console impl
(** Default console implementation. *)

val custom_console: string -> console impl
(** Custom console implementation. *)



(** {2 Memory allocation interface} *)

type io_page
(** Abstract type for page-aligned buffers. *)

val io_page: io_page typ
(** Implementations of the [Mirage_types.IO_PAGE] signature. *)

val default_io_page: io_page impl
(** The default [Io_page] implementation. *)



(** {2 Block devices} *)


type block
(** Abstract type for raw block device configurations. *)

val block: block typ
(** Implementations of the [Mirage_types.BLOCK] signature. *)

val block_of_file: string -> block impl
(** Use the given file as a raw block device. *)

val block_of_xenstore_id: string -> block impl
(** Use the given XenStore ID (ex: [/dev/xvdi1] or [51760]) as a raw block device. *)

val ramdisk: string -> block impl
(** Use a ramdisk with the given name. *)

val generic_block:
  ?key:[ `XenstoreId | `BlockFile | `Ramdisk ] value -> string -> block impl

(** {2 Static key/value stores} *)

type kv_ro
(** Abstract type for read-only key/value store. *)

val kv_ro: kv_ro typ
(** Implementations of the [Mirage_types.KV_RO] signature. *)

val crunch: string -> kv_ro impl
(** Crunch a directory. *)

val archive: block impl -> kv_ro impl

val archive_of_files: ?dir:string -> unit -> kv_ro impl

val direct_kv_ro: string -> kv_ro impl
(** Direct access to the underlying filesystem as a key/value
    store. For Xen backends, this is equivalent to [crunch]. *)



(** {2 Filesystem} *)


type fs
(** Abstract type for filesystems. *)

val fs: fs typ
(** Implementations of the [Mirage_types.FS] signature. *)

val fat: block impl -> fs impl
(** Consider a raw block device as a FAT filesystem. *)

val fat_of_files: ?dir:string -> ?regexp:string -> unit -> fs impl
(** [fat_files dir ?dir ?regexp ()] collects all the files matching
    the shell pattern [regexp] in the directory [dir] into a FAT
    image. By default, [dir] is the current working directory and
    [regexp] is {i *} *)

val kv_ro_of_fs: fs impl -> kv_ro impl
(** Consider a filesystem implementation as a read-only key/value
    store. *)

(** {2 Generic key/value stores} *)

val generic_kv_ro:
  ?key:[ `Archive | `Crunch | `Direct | `Fat ] value -> string -> kv_ro impl
(** Generic key/value that will choose dynamically between
    {!fat}, {!archive} and {!crunch}.  To use a filesystem implementation,
    try {!kv_ro_of_fs}.

    If no key is provided, it uses {!Key.kv_ro} to create a new one.
*)


(** {2 Network interfaces} *)


type network
(** Abstract type for network configurations. *)

val network: network typ
(** Implementations of the [Mirage_types.NETWORK] signature. *)

val default_network: network impl
(** [default_network] is a dynamic network implementation
 *  which attempts to do something reasonable based on the target. *)

val netif: ?group:string -> string -> network impl
(** A custom network interface. Exposes a {!Key.interface} key. *)



(** {2 Ethernet configuration} *)

type ethernet

val ethernet: ethernet typ
(** Implementations of the [Mirage_types.ETHIF] signature. *)

val etif: network impl -> ethernet impl

(** {2 ARP configuration} *)

type arpv4

val arpv4: arpv4 typ
(** Implementation of the [Mirage_types.ARPV4] signature. *)

val arp: ?clock:mclock impl -> ?time:time impl -> ethernet impl -> arpv4 impl

val farp : ?clock:mclock impl -> ?time:time impl -> ethernet impl -> arpv4 impl
(** Functional ARP implementation provided by the arp library *)

(** {2 IP configuration}

    Implementations of the [Mirage_types.IP] signature. *)

type v4
type v6

(** Abstract type for IP configurations. *)
type 'a ip
type ipv4 = v4 ip
type ipv6 = v6 ip

val ipv4: ipv4 typ
(** The [Mirage_types.IPV4] module signature. *)

val ipv6: ipv6 typ
(** The [Mirage_types.IPV6] module signature. *)

type ipv4_config = {
  network : Ipaddr.V4.Prefix.t * Ipaddr.V4.t;
  gateway : Ipaddr.V4.t option;
}
(** Types for IPv4 manual configuration. *)

type ipv6_config = {
  addresses : Ipaddr.V6.t list;
  netmasks  : Ipaddr.V6.Prefix.t list;
  gateways  : Ipaddr.V6.t list;
}
(** Types for IP manual configuration. *)

val create_ipv4: ?group:string ->
  ?config:ipv4_config -> ethernet impl -> arpv4 impl -> ipv4 impl
(** Use an IPv4 address
    Exposes the keys {!Key.V4.network} and {!Key.V4.gateway}.
    If provided, the values of these keys will override those supplied
    in the ipv4 configuration record, if that has been provided.
*)

val ipv4_qubes: qubesdb impl -> ethernet impl -> arpv4 impl -> ipv4 impl
(** Use a given initialized QubesDB to look up and configure the appropriate
 *  IPv4 interface. *)

val create_ipv6:
  ?random:random impl -> ?time:time impl -> ?clock:mclock impl ->
  ?group:string -> ethernet impl -> ipv6_config -> ipv6 impl
(** Use an IPv6 address.
    Exposes the keys {!Key.V6.ips}, {!Key.V6.netmasks} and {!Key.V6.gateways}.
*)



(** {2 UDP configuration} *)

type 'a udp
type udpv4 = v4 udp
type udpv6 = v6 udp

(** Implementation of the [Mirage_types.UDP] signature. *)
val udp: 'a udp typ
val udpv4: udpv4 typ
val udpv6: udpv6 typ

val direct_udp: ?random:random impl -> 'a ip impl -> 'a udp impl

val socket_udpv4: ?group:string -> Ipaddr.V4.t option -> udpv4 impl



(** {2 TCP configuration} *)

type 'a tcp
type tcpv4 = v4 tcp
type tcpv6 = v6 tcp

(** Implementation of the [Mirage_types.TCP] signature. *)
val tcp: 'a tcp typ
val tcpv4: tcpv4 typ
val tcpv6: tcpv6 typ

val direct_tcp:
  ?clock:mclock impl ->
  ?random:random impl ->
  ?time:time impl ->
  'a ip impl -> 'a tcp impl

val socket_tcpv4: ?group:string -> Ipaddr.V4.t option -> tcpv4 impl



(** {2 Network stack configuration} *)

type stackv4

val stackv4: stackv4 typ
(** Implementation of the [Mirage_types.STACKV4] signature. *)

(** Direct network stack with given ip. *)
val direct_stackv4:
  ?clock:mclock impl ->
  ?random:random impl ->
  ?time:time impl ->
  ?group:string ->
  network impl -> ethernet impl -> arpv4 impl -> ipv4 impl -> stackv4 impl

(** Network stack with sockets. Exposes the key {!Key.V4.interfaces}. *)
val socket_stackv4:
  ?group:string -> Ipaddr.V4.t list -> stackv4 impl

(** Build a stackv4 by looking up configuration information via QubesDB,
 *  building an ipv4, then building a stack on top of that. *)
val qubes_ipv4_stack: ?group:string -> ?qubesdb:qubesdb impl -> ?arp:(ethernet impl -> arpv4 impl) -> network impl -> stackv4 impl

(** Build a stackv4 by obtaining a DHCP lease, using the lease to
 *  build an ipv4, then building a stack on top of that. *)
val dhcp_ipv4_stack: ?group:string -> ?time:time impl -> ?arp:(ethernet impl -> arpv4 impl) -> network impl -> stackv4 impl

(** Build a stackv4 by checking the {!Key.V4.network}, and {!Key.V4.gateway} keys
 *  for ipv4 configuration information, filling in unspecified information from [?config],
 *  then building a stack on top of that. *)
val static_ipv4_stack: ?group:string -> ?config:ipv4_config -> ?arp:(ethernet impl -> arpv4 impl) -> network impl -> stackv4 impl

(** Generic stack using a [dhcp] and a [net] keys: {!Key.net} and {!Key.dhcp}.
    - If [target] = [Qubes] then {!qubes_ipv4_stack} is used.
    - If [net] = [socket] then {!socket_stackv4} is used.
    - Else, if [dhcp] then {!dhcp_ipv4_stack} is used
    - Else, {!static_ipv4_stack} is used.

    If a key is not provided, it uses {!Key.net} or {!Key.dhcp} (with the
    [group] argument) to create it.
*)
val generic_stackv4:
  ?group:string -> ?config:ipv4_config ->
  ?dhcp_key:bool value ->
  ?net_key:[ `Direct | `Socket ] value ->
  network impl -> stackv4 impl

(** {2 Resolver configuration} *)

type resolver
val resolver: resolver typ
val resolver_dns:
  ?ns:Ipaddr.V4.t -> ?ns_port:int -> ?time:time impl -> stackv4 impl -> resolver impl
val resolver_unix_system: resolver impl

(** {2 Syslog configuration} *)

(** Syslog exfiltrates log messages (generated by libraries using the [logs]
    library) via a network connection.  The log level of the log sources is
    controlled via the {!Mirage_key.logs} key.  The functionality is provided
    by the [logs-syslog] package. *)

type syslog_config = {
  hostname : string;
  server   : Ipaddr.V4.t option;
  port     : int option;
  truncate : int option
}

val syslog_config: ?port:int -> ?truncate:int -> ?server:Ipaddr.V4.t -> string -> syslog_config
(** Helper for constructing a {!syslog_config}. *)

type syslog
(** The type for syslog *)

val syslog: syslog typ
(** Implementation of the {!syslog} type. *)

val syslog_udp: ?config:syslog_config -> ?console:console impl -> ?clock:pclock impl -> stackv4 impl -> syslog impl
(** Emit log messages via UDP to the configured host. *)

val syslog_tcp: ?config:syslog_config -> ?console:console impl -> ?clock:pclock impl -> stackv4 impl -> syslog impl
(** Emit log messages via TCP to the configured host. *)

val syslog_tls: ?config:syslog_config -> ?keyname:string -> ?console:console impl -> ?clock:pclock impl -> stackv4 impl -> kv_ro impl -> syslog impl
(** Emit log messages via TLS to the configured host, using the credentials
    (private ekey, certificate, trust anchor) provided in the KV_RO using the
    [keyname]. *)

(** {2 Entropy} *)

val nocrypto: job impl
(** Device that initializes the entropy. *)

(** {2 Conduit configuration} *)

type conduit
val conduit: conduit typ
val conduit_direct: ?tls:bool -> stackv4 impl -> conduit impl

(** {2 HTTP configuration} *)

type http
val http: http typ
val http_server: conduit impl -> http impl

(** {2 Argv configuration} *)

val default_argv: Functoria_app.argv impl
(** [default_argv] is a dynamic argv implementation
 *  which attempts to do something reasonable based on the target. *)

val no_argv: Functoria_app.argv impl
(** [no_argv] Disable command line parsing and set argv to [|""|]. *)

(** {2 Other devices} *)

val noop: job impl
(** [noop] is a job that does nothing, has no dependency and returns [()] *)

type info
(** [info] is the type for module implementing
    {!Mirage_runtime.Info}. *)

val info: info typ
(** [info] is the combinator to generate {!info} values to use at
    runtime. *)

val app_info: info impl
(** [app_info] exports all the information available at configure time
    into a runtime {!Mirage.Info.t} value. *)

(** {2 Application registering} *)

val register:
  ?argv:Functoria_app.argv impl ->
  ?tracing:tracing impl ->
  ?reporter:reporter impl ->
  ?keys:Key.t list ->
  ?packages:Functoria.package list -> string -> job impl list -> unit
(** [register name jobs] registers the application named by [name]
    which will executes the given [jobs].
    @param packages The opam packages needed by this module.
    @param keys The keys related to this module.

    @param tracing Enable tracing.

    @param reporter Configure logging. The default log reporter is
    {!default_reporter}. To disable logging, use {!no_reporter}.

    @param argv Configure command-line argument parsing. The default
    parser is {!default_argv}. To disable command-line parsing, use
    {!no_argv}.
*)


(**/**)

val run: unit -> unit
