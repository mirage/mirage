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
module Type = Type
module Impl = Impl
module Info = Info
module Dune = Dune
module Key = Mirage_key
module Runtime_arg = Mirage_runtime_arg
module Context = Context
include Functoria.DSL

(** {2 OCamlfind predicates} *)

(** {2 Devices} *)

type qubesdb = Mirage_impl_qubesdb.qubesdb

let qubesdb = Mirage_impl_qubesdb.qubesdb
let default_qubesdb = Mirage_impl_qubesdb.default_qubesdb

type time = Mirage_impl_time.time

let time = Mirage_impl_time.time
let default_time = Mirage_impl_time.default_time

type pclock = Mirage_impl_pclock.pclock

let pclock = Mirage_impl_pclock.pclock
let default_posix_clock = Mirage_impl_pclock.default_posix_clock

type mclock = Mirage_impl_mclock.mclock

let mclock = Mirage_impl_mclock.mclock
let default_monotonic_clock = Mirage_impl_mclock.default_monotonic_clock

type random = Mirage_impl_random.random

let random = Mirage_impl_random.random
let default_random = Mirage_impl_random.default_random
let rng = Mirage_impl_random.rng

type kv_ro = Mirage_impl_kv.ro

let kv_ro = Mirage_impl_kv.ro
let direct_kv_ro = Mirage_impl_kv.direct_kv_ro
let crunch = Mirage_impl_kv.crunch
let generic_kv_ro = Mirage_impl_kv.generic_kv_ro

type kv_rw = Mirage_impl_kv.rw

let kv_rw = Mirage_impl_kv.rw
let direct_kv_rw = Mirage_impl_kv.direct_kv_rw
let kv_rw_mem = Mirage_impl_kv.mem_kv_rw

let docteur ?mode ?name ?output ?analyze ?branch ?extra_deps remote =
  Mirage_impl_block.docteur ?mode ?name ?output ?analyze ?branch ?extra_deps
    remote

let chamelon ~program_block_size ?(pclock = default_posix_clock) block =
  Mirage_impl_block.chamelon ~program_block_size $ block $ pclock

let tar_kv_rw ?(pclock = default_posix_clock) block =
  Mirage_impl_block.tar_kv_rw pclock block

type block = Mirage_impl_block.block

let block = Mirage_impl_block.block
let tar_kv_ro = Mirage_impl_block.tar_kv_ro
let fat_ro = Mirage_impl_block.fat_ro
let generic_block = Mirage_impl_block.generic_block
let ramdisk = Mirage_impl_block.ramdisk
let block_of_xenstore_id = Mirage_impl_block.block_of_xenstore_id
let block_of_file = Mirage_impl_block.block_of_file

let ccm_block ?nonce_len key block =
  Mirage_impl_block.ccm_block ?nonce_len key $ block

type network = Mirage_impl_network.network

let network = Mirage_impl_network.network
let netif = Mirage_impl_network.netif
let default_network = Mirage_impl_network.default_network

type ethernet = Mirage_impl_ethernet.ethernet

let ethernet = Mirage_impl_ethernet.ethernet
let etif = Mirage_impl_ethernet.etif

type arpv4 = Mirage_impl_arpv4.arpv4

let arpv4 = Mirage_impl_arpv4.arpv4
let arp = Mirage_impl_arpv4.arp

type v4 = Mirage_impl_ip.v4
type v6 = Mirage_impl_ip.v6
type v4v6 = Mirage_impl_ip.v4v6
type 'a ip = 'a Mirage_impl_ip.ip
type ipv4 = Mirage_impl_ip.ipv4
type ipv6 = Mirage_impl_ip.ipv6
type ipv4v6 = Mirage_impl_ip.ipv4v6

let ipv4 = Mirage_impl_ip.ipv4
let ipv6 = Mirage_impl_ip.ipv6
let ipv4_qubes = Mirage_impl_ip.ipv4_qubes
let ipv4v6 = Mirage_impl_ip.ipv4v6
let create_ipv4 = Mirage_impl_ip.create_ipv4
let create_ipv6 = Mirage_impl_ip.create_ipv6
let create_ipv4v6 = Mirage_impl_ip.create_ipv4v6

type ipv4_config = Mirage_impl_ip.ipv4_config = {
  network : Ipaddr.V4.Prefix.t;
  gateway : Ipaddr.V4.t option;
}

type ipv6_config = Mirage_impl_ip.ipv6_config = {
  network : Ipaddr.V6.Prefix.t;
  gateway : Ipaddr.V6.t option;
}

type 'a udp = 'a Mirage_impl_udp.udp

let udp = Mirage_impl_udp.udp

type udpv4v6 = Mirage_impl_udp.udpv4v6

let udpv4v6 = Mirage_impl_udp.udpv4v6
let direct_udp = Mirage_impl_udp.direct_udp
let socket_udpv4v6 = Mirage_impl_udp.socket_udpv4v6

type 'a tcp = 'a Mirage_impl_tcp.tcp

let tcp = Mirage_impl_tcp.tcp

type tcpv4v6 = Mirage_impl_tcp.tcpv4v6

let tcpv4v6 = Mirage_impl_tcp.tcpv4v6
let direct_tcp = Mirage_impl_tcp.direct_tcp
let socket_tcpv4v6 = Mirage_impl_tcp.socket_tcpv4v6

type stackv4v6 = Mirage_impl_stack.stackv4v6

let stackv4v6 = Mirage_impl_stack.stackv4v6
let generic_stackv4v6 = Mirage_impl_stack.generic_stackv4v6
let static_ipv4v6_stack = Mirage_impl_stack.static_ipv4v6_stack
let direct_stackv4v6 = Mirage_impl_stack.direct_stackv4v6
let socket_stackv4v6 = Mirage_impl_stack.socket_stackv4v6

let tcpv4v6_of_stackv4v6 v =
  let impl =
    let packages =
      [ package "tcpip" ~sublibs:[ "stack-direct" ] ~min:"7.1.0" ]
    in
    let connect _ modname = function
      | [ stackv4v6 ] ->
          code ~pos:__POS__ {ocaml|%s.connect %s|ocaml} modname stackv4v6
      | _ -> Mirage_impl_misc.connect_err "tcpv4v6_of_stackv4v6" 1
    in
    impl ~packages ~connect "Tcpip_stack_direct.TCPV4V6" (stackv4v6 @-> tcpv4v6)
  in
  impl $ v

type conduit = Mirage_impl_conduit.conduit

let conduit = Mirage_impl_conduit.conduit
let conduit_direct = Mirage_impl_conduit.conduit_direct

type resolver = Mirage_impl_resolver.resolver

let resolver = Mirage_impl_resolver.resolver
let resolver_unix_system = Mirage_impl_resolver.resolver_unix_system
let resolver_dns = Mirage_impl_resolver.resolver_dns

type dns_client = Mirage_impl_dns.dns_client

let dns_client = Mirage_impl_dns.dns_client

let generic_dns_client ?timeout ?nameservers ?(random = default_random)
    ?(time = default_time) ?(mclock = default_monotonic_clock)
    ?(pclock = default_posix_clock) stackv4v6 =
  Mirage_impl_dns.generic_dns_client timeout nameservers
  $ random
  $ time
  $ mclock
  $ pclock
  $ stackv4v6

type happy_eyeballs = Mirage_impl_happy_eyeballs.happy_eyeballs

let happy_eyeballs = Mirage_impl_happy_eyeballs.happy_eyeballs

let generic_happy_eyeballs ?aaaa_timeout ?connect_delay ?connect_timeout
    ?resolve_timeout ?resolve_retries ?timer_interval ?(time = default_time)
    ?(mclock = default_monotonic_clock) stackv4v6 dns_client =
  Mirage_impl_happy_eyeballs.generic_happy_eyeballs aaaa_timeout connect_delay
    connect_timeout resolve_timeout resolve_retries timer_interval
  $ time
  $ mclock
  $ stackv4v6
  $ dns_client

type syslog = Mirage_impl_syslog.syslog

let syslog = Mirage_impl_syslog.syslog
let syslog_tls = Mirage_impl_syslog.syslog_tls
let syslog_tcp = Mirage_impl_syslog.syslog_tcp
let syslog_udp = Mirage_impl_syslog.syslog_udp

type syslog_config = Mirage_impl_syslog.syslog_config = {
  hostname : string;
  server : Ipaddr.t option;
  port : int option;
  truncate : int option;
}

let syslog_config = Mirage_impl_syslog.syslog_config

type http = Mirage_impl_http.http

let http = Mirage_impl_http.http
let cohttp_server = Mirage_impl_http.cohttp_server
let httpaf_server = Mirage_impl_http.httpaf_server

type http_client = Mirage_impl_http.http_client

let http_client = Mirage_impl_http.http_client
let cohttp_client = Mirage_impl_http.cohttp_client

type http_server = Mirage_impl_http.http_server

let http_server = Mirage_impl_http.http_server
let paf_server ~port tcpv4v6 = Mirage_impl_http.paf_server port $ tcpv4v6

type alpn_client = Mirage_impl_http.alpn_client

let alpn_client = Mirage_impl_http.alpn_client

let paf_client ?(pclock = default_posix_clock) tcpv4v6 mimic =
  Mirage_impl_http.paf_client $ pclock $ tcpv4v6 $ mimic

type argv = Functoria.argv

let argv = Functoria.argv
let default_argv = Mirage_impl_argv.default_argv
let no_argv = Mirage_impl_argv.no_argv

type reporter = Mirage_impl_reporter.reporter

let reporter = Mirage_impl_reporter.reporter
let default_reporter = Mirage_impl_reporter.default_reporter
let no_reporter = Mirage_impl_reporter.no_reporter

type mimic = Mirage_impl_mimic.mimic

let mimic = Mirage_impl_mimic.mimic

let mimic_happy_eyeballs stackv4v6 dns_client happy_eyeballs =
  Mirage_impl_mimic.mimic_happy_eyeballs
  $ stackv4v6
  $ dns_client
  $ happy_eyeballs

type git_client = Mirage_impl_git.git_client

let git_client = Mirage_impl_git.git_client

let merge_git_clients ctx0 ctx1 =
  Mirage_impl_git.git_merge_clients $ ctx0 $ ctx1

let git_tcp tcpv4v6 ctx = Mirage_impl_git.git_tcp $ tcpv4v6 $ ctx

let git_ssh ?authenticator ~key ~password ?(mclock = default_monotonic_clock)
    ?(time = default_time) tcpv4v6 ctx =
  Mirage_impl_git.git_ssh ?authenticator key password
  $ mclock
  $ tcpv4v6
  $ time
  $ ctx

let git_http ?authenticator ?headers ?(pclock = default_posix_clock) tcpv4v6 ctx
    =
  Mirage_impl_git.git_http ?authenticator headers $ pclock $ tcpv4v6 $ ctx

let delay = job

let delay_startup =
  let delay_key = Runtime_arg.delay in
  let runtime_args = [ Runtime_arg.v delay_key ] in
  let packages = [ package ~max:"1.0.0" "duration" ] in
  let connect i _ = function
    | [ delay_key ] ->
        let modname =
          match Mirage_impl_misc.get_target i with
          | `Unix | `MacOSX -> "Unix_os.Time"
          | `Xen | `Qubes -> "Xen_os.Time"
          | `Virtio | `Hvt | `Spt | `Muen | `Genode -> "Solo5_os.Time"
        in
        code ~pos:__POS__ "%s.sleep_ns (Duration.of_sec %s)" modname delay_key
    | _ -> Mirage_impl_misc.connect_err "delay_startup" 1
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

  let dune i = Mirage_target.dune i
  let configure i = Mirage_target.configure i

  let dune_project =
    [ Dune.stanza {|
    (implicit_transitive_deps true)
    |} ]

  let dune_workspace =
    let f ?build_dir i =
      let stanzas = Mirage_target.build_context ?build_dir i in
      let main =
        Dune.stanza {|
(lang dune 2.0)

(context (default))
        |}
      in
      Dune.v (main :: stanzas)
    in
    Some f

  let context_name i = Mirage_target.context_name i

  let create jobs =
    let keys = Key.[ v target ] in
    let packages_v =
      (* XXX: use %%VERSION_NUM%% here instead of hardcoding a version? *)
      let min = "4.4.0" and max = "4.5.0" in
      let common =
        [
          package ~scope:`Monorepo "lwt";
          package ~scope:`Monorepo ~min ~max "mirage-runtime";
          package ~scope:`Switch ~build:true ~min ~max "mirage";
          package ~scope:`Switch ~build:true ~min:"0.3.2" "opam-monorepo";
        ]
      in
      Key.match_ Key.(value target) @@ fun target ->
      Mirage_target.packages target @ common
    in
    let install = Mirage_target.install in
    let extra_deps = List.map dep jobs in
    let connect _ _ _ = code ~pos:__POS__ "return ()" in
    impl ~keys ~packages_v ~configure ~dune ~connect ~extra_deps ~install
      "Mirage_runtime" job
end

include Lib.Make (Project)
module Tool = Tool.Make (Project)

let backtrace =
  let runtime_args = Runtime_arg.[ v backtrace ] in
  let connect _ _ = function
    | [ backtrace ] ->
        code ~pos:__POS__ "return (Printexc.record_backtrace %s)" backtrace
    | _ -> Mirage_impl_misc.connect_err "backtrace" 1
  in
  impl ~runtime_args ~connect "Printexc" job

let randomize_hashtables =
  let runtime_args = Runtime_arg.[ v randomize_hashtables ] in
  let connect _ _ = function
    | [ randomize_hashtables ] ->
        code ~pos:__POS__ "return (if %s then Hashtbl.randomize ())"
          randomize_hashtables
    | _ -> Mirage_impl_misc.connect_err "randomize_hashtables" 2
  in
  impl ~runtime_args ~connect "Hashtbl" job

let gc_control =
  let pp_pol ~name =
    Fmt.(
      any name
      ++ any " = "
      ++ any "(match "
      ++ string
      ++ any " with `Next_fit -> 0 | `First_fit -> 1 | `Best_fit -> 2)")
  and pp_k ~name =
    Fmt.(
      any name
      ++ any " = "
      ++ any "(match "
      ++ string
      ++ any " with None -> ctrl."
      ++ any name
      ++ any " | Some x -> x)")
  in
  let runtime_args =
    Runtime_arg.
      [
        v allocation_policy;
        v minor_heap_size;
        v major_heap_increment;
        v space_overhead;
        v max_space_overhead;
        v gc_verbosity;
        v gc_window_size;
        v custom_major_ratio;
        v custom_minor_ratio;
        v custom_minor_max_size;
      ]
  in
  let connect _ _ = function
    | [
        allocation_policy;
        minor_heap_size;
        major_heap_increment;
        space_overhead;
        max_space_overhead;
        gc_verbosity;
        gc_window_size;
        custom_major_ratio;
        custom_minor_ratio;
        custom_minor_max_size;
      ] ->
        code ~pos:__POS__
          "return (@.@[<v 2>let open Gc in@ let ctrl = get () in@ set ({ ctrl \
           with %a;@ %a;@ %a;@ %a;@ %a;@ %a;@ %a;@ %a;@ %a;@ %a })@]@.)"
          (pp_pol ~name:"allocation_policy")
          allocation_policy
          (pp_k ~name:"minor_heap_size")
          minor_heap_size
          (pp_k ~name:"major_heap_increment")
          major_heap_increment
          (pp_k ~name:"space_overhead")
          space_overhead
          (pp_k ~name:"max_overhead")
          max_space_overhead (pp_k ~name:"verbose") gc_verbosity
          (pp_k ~name:"window_size") gc_window_size
          (pp_k ~name:"custom_major_ratio")
          custom_major_ratio
          (pp_k ~name:"custom_minor_ratio")
          custom_minor_ratio
          (pp_k ~name:"custom_minor_max_size")
          custom_minor_max_size
    | _ -> Mirage_impl_misc.connect_err "gc_control" 11
  in
  impl ~runtime_args ~connect "Gc" job

(** Custom registration *)

let runtime_args argv =
  Functoria.runtime_args ~runtime_package:"mirage-runtime"
    ~runtime_modname:"Mirage_runtime" argv

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
  let first =
    [ runtime_args argv; backtrace; randomize_hashtables; gc_control ]
  in
  let reporter = if reporter == no_reporter then None else Some reporter in
  let init = Some first ++ Some delay_startup ++ reporter in
  register ?init ?src name jobs

module Action = Functoria.Action
