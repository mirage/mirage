(*
 * Copyright (c) 2013 Thomas Gazagnaire <thomas@gazagnaire.org>
 * Copyright (c) 2013 Anil Madhavapeddy <anil@recoil.org>
 * Copyright (c) 2018 Mindy Preston     <meetup@yomimono.org>
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

open Functoria
open Devices
module Type = Type
module Impl = Functoria.Impl
module Info = Info
module Dune = Dune
module Context = Context
module Key = Devices.Key
module Runtime_arg = Devices.Runtime_arg
include Functoria.DSL

(** {2 OCamlfind predicates} *)

(** {2 Devices} *)

type qubesdb = Qubesdb.qubesdb

let qubesdb = Qubesdb.qubesdb
let default_qubesdb = Qubesdb.default_qubesdb

type time = Time.time

let time = Time.time
let default_time = Time.default_time

type pclock = Pclock.pclock

let pclock = Pclock.pclock
let default_posix_clock = Pclock.default_posix_clock

type mclock = Mclock.mclock

let mclock = Mclock.mclock
let default_monotonic_clock = Mclock.default_monotonic_clock

type random = Random.random

let random = Random.random
let default_random = Random.default_random
let rng = Random.rng

type kv_ro = Kv.ro

let kv_ro = Kv.ro
let direct_kv_ro = Kv.direct_kv_ro
let crunch = Kv.crunch
let generic_kv_ro = Kv.generic_kv_ro

type kv_rw = Kv.rw

let kv_rw = Kv.rw
let direct_kv_rw = Kv.direct_kv_rw
let kv_rw_mem = Kv.mem_kv_rw

let docteur ?mode ?name ?output ?analyze ?branch ?extra_deps remote =
  Block.docteur ?mode ?name ?output ?analyze ?branch ?extra_deps remote

let chamelon ~program_block_size ?(pclock = default_posix_clock) block =
  Block.chamelon ~program_block_size $ block $ pclock

let tar_kv_rw ?(pclock = default_posix_clock) block =
  Block.tar_kv_rw pclock block

type block = Block.block

let block = Block.block
let tar_kv_ro = Block.tar_kv_ro
let fat_ro = Block.fat_ro
let generic_block = Block.generic_block
let ramdisk = Block.ramdisk
let block_of_xenstore_id = Block.block_of_xenstore_id
let block_of_file = Block.block_of_file
let ccm_block ?nonce_len key block = Block.ccm_block ?nonce_len key $ block

type network = Network.network

let network = Network.network
let netif = Network.netif
let default_network = Network.default_network

type ethernet = Ethernet.ethernet

let ethernet = Ethernet.ethernet
let etif = Ethernet.ethif
let ethif = Ethernet.ethif

type arpv4 = Arp.arpv4

let arpv4 = Arp.arpv4
let arp = Arp.arp

type v4 = Ip.v4
type v6 = Ip.v6
type v4v6 = Ip.v4v6
type 'a ip = 'a Ip.ip
type ipv4 = Ip.ipv4
type ipv6 = Ip.ipv6
type ipv4v6 = Ip.ipv4v6

let ipv4 = Ip.ipv4
let ipv6 = Ip.ipv6
let ipv4_qubes = Ip.ipv4_qubes
let ipv4v6 = Ip.ipv4v6
let create_ipv4 = Ip.create_ipv4
let create_ipv6 = Ip.create_ipv6
let create_ipv4v6 = Ip.create_ipv4v6

type ipv4_config = Ip.ipv4_config = {
  network : Ipaddr.V4.Prefix.t;
  gateway : Ipaddr.V4.t option;
}

type ipv6_config = Ip.ipv6_config = {
  network : Ipaddr.V6.Prefix.t;
  gateway : Ipaddr.V6.t option;
}

type 'a udp = 'a Udp.udp

let udp = Udp.udp

type udpv4v6 = Udp.udpv4v6

let udpv4v6 = Udp.udpv4v6
let direct_udp = Udp.direct_udp
let socket_udpv4v6 = Udp.socket_udpv4v6

type 'a tcp = 'a Tcp.tcp

let tcp = Tcp.tcp

type tcpv4v6 = Tcp.tcpv4v6

let tcpv4v6 = Tcp.tcpv4v6
let direct_tcp = Tcp.direct_tcp
let socket_tcpv4v6 = Tcp.socket_tcpv4v6

type stackv4v6 = Stack.stackv4v6

let stackv4v6 = Stack.stackv4v6
let generic_stackv4v6 = Stack.generic_stackv4v6
let static_ipv4v6_stack = Stack.static_ipv4v6_stack
let direct_stackv4v6 = Stack.direct_stackv4v6
let socket_stackv4v6 = Stack.socket_stackv4v6

let tcpv4v6_of_stackv4v6 v =
  let impl =
    let packages_v =
      Ip.right_tcpip_library ~sublibs:[ "stack-direct" ] "tcpip"
    in
    let connect _ modname = function
      | [ stackv4v6 ] ->
          code ~pos:__POS__ {ocaml|%s.connect %s|ocaml} modname stackv4v6
      | _ -> Misc.connect_err "tcpv4v6_of_stackv4v6" 1
    in
    impl ~packages_v ~connect "Tcpip_stack_direct.TCPV4V6"
      (stackv4v6 @-> tcpv4v6)
  in
  impl $ v

type conduit = Conduit.conduit

let conduit = Conduit.conduit
let conduit_direct = Conduit.conduit_direct

type resolver = Resolver.resolver

let resolver = Resolver.resolver
let resolver_unix_system = Resolver.resolver_unix_system
let resolver_dns = Resolver.resolver_dns

type happy_eyeballs = Happy_eyeballs.happy_eyeballs

let happy_eyeballs = Happy_eyeballs.happy_eyeballs

let generic_happy_eyeballs ?group ?aaaa_timeout ?connect_delay ?connect_timeout
    ?resolve_timeout ?resolve_retries ?timer_interval ?(time = default_time)
    ?(mclock = default_monotonic_clock) stackv4v6 =
  Happy_eyeballs.generic_happy_eyeballs ?group ?aaaa_timeout ?connect_delay
    ?connect_timeout ?resolve_timeout ?resolve_retries ?timer_interval ()
  $ time
  $ mclock
  $ stackv4v6

type dns_client = Dns.dns_client

let dns_client = Dns.dns_client

let generic_dns_client ?group ?timeout ?nameservers ?cache_size
    ?(random = default_random) ?(time = default_time)
    ?(mclock = default_monotonic_clock) ?(pclock = default_posix_clock)
    stackv4v6 happy_eyeballs =
  Dns.generic_dns_client ?group ?timeout ?nameservers ?cache_size ()
  $ random
  $ time
  $ mclock
  $ pclock
  $ stackv4v6
  $ happy_eyeballs

type syslog = Syslog.syslog

let syslog = Syslog.syslog
let syslog_tls = Syslog.syslog_tls
let syslog_tcp = Syslog.syslog_tcp
let syslog_udp = Syslog.syslog_udp

type syslog_config = Syslog.syslog_config = {
  hostname : string;
  server : Ipaddr.t option;
  port : int option;
  truncate : int option;
}

let syslog_config = Syslog.syslog_config

type http = Http.http

let http = Http.http
let cohttp_server = Http.cohttp_server
let httpaf_server = Http.httpaf_server

type http_client = Http.http_client

let http_client = Http.http_client
let cohttp_client = Http.cohttp_client

type http_server = Http.http_server

let http_server = Http.http_server
let paf_server ~port tcpv4v6 = Http.paf_server port $ tcpv4v6

type alpn_client = Http.alpn_client

let alpn_client = Http.alpn_client

let paf_client ?(pclock = default_posix_clock) tcpv4v6 mimic =
  Http.paf_client $ pclock $ tcpv4v6 $ mimic

type argv = Functoria.argv

let argv = Functoria.argv
let default_argv = Argv.default_argv
let no_argv = Argv.no_argv

type reporter = Reporter.reporter

let reporter = Reporter.reporter
let default_reporter = Reporter.default_reporter
let no_reporter = Reporter.no_reporter

type mimic = Mimic.mimic

let mimic = Mimic.mimic

let mimic_happy_eyeballs stackv4v6 happy_eyeballs dns =
  Mimic.mimic_happy_eyeballs $ stackv4v6 $ happy_eyeballs $ dns

type git_client = Git.git_client

let git_client = Git.git_client
let merge_git_clients ctx0 ctx1 = Git.git_merge_clients $ ctx0 $ ctx1
let git_tcp tcpv4v6 ctx = Git.git_tcp $ tcpv4v6 $ ctx

let git_ssh ?group ?authenticator ?key ?password
    ?(mclock = default_monotonic_clock) ?(time = default_time) tcpv4v6 ctx =
  Git.git_ssh ?group ?authenticator ?key ?password ()
  $ mclock
  $ tcpv4v6
  $ time
  $ ctx

let git_http ?group ?authenticator ?headers ?(pclock = default_posix_clock)
    tcpv4v6 ctx =
  Git.git_http ?group ?authenticator ?headers () $ pclock $ tcpv4v6 $ ctx

let delay = job

let delay_startup =
  let delay_key = Runtime_arg.delay in
  let runtime_args = [ Runtime_arg.v delay_key ] in
  let packages = [ package ~max:"1.0.0" "duration" ] in
  let connect i _ = function
    | [ delay_key ] ->
        let modname =
          match Misc.get_target i with
          | `Unix | `MacOSX -> "Unix_os.Time"
          | `Xen | `Qubes -> "Xen_os.Time"
          | `Virtio | `Hvt | `Spt | `Muen | `Genode -> "Solo5_os.Time"
        in
        code ~pos:__POS__ "%s.sleep_ns (Duration.of_sec %s)" modname delay_key
    | _ -> Misc.connect_err "delay_startup" 1
  in
  impl ~packages ~runtime_args ~connect "Mirage_runtime" delay

(** Functoria devices *)

type info = Functoria.info

let job = Functoria.job
let noop = Functoria.noop

let os_of_target i =
  match Info.get i Key.target with
  | #Key.mode_solo5 -> "Solo5_os"
  | #Key.mode_unix -> "Unix_os"
  | #Key.mode_xen -> "Xen_os"

module Project = struct
  let name = "mirage"
  let version = "%%VERSION%%"

  let prelude info =
    Fmt.str
      {ocaml|open Lwt.Infix
type 'a io = 'a Lwt.t
let return = Lwt.return
let run t = %s.Main.run t ; exit 0|ocaml}
      (os_of_target info)

  (* The ocamlfind packages to use when compiling config.ml *)
  let packages = [ package "mirage" ]

  let name_of_target i =
    match Info.output i with
    | Some o -> o
    | None ->
        let name = Info.name i in
        let target = Info.get i Key.target in
        Fmt.str "%s-%a" name Key.pp_target target

  let dune i = Target.dune i
  let configure i = Target.configure i

  let dune_project =
    [ Dune.stanza {|
    (implicit_transitive_deps true)
    |} ]

  let dune_workspace =
    let f ?build_dir i =
      let stanzas = Target.build_context ?build_dir i in
      let main =
        Dune.stanza {|
(lang dune 2.9)

(context (default))
        |}
      in
      Dune.v (main :: stanzas)
    in
    Some f

  let context_name i = Target.context_name i

  let create jobs =
    let keys = Key.[ v target ] in
    let packages_v =
      (* XXX: use %%VERSION_NUM%% here instead of hardcoding a version? *)
      let min = "4.8.0" and max = "4.9.0" in
      let common =
        [
          package ~scope:`Monorepo "lwt";
          package ~scope:`Monorepo ~min ~max "mirage-runtime";
          package ~scope:`Switch ~build:true ~min ~max "mirage";
          package ~scope:`Switch ~build:true ~min:"0.3.2" "opam-monorepo";
        ]
      in
      Key.match_ Key.(value target) @@ fun target ->
      Target.packages target @ common
    in
    let install = Target.install in
    let extra_deps = List.map dep jobs in
    let connect _ _ _ = code ~pos:__POS__ "return ()" in
    impl ~keys ~packages_v ~configure ~dune ~connect ~extra_deps ~install
      "Mirage_runtime" job
end

include Lib.Make (Project)
module Tool = Tool.Make (Project)

(** Custom registration *)

let runtime_args argv =
  Functoria.runtime_args ~runtime_package:(package "mirage-runtime")
    ~runtime_modname:"Mirage_runtime" argv

let ocaml_runtime =
  let packages = [ package ~min:"1.0.1" ~max:"2.0.0" "cmdliner-stdlib" ] in
  let runtime_args =
    [
      Runtime_arg.v
        (Runtime_arg.create ~pos:__POS__
           "Cmdliner_stdlib.setup ~backtrace:(Some true) \
            ~randomize_hashtables:(Some true) ()");
    ]
  in
  impl ~packages ~runtime_args "Cmdliner_stdlib" job

let ( ++ ) acc x =
  match (acc, x) with
  | _, None -> acc
  | None, Some x -> Some [ x ]
  | Some acc, Some x -> Some (acc @ [ x ])

let register ?(argv = default_argv) ?(reporter = default_reporter ()) ?src name
    jobs =
  if List.exists Functoria.Impl.app_has_no_arguments jobs then
    invalid_arg
      "Your configuration includes a job without arguments. Please add a \
       dependency in your config.ml: use `let main = Mirage.main \
       \"Unikernel.hello\" (job @-> job) register \"hello\" [ main $ noop ]` \
       instead of `.. job .. [ main ]`.";
  let first = [ runtime_args argv; ocaml_runtime ] in
  let reporter = if reporter == no_reporter then None else Some reporter in
  let init = Some first ++ Some delay_startup ++ reporter in
  register ?init ?src name jobs

let connect_err = Devices.Misc.connect_err

module Action = Functoria.Action
