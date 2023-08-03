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
  (** @inline *)
end

val abstract : 'a impl -> abstract_impl [@@ocaml.deprecated "Use Mirage.dep."]

(** {2 General mirage devices} *)

type qubesdb

val qubesdb : qubesdb typ
(** For the Qubes target, the Qubes database from which to look up dynamic
    runtime configuration information. *)

val default_qubesdb : qubesdb impl
(** A default qubes database, guessed from the usual valid configurations. *)

(** {2 Time} *)

type time
(** Abstract type for timers. *)

val time : time typ
(** Implementations of the [Mirage_time.S] signature. *)

val default_time : time impl
(** The default timer implementation. *)

(** {2 Clocks} *)

type pclock
(** Abstract type for POSIX clocks. *)

val pclock : pclock typ
(** Implementations of the [Mirage_clock.PCLOCK] signature. *)

val default_posix_clock : pclock impl
(** The default mirage-clock [Mirage_clock.PCLOCK] implementation. *)

type mclock
(** Abstract type for monotonic clocks *)

val mclock : mclock typ
(** Implementations of the [Mirage_clock.MCLOCK] signature. *)

val default_monotonic_clock : mclock impl
(** The default mirage-clock [Mirage_clock.MCLOCK] implementation. *)

(** {2 Log reporters} *)

type reporter
(** The type for log reporters. *)

val reporter : reporter typ
(** Implementation of the log {!type:reporter} type. *)

val default_reporter :
  ?clock:pclock impl -> ?level:Logs.level option -> unit -> reporter impl
(** [default_reporter ?clock ?level ()] is the log reporter that prints log
    messages to the console, timestampted with [clock]. If not provided, the
    default clock is {!default_posix_clock}. [level] is the default log
    threshold. It is [Some Logs.Info] if not specified. *)

val no_reporter : reporter impl
(** [no_reporter] disable log reporting. *)

(** {2 Random} *)

type random
(** Abstract type for random sources. *)

val random : random typ
(** Implementations of the [Mirage_random.S] signature. *)

val default_random : random impl
(** Default PRNG device to be used in unikernels. It uses getrandom/getentropy
    on Unix, and a Fortuna PRNG on other targets. *)

val rng : ?time:time impl -> ?mclock:mclock impl -> unit -> random impl
(** [rng ()] is the device [Mirage_crypto_rng.Make]. *)

(** {2 Consoles} *)

type console
(** Abstract type for consoles. *)

val console : console typ
  [@@ocaml.deprecated "use Logs and Printf instead"]
(** Implementations of the [Mirage_console.S] signature. *)

val default_console : console impl
  [@@ocaml.deprecated "use Logs and Printf instead"]
(** Default console implementation. *)

val custom_console : string -> console impl
  [@@ocaml.deprecated "use Logs and Printf instead"]
(** Custom console implementation. *)

(** {2 Block devices} *)

type block
(** Abstract type for raw block device configurations. *)

val block : block typ
(** Implementations of the [Mirage_block.S] signature. *)

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
(** Implementations of the [Mirage_kv.RO] signature. *)

val crunch : string -> kv_ro impl
(** Crunch a directory. The contents of the directory is transformed into OCaml
    code, which is then compiled as part of the unikernel. *)

val tar_kv_ro : block impl -> kv_ro impl
(** [tar_kv_ro block] is a read-only tar archive. *)

val archive : block impl -> kv_ro impl
  [@@ocaml.deprecated "use Mirage.tar_kv_ro"]
(** @deprecated You should use {!val:tar_kv_ro} (or {!val:tar_kv_rw}). *)

val direct_kv_ro : string -> kv_ro impl
(** Direct access to the underlying filesystem as a key/value store for Unix.
    For other backends, this is equivalent to [crunch]. *)

val fat_ro : block impl -> kv_ro impl
(** Use a FAT formatted block device. *)

val generic_kv_ro :
  ?group:string -> ?key:[ `Crunch | `Direct ] value -> string -> kv_ro impl
(** Generic key/value that will choose dynamically between {!direct_kv_ro} and
    {!crunch}. To use a filesystem implementation, try {!kv_ro_of_fs}.

    If no key is provided, it uses {!Key.kv_ro} to create a new one. *)

val docteur :
  ?mode:[ `Fast | `Light ] ->
  ?disk:string Key.key ->
  ?analyze:bool Key.key ->
  ?branch:string ->
  ?extra_deps:string list ->
  string ->
  kv_ro impl
(** [docteur ?mode ?disk ?analyze remote] is a read-only, key-value store
    device. Data is stored on that device using the Git PACK file format,
    version 2. This format has very good compression factors for many similar
    files of relatively small size. For instance, 14Gb of HTML files can be
    compressed into a disk image of 240Mb.

    Unlike {!crunch}, [docteur] produces an external image which means that less
    memory is used to keep and get files. The image can be produced from many
    sources:

    - A local Git repository (like [file://path/to/the/git/repository/])
    - A simple directory (like [file://path/to/a/simple/directory/])
    - A remote Git repository (via SSH, HTTP(S) or TCP/IP as what [git clone]
      expects)

    If you use a Git repository, you can choose a specific branch with the
    [?branch] argument (like [refs/heads/main]). Otherwise, this argument is
    ignored.

    If you use a simple directory, it can be a relative from your unikernel
    project ([relativize://directory]) or an absolute path
    ([file://home/user/directory]).

    If a required file is produced by a [dune] rule, you must notice it via the
    [extra_deps] argument.

    For a Solo5 target, users must {i attach} the image as a block device:

    {[
      $ solo5-hvt --block:<name>=<path-to-the-image> -- unikernel.{hvt,...}
    ]}

    For the Unix target, the program [open] the image at the beginning of the
    process. An integrity check of the image can be done via the [analyze] value
    (defaults to [true]).

    It's possible to use the file-system into 2 modes:

    - [`Light]: any access requires that we reconstruct the path to the
      requested file. That means that we will need to extract a few additional
      objects before the extraction of the requested one. [`Light] does not
      cache anything in memory but it can be slower if the requested file is
      deep in the directory structure.
    - [`Fast]: reconstructs and cache the layout of the directory structure when
      the unikernel starts: it might increase boot-time and bigger memory
      requirements. However, [`Fast] allows the device to decode only the
      requested object so it is faster than the [`Light] mode. *)

type kv_rw
(** Abstract type for read-write key/value store. *)

val kv_rw : kv_rw typ
(** Implementations of the [Mirage_kv.RW] signature. *)

val direct_kv_rw : string -> kv_rw impl
(** Direct access to the underlying filesystem as a key/value store. Only
    available on Unix backends. *)

val kv_rw_mem : ?clock:pclock impl -> unit -> kv_rw impl
(** An in-memory key-value store using [mirage-kv-mem]. *)

val chamelon :
  program_block_size:int key -> ?pclock:pclock impl -> block impl -> kv_rw impl
(** [chamelon ~program_block_size] returns a {!kv_rw} filesystem which is an
    implementation of {{:https://github.com/littlefs-project/littlefs} littlefs}
    in OCaml. The [chamelon] device expects a {i block-device}:

    {[
      let program_block_size =
        let doc = Key.Arg.info [ "program-block-size" ] in
        Key.(create "program_block_size" Arg.(opt int 16 doc))

      let block = block_of_file "db"
      let fs = chamelon ~program_block_size block
    ]}

    For Solo5 targets, you finally can launch the unikernel with:

    {[
      $ solo5-hvt --block:db=db.img unikernel.hvt
    ]}

    The block-device must be well-formed and {i formatted} by the [chamelon]
    tool:

    {[
      $ dd if=/dev/zero of=db.img bs=1M count=1
      $ chamelon format db.img 512
    ]} *)

val tar_kv_rw : ?pclock:pclock impl -> block impl -> kv_rw impl
(** [tar_kv_rw block] is a read/write tar archive. Note that the filesystem is
    append-only. That is, files can generally not be removed, [set_partial] only
    works on what is allocated, and there are restrictions on [rename]. *)

val ccm_block : ?nonce_len:int -> string option key -> block impl -> block impl
(** [ccm_block key block] returns a new block which is a AES-CCM encrypted disk.

    {b Note} also that the available size of an encrypted block is always
    divided by 2 of its real size: a 512M block will only be able to contain
    256M data if it is encrypted.

    You can either use a fresh block device as encrypted storage. This does not
    need any preparation, just using [ccm_block] with the desired [key]. If you
    have an existing disk image that you want to encrypt, you can use the
    [ccmblock] tool given by the [mirage-block-ccm] opam package.

    {[
      $ ccmblock enc -i db.img -k 0x10786d3a9c920d0b3ec80dfaaac557a7 -o edb.img
    ]}

    Then, into you [config.ml], you just need to compose your block device with
    [ccm_block]:

    {[
      let aes_ccm_key =
        let doc =
          Key.Arg.info [ "aes-ccm-key" ]
            ~doc:"The key of the block device (hex formatted)"
        in
        Key.(create "aes-ccm-key" Arg.(required string doc))

      let block = block_of_file "edb"
      let encrypted_block = ccm_block aes_ccm_key block
    ]}

    Finally, with Solo5, you can launch your unikernel with that:

    {[
      $ solo5-hvt --block:edb=edb.img \
        --arg="--aes-ccm-key=0x10786d3a9c920d0b3ec80dfaaac557a7" \
        unikernel.hvt
    ]}

    You can finally compose a file-system such as {!chamelon} with this block
    device (and you have a encrypted file-system!):

    {[
      let fs = chamelon ~program_block_size encrypted_block
    ]} *)

(** {2 Network interfaces} *)

type network
(** Abstract type for network configurations. *)

val network : network typ
(** Implementations of the [Mirage_net.S] signature. *)

val default_network : network impl
(** [default_network] is a dynamic network implementation which attempts to do
    something reasonable based on the target. *)

val netif : ?group:string -> string -> network impl
(** A custom network interface. Exposes a {!Key.interface} key. *)

(** {2 Ethernet configuration} *)

type ethernet

val ethernet : ethernet typ
(** Implementations of the [Ethernet.S] signature. *)

val etif : network impl -> ethernet impl

(** {2 ARP configuration} *)

type arpv4

val arpv4 : arpv4 typ
(** Implementation of the [Arp.S] signature. *)

val arp : ?time:time impl -> ethernet impl -> arpv4 impl
(** ARP implementation provided by the arp library *)

(** {2 IP configuration}

    Implementations of the [Tcpip.Ip.S] signature. *)

type v4
type v6
type v4v6

type 'a ip
(** Abstract type for IP configurations. *)

type ipv4 = v4 ip
type ipv6 = v6 ip
type ipv4v6 = v4v6 ip

val ipv4 : ipv4 typ
(** The [Tcpip.Ip.S] module signature with ipaddr = Ipaddr.V4. *)

val ipv6 : ipv6 typ
(** The [Tcpip.Ip.S] module signature with ipaddr = Ipaddr.V6. *)

val ipv4v6 : ipv4v6 typ
(** The [Tcpip.Ip.S] module signature with ipaddr = Ipaddr.t. *)

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
type udpv4v6 = v4v6 udp

val udp : 'a udp typ
(** Implementation of the [Tcpip.Udp.S] signature. *)

val udpv4v6 : udpv4v6 typ
val direct_udp : ?random:random impl -> 'a ip impl -> 'a udp impl

val socket_udpv4v6 :
  ?group:string -> Ipaddr.V4.t option -> Ipaddr.V6.t option -> udpv4v6 impl

(** {2 TCP configuration} *)

type 'a tcp
type tcpv4v6 = v4v6 tcp

val tcp : 'a tcp typ
(** Implementation of the [Tcpip.Tcp.S] signature. *)

val tcpv4v6 : tcpv4v6 typ

val direct_tcp :
  ?mclock:mclock impl ->
  ?time:time impl ->
  ?random:random impl ->
  'a ip impl ->
  'a tcp impl

val socket_tcpv4v6 :
  ?group:string -> Ipaddr.V4.t option -> Ipaddr.V6.t option -> tcpv4v6 impl

(** {2 Network stack configuration} *)

(** {3 Dual IPv4 and IPv6} *)

type stackv4v6

val stackv4v6 : stackv4v6 typ
(** Implementation of the [Tcpip.Stack.V4V6] signature. *)

val direct_stackv4v6 :
  ?mclock:mclock impl ->
  ?random:random impl ->
  ?time:time impl ->
  ?tcp:tcpv4v6 impl ->
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

val tcpv4v6_of_stackv4v6 : stackv4v6 impl -> tcpv4v6 impl
(** [tcpv4v6 stackv4v6] is an helper to extract the TCP/IP stack regardless the
    UDP/IP stack expected by some {i devices} such as protocols. *)

(** {2 Resolver configuration} *)

type resolver

val resolver : resolver typ

val resolver_dns :
  ?ns:string list ->
  ?time:time impl ->
  ?mclock:mclock impl ->
  ?pclock:pclock impl ->
  ?random:random impl ->
  stackv4v6 impl ->
  resolver impl

val resolver_unix_system : resolver impl

(** {2 DNS client} *)

(** A DNS client is a module which implements:

    - [getaddrinfo] to request a [query_type]-dependent response to a nameserver
      regarding a domain-name such as the [MX] record.
    - [gethostbyname] to request the [A] regarding a domain-name
    - [gethostbyname6] to request the [AAAA] record regarding a domain-name *)

type dns_client

val dns_client : dns_client typ

val generic_dns_client :
  ?timeout:int64 option key ->
  ?nameservers:string list key ->
  ?random:random impl ->
  ?time:time impl ->
  ?mclock:mclock impl ->
  ?pclock:pclock impl ->
  stackv4v6 impl ->
  dns_client impl
(** [generic_dns_client stackv4v6] creates a new DNS value which is able to
    resolve domain-name from [nameservers]. It requires a network stack to
    communicate with these nameservers.

    The [nameservers] argument is a list of strings. The format of them is:

    - [udp:ipaddr(:port)?] if you want to communicate with a DNS resolver
      {i via} UDP
    - [tcp:ipaddr(:port)?] if you want to communicate with a DNS resolver
      {i via} TCP/IP
    - [tls:ipaddr(:port)?(!<authenticator>)] if you to communicate with a DNS
      resolver {i via} TLS. You are able to introduce an [<authenticator>]
      (please, follow the documentation about [X509.Authenticator.of_string] to
      get an explanation of its format). Otherwise, by default, we use trust
      anchors from NSS' [certdata.txt]. *)

(** {2 Happy-eyeballs} *)

(** Happy-eyeballs is an implementation of RFC 8305 which specifies how to
    connect to a remote host using either IP protocol version 4 or IP protocol
    version 6 from a [stackv4v6] network implementation.

    The given {i device} is able to resolve a remote host {i via} a
    {!dns_client} device and both must share the same [stackv4v6]
    implementation. *)

type happy_eyeballs

val happy_eyeballs : happy_eyeballs typ

val generic_happy_eyeballs :
  ?aaaa_timeout:int64 option key ->
  ?connect_delay:int64 option key ->
  ?connect_timeout:int64 option key ->
  ?resolve_timeout:int64 option key ->
  ?resolve_retries:int64 option key ->
  ?timer_interval:int64 option key ->
  ?time:time impl ->
  ?mclock:mclock impl ->
  stackv4v6 impl ->
  dns_client impl ->
  happy_eyeballs impl
(** [generic_happy_eyeballs stackv4v6 dns_client] creates a new happy-eyeballs
    value which is able to resolve and connect to a remote host and allocate
    finally a connected {i flow} from the given network implementation
    [stackv4v6].

    This device has several optional arguments of keys for timeouts specified in
    nanoseconds. *)

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
(** Helper for constructing a {!type:syslog_config}. *)

type syslog
(** The type for syslog *)

val syslog : syslog typ
(** Implementation of the {!type:syslog} type. *)

val syslog_udp :
  ?config:syslog_config -> ?clock:pclock impl -> stackv4v6 impl -> syslog impl
(** Emit log messages via UDP to the configured host. *)

val syslog_tcp :
  ?config:syslog_config -> ?clock:pclock impl -> stackv4v6 impl -> syslog impl
(** Emit log messages via TCP to the configured host. *)

val syslog_tls :
  ?config:syslog_config ->
  ?keyname:string ->
  ?clock:pclock impl ->
  stackv4v6 impl ->
  kv_ro impl ->
  syslog impl
(** Emit log messages via TLS to the configured host, using the credentials
    (private key, certificate, trust anchor) provided in the KV_RO using the
    [keyname]. *)

(** {2 Conduit configuration} *)

type conduit

val conduit : conduit typ

val conduit_direct :
  ?tls:bool -> ?random:random impl -> stackv4v6 impl -> conduit impl

(** {2 Mimic devices}

    For some implementations which requires to communicate with an external
    resources (such as a webserver or a git server), we must hide the underlying
    implementations that depend on the {i target} (such as the network stack)
    and are necessary for these implementations.

    The aim of [mimic] is to offer first of all the ability to initiate a TCP/IP
    connection independently of the chosen {i target} (see
    {!val:mimic_happy_eyeballs}).

    The resulting {i device} can then be composed with other protocols like TLS,
    Git or HTTP and it is through this resulting {i device} that other devices
    can initiate an internet connection to a peer (like a webserver or a Git
    server). *)

type mimic

val mimic : mimic typ

val mimic_happy_eyeballs :
  stackv4v6 impl -> dns_client impl -> happy_eyeballs impl -> mimic impl
(** [mimic_happy_eyeballs stackv4v6 dns happy_eyeballs] creates a device which
    initiate a global {i happy-eyeballs} loop. By this way, an underlying
    instance works to initiate a TCP/IP connection from an IP address or a
    domain-name.

    For the domain-name resolution, we ask the {i happy-eyeballs} instance to
    resolve the given domain-name {i via} the DNS instance created by [dns]
    (which includes several arguments like nameservers used - see
    {!val:generic_dns_client} for more informations).

    The resulting {i device} can be used {b and} re-used to for any {i clients}
    which need to initiate a connection (like {!val:alpn_client} or
    {!val:git_tcp}). *)

(** {2 HTTP configuration} *)

type http

val http : http typ

val cohttp_server : conduit impl -> http impl
(** [cohttp_server] starts a Cohttp server. *)

val httpaf_server : conduit impl -> http impl
(** [httpaf_server] starts a http/af server. *)

type http_client

val http_client : http_client typ

val cohttp_client :
  ?pclock:pclock impl -> resolver impl -> conduit impl -> http_client impl
(** [cohttp_server] starts a Cohttp server. *)

type http_server

val http_server : http_server typ

val paf_server : port:int key -> tcpv4v6 impl -> http_server impl
(** [paf_server ~port tcpv4v6] creates an instance which will start to
    {i listen} on the given [port]. With this instance and the produced module
    [HTTP_server], the user can initiate:

    - a simple HTTP server
    - a simple HTTPS server (with a TLS configuration)
    - a simple ALPN ([http/1.1] & [h2]) server with TLS

    This is a simple example of how to launch an HTTP server: {b unikernel.ml}

    {[
      module Make (HTTP_server : Paf_mirage.S with type ipaddr = Ipaddr.t) =
      struct
        let error_handler (_ipaddr, _port) ?request:_ _error _send = ()

        let request_handler :
            HTTP_server.TCP.flow -> Ipaddr.t * int -> Httpaf.Reqd.t -> unit =
         fun _socket (_ipaddr, _port) reqd ->
          let contents = "Hello World!\n" in
          let headers =
            Httpaf.Headers.of_list
              [
                ("content-length", string_of_int (String.length contents));
                ("content-type", "text/plain");
                ("connection", "close");
              ]
          in
          let response = Httpaf.Response.create ~headers `OK in
          Httpaf.Reqd.respond_with_string reqd response contents

        let start http_server =
          let service =
            HTTP_service.http_service ~error_handler request_handler
          in
          let (`Initialized thread) = HTTP_server.serve service http_server in
          thread
      end
    ]}

    {b config.ml}

    {[
      open Mirage

      let port =
        let doc =
          Key.Arg.info ~doc:"Port of the HTTP service." [ "p"; "port" ]
        in
        Key.(create "port" Arg.(opt int 8080 doc))

      let main = foreign "Unikernel.Make" (http_server @-> job)
      let stackv4v6 = generic_stackv4v6 default_network
      let http_server = paf_server ~port (tcpv4v6_of_stackv4v6 stackv4v6)
      let () = register "main" [ main $ http_server ]
    ]} *)

type alpn_client
(** Abstract type for ALPN HTTP clients *)

val alpn_client : alpn_client typ

val paf_client :
  ?pclock:pclock impl -> tcpv4v6 impl -> mimic impl -> alpn_client impl
(** [paf_client tcpv4v6 dns] creates an ALPN device which can do HTTP
    ([http/1.1] & [h2]) requests as a HTTP client. The device allocated
    represents values required to initiate a connection to HTTP webservers. The
    user can, then, use the module [Http_mirage_client.request] to communicate
    with HTTP webservers. This is an example of how to use the ALPN devices:

    {b unikernel.ml}

    {[
      module Make (HTTP_client : Http_mirage_client.S) = struct
        let start http =
          Http_mirage_client.request http "https://google.com"
            (fun _response buf str -> Buffer.add_string buf str ; Lwt.return buf)
            (Buffer.create 0x100) >>= function
          | Ok (response, buf) ->
            let body = Buffer.contents buf in
            ...
          | Error _ -> ...
      end
    ]}

    {b config.ml}

    {[
      open Mirage

      let main = foreign "Unikernel.Make" (alpn_client @-> job)
      let stackv4v6 = generic_stackv4v6 default_network
      let dns = generic_dns_client stack

      let alpn_client =
        let dns =
          mimic_happy_eyeballs stackv4v6 dns (generic_happy_eyeballs stack dns)
        in
        paf_client (tcpv4v6_of_stackv4v6 stackv4v6) dns

      let () = register "main" [ main $ alpn_client ]
    ]} *)

(** {2 Argv configuration} *)

type argv = Functoria.argv

val argv : argv typ

val default_argv : argv impl
(** [default_argv] is a dynamic argv implementation which attempts to do
    something reasonable based on the target. *)

val no_argv : argv impl
(** [no_argv] Disable command line parsing and set argv to [|""|]. *)

(** {2 Git client configuration} *)

(** Users can connect to a remote Git repository in many ways:

    - TCP/IP
    - HTTP
    - HTTP + TLS
    - SSH

    The devices defined below define these in composable ways. The
    [git_client impl] returned from them can be passed to Git or Irmin in order
    to be able to {i fetch} and {i push} from/into a Git repository.

    The user is able to restrict or enlarge protocol possibilities needed for
    its application. For instance, the user is able to restrict only the SSH
    connection to communicate with a Git repository or the user can handle
    TCP/IP and SSH as possible protocols to communicate with a peer.

    For instance, a device which is able to communicate {i via} TCP/IP and SSH
    can be implemented like:

    {[
      let dns = generic_dns_client stack

      let git_client =
        let dns =
          mimic_happy_eyeballs stackv4v6 dns (generic_happy_eyeballs stack dns)
        in
        let ssh = git_ssh ~key ~password (tcpv4v6_of_stackv4v6 stackv4v6) dns in
        let tcp = git_tcp (tcpv4v6_of_stackv4v6 stackv4v6) dns in
        merge_git_clients ssh tcp
    ]} *)

type git_client
(** The type for devices that implement the Git protocol. *)

val git_client : git_client typ

val merge_git_clients : git_client impl -> git_client impl -> git_client impl
(** [merge_git_clients a b] is a device that can connect to remote Git
    repositories using either the device [a] or the device [b]. *)

val git_tcp : tcpv4v6 impl -> mimic impl -> git_client impl
(** [git_tcp tcpv4v6 dns] is a device able to connect to a remote Git repository
    using TCP/IP. *)

val git_ssh :
  ?authenticator:string option key ->
  key:string option key ->
  password:string option key ->
  ?mclock:mclock impl ->
  ?time:time impl ->
  tcpv4v6 impl ->
  mimic impl ->
  git_client impl
(** [git_ssh ?authenticator ~key ~password tcpv4v6 dns] is a device able to
    connect to a remote Git repository using an SSH connection with the given
    private [key] or [password]. The identity of the remote Git repository can
    be verified using [authenticator].

    The format of the private key is: [<type>:<seed or b64 encoded>]. [<type>]
    can be [rsa] or [ed25519] and, if the type is RSA, we expect the {b seed} of
    the private key. Otherwise (if the type is Ed25519), we expect the
    b64-encoded private key.

    The format of the authenticator is [SHA256:<b64-encoded-public-key>], the
    output of:

    {[
      $ ssh-keygen -lf <(ssh-keyscan -t rsa|ed25519 remote 2>/dev/null)
    ]} *)

val git_http :
  ?authenticator:string option key ->
  ?headers:(string * string) list key ->
  ?pclock:pclock impl ->
  tcpv4v6 impl ->
  mimic impl ->
  git_client impl
(** [git_http ?authenticator ?headers tcpv4v6 dns] is a device able to connect
    to a remote Git repository via an HTTP(S) connection, using the provided
    HTTP [headers]. The identity of the remote Git repository can be verified
    using [authenticator].

    The format of it is:

    - [none] no authentication
    - key(:<hash>)?:<b64-encoded fingerprint> to authenticate via the key
      fingerprint
    - cert(:<hash>)?:<b64-encoded fingerprint> to authenticate via the cert
      fingerprint
    - trust-anchor(:<der-encoded cert>)+ to authenticate via a list of
      certificates - By default, we use X.509 trust anchors extracted from
      Mozilla's NSS *)

(** {2 Other devices} *)

val job : job typ
(** [job] is the combinator for representing main tasks. *)

val noop : job impl
(** [noop] is a job that does nothing, has no dependency and returns [()] *)

val keys : argv impl -> job impl
(** [keys argv] is a job that loads argv. *)

type info
(** [info] is the type for module implementing {!Mirage_runtime.Info}. *)

val info : info typ
(** [info] is the combinator to generate {!type:info} values to use at runtime. *)

val app_info : info impl
(** [app_info] exports all the information available at configure time into a
    runtime {!type:Mirage.Info.t} value. *)

val app_info_with_opam_deps : (string * string) list -> info impl
(** [app_info_with_opam_deps build_info] exports all the information available
    at configure time into a runtime {!type:Mirage.Info.t} value. The libraries
    are set to [build_info]. Most likely you want to use [app_info] instead. *)

(** {2 Application registering} *)

val register :
  ?argv:argv impl ->
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

module Project : sig
  val dune : Info.t -> Dune.stanza list
  val configure : Info.t -> unit Action.t
end

module Tool : sig
  val run : unit -> unit
end
