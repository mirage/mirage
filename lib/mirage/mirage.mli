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

(** {e Release %%VERSION%%} *)

(** {1 What is MirageOS?}

    MirageOS is a library operating system that can build standalone unikernels
    on various platforms. More precisely, the architecture can be divided into:

    - {e operating system libraries} that implement kernel and protocol
      functionality, ranging from low-level network card drivers to a full
      reimplementation of the TLS protocol, through to a reimplementation of the
      Git protocol to store versioned data.

    - A set of {e typed signatures} to make sure these libraries are consistent
      and can interoperate. As all the library are almost all pure OCaml code,
      we have defined {e a set of OCaml module types} that encode these
      conventions in a statically enforcable way. We make no compatibility
      guarantees at the C level, but compile those on a best-effort basis.

    - Finally, MirageOS is also a {e metaprogramming compiler} that generates
      OCaml code. It takes as input: the OCaml source code of a program and all
      of its dependencies, the full description of the deployment target,
      including configuration values (like the HTTP port to listen on, or the
      private key or the service being deployed). The `mirage`CLI tool uses all
      of these to {e generate a executable unikernel}: a specialised binary
      artefact containing only the code what is needed to run on the given
      deployment platform and no more.

    It is possible to write high-level MirageOS applications, such as HTTPS,
    email or CalDAV servers which can be deployed on very heterogenous and
    embedded platforms by changing only a few compilation parameters. The
    supported platforms range from minimal virtual machines running on cloud
    providers, or processes running inside Docker containers configured with a
    tight security profile. In general, these platform do not have a full POSIX
    environment; MirageOS does not try to emulate POSIX and focuses on providing
    a small, well-defined, typed interface with the system components. The
    nearest equivalent to the MirageOS approach is the WASI (wasi.dev) set of
    interfaces for WebAssembly.

    {2 Is everything really written in OCaml?}

    While most of the code is written in OCaml, a typed, high-level language
    with many good safety properties, there are pieces of MirageOS which are
    still written in C. These bits can be separated in three categories:

    - The OCaml runtime is written in C. It needs to be ported to the platform
      that MirageOS is trying to target, which do not support POSIX. Hence, the
      first component to port to a new platform is the OCaml runtime.

    - The low-level device drivers (network, console, clock, etc) also need some
      C bits.

    - The base usual C bindings; some libraries are widely used and
      (unfortunately) very hard (but not impossible) to replace them completely
      without taking a big performance hit or having to trust code without much
      real-world usages. This is the case for low-level bit handling for crypto
      code (even if we try to make sure allocation is alway handled by the OCaml
      runtime) as well as arbitrary precision numeric computation (e.g. gmp).
      Ideally we could image rewriting all of these libraries in OCaml if we had
      an infinite amount of time in our hands.

    {2 MirageOS as a cross-compilator}

    The MirageOS compiler is basically a cross-compiler, where the host and
    target toolchain are identical, but with different flags for the C bindings:
    for instance, it is necessary to pass [-freestanding] to {e all} C bindings
    to not use POSIX headers. The MirageOS compiler also uses a custom linker:
    eg. not only it needs a custom OCaml's runtime [libasmrun.a], but it also
    needs to run a different linker to generate specialised executable images.

    Historically, the OCaml ecosystem always had partial support for
    cross-compilation: for instance, the
    {{:https://github.com/ocaml-cross/opam-cross-windows} ocaml-cross} way of
    doing it is to duplicate {e all} existing opam pacakges by adding a
    [-windows] suffix to their names and dependencies; this allows normal
    packages and windows packages can be co-installed in the same opam switch.

    {3 MirageOS 3.x}

    MirageOS 3.x solves this by duplicating only the packages defining C
    bindings. It relies on every MirageOS backend registering a set of [CFLAGS]
    with [pkg-config]. Then every bindings uses [pkg-config] to configure their
    [CFLAGS] and [ocamlfind] to register
    {{:https://github.com/ocaml/opam-repository/blob/master/packages/zarith-xen/zarith-xen.1.7/files/mirage-install.sh#L20}
    link-time predicates}, e.g. additional link time options like the name of
    the C archives. Finally, the final link step is done by querying ocamlfind
    (using the custom registered predicates) to link the list of dependencies'
    objects files with the result of OCam compiler's [--output-obj] option.

    {4 MirageOS 4.x}

    MirageOS 4 solves this by relying on [dune]'s built-in support for
    cross-compilation. This is done by gathering all the sources of the
    dependencies locally with [opam-monorepo], and by creating a
    `dune-workspace` file describing the C flags to use in each
    cross-compilation "context". Once this is set-up, only one [dune build] can
    cross-compile the unikernel target with all its local sources.

    {1 MirageOS eDSL}

    The rest of the document describes Functoria, the embedded domain-specific
    language to be used in [config.ml] files, to described how the typed
    libraries have to be assembled. *)

include Functoria.DSL
(** @inline *)

(** Configuration keys. *)
module Key : module type of struct
  include Mirage_key
end
(** @inline *)

val abstract : 'a impl -> abstract_impl [@@ocaml.deprecated "Use Mirage.dep."]

(** {2 General mirage devices} *)

type tracing
(** The type for tracing. *)

val tracing : tracing typ
(** Implementation of the {!tracing} type. *)

val mprof_trace : size:int -> unit -> tracing impl
(** Use mirage-profile to trace the unikernel. On Unix, this creates and mmaps a
    file called "trace.ctf". On Xen, it shares the trace buffer with dom0.

    @param size: size of the ring buffer to use. *)

type qubesdb

val qubesdb : qubesdb typ
(** For the Qubes target, the Qubes database from which to look up * dynamic
    runtime configuration information. *)

val default_qubesdb : qubesdb impl
(** A default qubes database, guessed from the usual valid configurations. *)

(** {2 Time} *)

type time
(** Abstract type for timers. *)

val time : time typ
(** Implementations of the [Mirage_types.TIME] signature. *)

val default_time : time impl
(** The default timer implementation. *)

(** {2 Clocks} *)

type pclock
(** Abstract type for POSIX clocks. *)

val pclock : pclock typ
(** Implementations of the {!Mirage_types.PCLOCK} signature. *)

val default_posix_clock : pclock impl
(** The default mirage-clock PCLOCK implementation. *)

type mclock
(** Abstract type for monotonic clocks *)

val mclock : mclock typ
(** Implementations of the {!Mirage_types.MCLOCK} signature. *)

val default_monotonic_clock : mclock impl
(** The default mirage-clock MCLOCK implementation. *)

(** {2 Log reporters} *)

type reporter
(** The type for log reporters. *)

val reporter : reporter typ
(** Implementation of the log {!reporter} type. *)

val default_reporter :
  ?clock:pclock impl ->
  ?ring_size:int ->
  ?level:Logs.level ->
  unit ->
  reporter impl
(** [default_reporter ?clock ?level ()] is the log reporter that prints log
    messages to the console, timestampted with [clock]. If not provided, the
    default clock is {!default_posix_clock}. [level] is the default log
    threshold. It is [Logs.Info] if not specified. *)

val no_reporter : reporter impl
(** [no_reporter] disable log reporting. *)

(** {2 Random} *)

type random
(** Abstract type for random sources. *)

val random : random typ
(** Implementations of the [Mirage_types.RANDOM] signature. *)

val stdlib_random : random impl
  [@@ocaml.deprecated "Mirage will always use a Fortuna PRNG."]
(** Passthrough to the OCaml Random generator. *)

val nocrypto_random : random impl
  [@@ocaml.deprecated "Mirage will always use a Fortuna PRNG."]
(** Passthrough to the Fortuna PRNG implemented in nocrypto. *)

val default_random : random impl
(** Default PRNG device to be used in unikernels. It uses getrandom/getentropy
    on Unix, and a Fortuna PRNG on other targets. *)

val rng : ?time:time impl -> ?mclock:mclock impl -> unit -> random impl
(** [rng] is the device [Mirage_crypto_rng.Make]. *)

(** {2 Consoles} *)

type console
(** Abstract type for consoles. *)

val console : console typ
(** Implementations of the [Mirage_types.CONSOLE] signature. *)

val default_console : console impl
(** Default console implementation. *)

val custom_console : string -> console impl
(** Custom console implementation. *)

(** {2 Block devices} *)

type block
(** Abstract type for raw block device configurations. *)

val block : block typ
(** Implementations of the [Mirage_types.BLOCK] signature. *)

val block_of_file : string -> block impl
(** Use the given file as a raw block device. *)

val block_of_xenstore_id : string -> block impl
(** Use the given XenStore ID (ex: [/dev/xvdi1] or [51760]) as a raw block
    device. *)

val ramdisk : string -> block impl
(** Use a ramdisk with the given name. *)

val generic_block :
  ?group:string ->
  ?key:[ `XenstoreId | `BlockFile | `Ramdisk ] value ->
  string ->
  block impl

(** {2 Static key/value stores} *)

type kv_ro
(** Abstract type for read-only key/value store. *)

val kv_ro : kv_ro typ
(** Implementations of the [Mirage_types.KV_RO] signature. *)

val crunch : string -> kv_ro impl
(** Crunch a directory. *)

val archive : block impl -> kv_ro impl

val archive_of_files : ?dir:string -> unit -> kv_ro impl

val direct_kv_ro : string -> kv_ro impl
(** Direct access to the underlying filesystem as a key/value store. For Xen
    backends, this is equivalent to [crunch]. *)

val generic_kv_ro :
  ?group:string ->
  ?key:[ `Archive | `Crunch | `Direct | `Fat ] value ->
  string ->
  kv_ro impl
(** Generic key/value that will choose dynamically between {!fat}, {!archive}
    and {!crunch}. To use a filesystem implementation, try {!kv_ro_of_fs}.

    If no key is provided, it uses {!Key.kv_ro} to create a new one. *)

type kv_rw
(** Abstract type for read-write key/value store. *)

val kv_rw : kv_rw typ
(** Implementations of the [Mirage_types.KV_RW] signature. *)

val direct_kv_rw : string -> kv_rw impl
(** Direct access to the underlying filesystem as a key/value store. Only
    available on Unix backends. *)

val kv_rw_mem : ?clock:pclock impl -> unit -> kv_rw impl
(** An in-memory key-value store using [mirage-kv-mem]. *)

(** {2 Filesystem} *)

type fs
(** Abstract type for filesystems. *)

val fs : fs typ
(** Implementations of the [Mirage_types.FS] signature. *)

val fat : block impl -> fs impl
(** Consider a raw block device as a FAT filesystem. *)

val fat_of_files : ?dir:string -> ?regexp:string -> unit -> fs impl
(** [fat_files dir ?dir ?regexp ()] collects all the files matching the shell
    pattern [regexp] in the directory [dir] into a FAT image. By default, [dir]
    is the current working directory and [regexp] is {i *} *)

val kv_ro_of_fs : fs impl -> kv_ro impl
(** Consider a filesystem implementation as a read-only key/value store. *)

(** {2 Network interfaces} *)

type network
(** Abstract type for network configurations. *)

val network : network typ
(** Implementations of the [Mirage_types.NETWORK] signature. *)

val default_network : network impl
(** [default_network] is a dynamic network implementation * which attempts to do
    something reasonable based on the target. *)

val netif : ?group:string -> string -> network impl
(** A custom network interface. Exposes a {!Key.interface} key. *)

(** {2 Ethernet configuration} *)

type ethernet

val ethernet : ethernet typ
(** Implementations of the [Mirage_types.ETHERNET] signature. *)

val etif : network impl -> ethernet impl

(** {2 ARP configuration} *)

type arpv4

val arpv4 : arpv4 typ
(** Implementation of the [Mirage_types.ARPV4] signature. *)

val arp : ?time:time impl -> ethernet impl -> arpv4 impl
(** ARP implementation provided by the arp library *)

(** {2 IP configuration}

    Implementations of the [Mirage_types.IP] signature. *)

type v4

type v6

type v4v6

type 'a ip
(** Abstract type for IP configurations. *)

type ipv4 = v4 ip

type ipv6 = v6 ip

type ipv4v6 = v4v6 ip

val ipv4 : ipv4 typ
(** The [Mirage_types.IPV4] module signature. *)

val ipv6 : ipv6 typ
(** The [Mirage_types.IPV6] module signature. *)

val ipv4v6 : ipv4v6 typ
(** The [Mirage_types.IP] module signature with ipaddr = Ipaddr.t. *)

type ipv4_config = {
  network : Ipaddr.V4.Prefix.t;
  gateway : Ipaddr.V4.t option;
}
(** Types for manual IPv4 configuration. *)

type ipv6_config = {
  network : Ipaddr.V6.Prefix.t;
  gateway : Ipaddr.V6.t option;
}
(** Types for manual IPv6 configuration. *)

val create_ipv4 :
  ?group:string ->
  ?config:ipv4_config ->
  ?no_init:bool Key.key ->
  ?random:random impl ->
  ?clock:mclock impl ->
  ethernet impl ->
  arpv4 impl ->
  ipv4 impl
(** Use an IPv4 address Exposes the keys {!Key.V4.network} and
    {!Key.V4.gateway}. If provided, the values of these keys will override those
    supplied in the ipv4 configuration record, if that has been provided. *)

val ipv4_qubes :
  ?random:random impl ->
  ?clock:mclock impl ->
  qubesdb impl ->
  ethernet impl ->
  arpv4 impl ->
  ipv4 impl
(** Use a given initialized QubesDB to look up and configure the appropriate *
    IPv4 interface. *)

val create_ipv6 :
  ?random:random impl ->
  ?time:time impl ->
  ?clock:mclock impl ->
  ?group:string ->
  ?config:ipv6_config ->
  ?no_init:bool Key.key ->
  network impl ->
  ethernet impl ->
  ipv6 impl
(** Use an IPv6 address. Exposes the keys {!Key.V6.network}, {!Key.V6.gateway}. *)

val create_ipv4v6 : ?group:string -> ipv4 impl -> ipv6 impl -> ipv4v6 impl

(** {2 UDP configuration} *)

type 'a udp

type udpv4 = v4 udp

type udpv6 = v6 udp

type udpv4v6 = v4v6 udp

val udp : 'a udp typ
(** Implementation of the [Mirage_types.UDP] signature. *)

val udpv4 : udpv4 typ

val udpv6 : udpv6 typ

val udpv4v6 : udpv4v6 typ

val direct_udp : ?random:random impl -> 'a ip impl -> 'a udp impl

val socket_udpv4 : ?group:string -> Ipaddr.V4.t option -> udpv4 impl

val socket_udpv6 : ?group:string -> Ipaddr.V6.t option -> udpv6 impl

val socket_udpv4v6 :
  ?group:string -> Ipaddr.V4.t option -> Ipaddr.V6.t option -> udpv4v6 impl

(** {2 TCP configuration} *)

type 'a tcp

type tcpv4 = v4 tcp

type tcpv6 = v6 tcp

type tcpv4v6 = v4v6 tcp

val tcp : 'a tcp typ
(** Implementation of the [Mirage_types.TCP] signature. *)

val tcpv4 : tcpv4 typ

val tcpv6 : tcpv6 typ

val tcpv4v6 : tcpv4v6 typ

val direct_tcp :
  ?mclock:mclock impl ->
  ?time:time impl ->
  ?random:random impl ->
  'a ip impl ->
  'a tcp impl

val socket_tcpv4 : ?group:string -> Ipaddr.V4.t option -> tcpv4 impl

val socket_tcpv6 : ?group:string -> Ipaddr.V6.t option -> tcpv6 impl

val socket_tcpv4v6 :
  ?group:string -> Ipaddr.V4.t option -> Ipaddr.V6.t option -> tcpv4v6 impl

(** {2 Network stack configuration} *)

type stackv4
(** {3 IPv4} *)

val stackv4 : stackv4 typ
(** Implementation of the [Mirage_types.STACKV4] signature. *)

val direct_stackv4 :
  ?mclock:mclock impl ->
  ?time:time impl ->
  ?random:random impl ->
  network impl ->
  ethernet impl ->
  arpv4 impl ->
  ipv4 impl ->
  stackv4 impl
(** Direct network stack with given ip. *)

val socket_stackv4 : ?group:string -> unit -> stackv4 impl
(** Network stack with sockets. *)

val qubes_ipv4_stack :
  ?qubesdb:qubesdb impl ->
  ?arp:(ethernet impl -> arpv4 impl) ->
  network impl ->
  stackv4 impl
(** Build a stackv4 by looking up configuration information via QubesDB, *
    building an ipv4, then building a stack on top of that. *)

val dhcp_ipv4_stack :
  ?random:random impl ->
  ?clock:mclock impl ->
  ?time:time impl ->
  ?arp:(ethernet impl -> arpv4 impl) ->
  network impl ->
  stackv4 impl
(** Build a stackv4 by obtaining a DHCP lease, using the lease to * build an
    ipv4, then building a stack on top of that. *)

val static_ipv4_stack :
  ?group:string ->
  ?config:ipv4_config ->
  ?arp:(ethernet impl -> arpv4 impl) ->
  network impl ->
  stackv4 impl
(** Build a stackv4 by checking the {!Key.V4.network}, and {!Key.V4.gateway}
    keys * for ipv4 configuration information, filling in unspecified
    information from [?config], * then building a stack on top of that. *)

val generic_stackv4 :
  ?group:string ->
  ?config:ipv4_config ->
  ?dhcp_key:bool value ->
  ?net_key:[ `Direct | `Socket ] option value ->
  network impl ->
  stackv4 impl
(** Generic stack using a [dhcp] and a [net] keys: {!Key.net} and {!Key.dhcp}.

    - If [target] = [Qubes] then {!qubes_ipv4_stack} is used
    - Else, if [net] = [socket] then {!socket_stackv4} is used
    - Else, if [dhcp] then {!dhcp_ipv4_stack} is used
    - Else, if [unix or macosx] then {!socket_stackv4} is used
    - Else, {!static_ipv4_stack} is used.

    If a key is not provided, it uses {!Key.net} or {!Key.dhcp} (with the
    [group] argument) to create it. *)

(** {3 IPv6} *)

type stackv6

val stackv6 : stackv6 typ
(** Implementation of the [Mirage_stack.V6] signature. *)

val direct_stackv6 :
  ?mclock:mclock impl ->
  ?random:random impl ->
  ?time:time impl ->
  network impl ->
  ethernet impl ->
  ipv6 impl ->
  stackv6 impl
(** Direct network stack with given ip. *)

val socket_stackv6 : ?group:string -> unit -> stackv6 impl
(** Network stack with sockets. *)

val static_ipv6_stack :
  ?group:string -> ?config:ipv6_config -> network impl -> stackv6 impl
(** Build a stackv6 by checking the {!Key.V6.network}, and {!Key.V6.gateway}
    keys for ipv6 configuration information, filling in unspecified information
    from [?config], then building a stack on top of that. *)

val generic_stackv6 :
  ?group:string ->
  ?config:ipv6_config ->
  ?net_key:[ `Direct | `Socket ] option value ->
  network impl ->
  stackv6 impl
(** Generic stack using a [net] keys: {!Key.net}.

    - If [net] = [socket] then {!socket_stackv6} is used
    - Else, if [unix or macosx] then {!socket_stackv6} is used
    - Else, {!static_ipv6_stack} is used.

    If a key is not provided, it uses {!Key.net} (with the [group] argument) to
    create it. *)

(** {3 Dual IPv4 and IPv6} *)

type stackv4v6

val stackv4v6 : stackv4v6 typ
(** Implementation of the [Mirage_stack.V4V6] signature. *)

val direct_stackv4v6 :
  ?mclock:mclock impl ->
  ?random:random impl ->
  ?time:time impl ->
  ipv4_only:bool Key.key ->
  ipv6_only:bool Key.key ->
  network impl ->
  ethernet impl ->
  arpv4 impl ->
  ipv4 impl ->
  ipv6 impl ->
  stackv4v6 impl
(** Direct network stack with given ip. *)

val socket_stackv4v6 : ?group:string -> unit -> stackv4v6 impl
(** Network stack with sockets. *)

val static_ipv4v6_stack :
  ?group:string ->
  ?ipv6_config:ipv6_config ->
  ?ipv4_config:ipv4_config ->
  ?arp:(ethernet impl -> arpv4 impl) ->
  network impl ->
  stackv4v6 impl
(** Build a stackv4v6 by checking the {!Key.V6.network}, and {!Key.V6.gateway}
    keys for IPv4 and IPv6 configuration information, filling in unspecified
    information from [?config], then building a stack on top of that. *)

val generic_stackv4v6 :
  ?group:string ->
  ?ipv6_config:ipv6_config ->
  ?ipv4_config:ipv4_config ->
  ?dhcp_key:bool value ->
  ?net_key:[ `Direct | `Socket ] option value ->
  network impl ->
  stackv4v6 impl
(** Generic stack using a [net] keys: {!Key.net}.

    - If [net] = [socket] then {!socket_stackv4v6} is used
    - Else, if [unix or macosx] then {!socket_stackv4v6} is used
    - Else, {!static_ipv4v6_stack} is used.

    If a key is not provided, it uses {!Key.net} (with the [group] argument) to
    create it. *)

(** {2 Resolver configuration} *)

type resolver

val resolver : resolver typ

val resolver_dns :
  ?ns:Ipaddr.t ->
  ?ns_port:int ->
  ?time:time impl ->
  ?mclock:mclock impl ->
  ?random:random impl ->
  stackv4v6 impl ->
  resolver impl

val resolver_unix_system : resolver impl

(** {2 Syslog configuration} *)

(** Syslog exfiltrates log messages (generated by libraries using the [logs]
    library) via a network connection. The log level of the log sources is
    controlled via the {!Mirage_key.logs} key. The functionality is provided by
    the [logs-syslog] package. *)

type syslog_config = {
  hostname : string;
  server : Ipaddr.t option;
  port : int option;
  truncate : int option;
}

val syslog_config :
  ?port:int -> ?truncate:int -> ?server:Ipaddr.t -> string -> syslog_config
(** Helper for constructing a {!syslog_config}. *)

type syslog
(** The type for syslog *)

val syslog : syslog typ
(** Implementation of the {!syslog} type. *)

val syslog_udp :
  ?config:syslog_config ->
  ?console:console impl ->
  ?clock:pclock impl ->
  stackv4v6 impl ->
  syslog impl
(** Emit log messages via UDP to the configured host. *)

val syslog_tcp :
  ?config:syslog_config ->
  ?console:console impl ->
  ?clock:pclock impl ->
  stackv4v6 impl ->
  syslog impl
(** Emit log messages via TCP to the configured host. *)

val syslog_tls :
  ?config:syslog_config ->
  ?keyname:string ->
  ?console:console impl ->
  ?clock:pclock impl ->
  stackv4v6 impl ->
  kv_ro impl ->
  syslog impl
(** Emit log messages via TLS to the configured host, using the credentials
    (private key, certificate, trust anchor) provided in the KV_RO using the
    [keyname]. *)

(** {2 Entropy} *)

val nocrypto : job impl
  [@@ocaml.deprecated "nocrypto is deprecated and not needed anymore."]
(** Device that initializes the entropy. *)

(** {2 Conduit configuration} *)

type conduit

val conduit : conduit typ

val conduit_direct :
  ?tls:bool -> ?random:random impl -> stackv4v6 impl -> conduit impl

(** {2 HTTP configuration} *)

type http

val http : http typ

val http_server : conduit impl -> http impl
  [@@ocaml.deprecated
    "`http_server` is deprecated. Please use `cohttp_server` or \
     `httpaf_server` instead."]

val cohttp_server : conduit impl -> http impl
(** [cohttp_server] starts a Cohttp server. *)

val httpaf_server : conduit impl -> http impl
(** [httpaf_server] starts a http/af server. *)

type http_client

val http_client : http_client typ

val cohttp_client :
  ?pclock:pclock impl -> resolver impl -> conduit impl -> http_client impl
(** [cohttp_server] starts a Cohttp server. *)

(** {2 Argv configuration} *)

type argv = Functoria.argv

val argv : argv typ

val default_argv : argv impl
(** [default_argv] is a dynamic argv implementation * which attempts to do
    something reasonable based on the target. *)

val no_argv : argv impl
(** [no_argv] Disable command line parsing and set argv to [|""|]. *)

(** {2 Other devices} *)

val job : job typ
(** [job] is the combinator for representing main tasks. *)

val noop : job impl
(** [noop] is a job that does nothing, has no dependency and returns [()] *)

val keys : argv impl -> job impl
(** [keys argv] is a job that loads argv. *)

(* fix compilation on ocaml<4.08 *)
(* type info
   (** [info] is the type for module implementing
       {!Mirage_runtime.Info}. *) *)

val info : info typ
(** [info] is the combinator to generate {!info} values to use at runtime. *)

val app_info : info impl
(** [app_info] exports all the information available at configure time into a
    runtime {!Mirage.Info.t} value. *)

val app_info_with_opam_deps : (string * string) list -> info impl
(** [app_info] exports all the information available at configure time into a
    runtime {!Mirage.Info.t} value. *)

(** {2 Application registering} *)

val register :
  ?argv:argv impl ->
  ?tracing:tracing impl ->
  ?reporter:reporter impl ->
  ?keys:Key.t list ->
  ?packages:Functoria.package list ->
  ?src:[ `Auto | `None | `Some of string ] ->
  string ->
  job impl list ->
  unit
(** [register name jobs] registers the application named by [name] which will
    executes the given [jobs].

    @param packages The opam packages needed by this module.
    @param keys The keys related to this module.
    @param tracing Enable tracing.
    @param reporter
      Configure logging. The default log reporter is {!default_reporter}. To
      disable logging, use {!no_reporter}.
    @param argv
      Configure command-line argument parsing. The default parser is
      {!default_argv}. To disable command-line parsing, use {!no_argv}. *)

module Type = Functoria.Type
module Impl = Functoria.Impl
module Info = Functoria.Info
module Dune = Functoria.Dune
module Action = Functoria.Action

module FS : sig
  val fat_shell_script :
    Format.formatter ->
    block_file:string ->
    dir:Fpath.t ->
    regexp:string ->
    unit
end

module Project : sig
  val dune : Info.t -> Dune.stanza list

  val configure : Info.t -> unit Action.t
end

module Tool : sig
  val run : unit -> unit
end
