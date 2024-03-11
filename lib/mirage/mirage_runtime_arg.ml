(*
 * Copyright (c) 2023 Thomas Gazagnaire <thomas@gazagnaire.org>
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
include Runtime_arg

(** {2 OCaml runtime} *)

let runtime_arg ~pos name =
  Runtime_arg.create ~name ~pos
    ~packages:[ package "mirage-runtime" ]
    (Fmt.str "Mirage_runtime.%s" name)

let runtime_network_key ~pos ~name fmt =
  Fmt.kstr
    (Runtime_arg.create ~name ~pos
       ~packages:[ package "mirage-runtime" ~sublibs:[ "network" ] ])
    ("Mirage_runtime_network." ^^ fmt)

let delay = runtime_arg ~pos:__POS__ "delay"
let backtrace = runtime_arg ~pos:__POS__ "backtrace"
let randomize_hashtables = runtime_arg ~pos:__POS__ "randomize_hashtables"
let allocation_policy = runtime_arg ~pos:__POS__ "allocation_policy"
let minor_heap_size = runtime_arg ~pos:__POS__ "minor_heap_size"
let major_heap_increment = runtime_arg ~pos:__POS__ "major_heap_increment"
let space_overhead = runtime_arg ~pos:__POS__ "space_overhead"
let max_space_overhead = runtime_arg ~pos:__POS__ "max_space_overhead"
let gc_verbosity = runtime_arg ~pos:__POS__ "gc_verbosity"
let gc_window_size = runtime_arg ~pos:__POS__ "gc_window_size"
let custom_major_ratio = runtime_arg ~pos:__POS__ "custom_major_ratio"
let custom_minor_ratio = runtime_arg ~pos:__POS__ "custom_minor_ratio"
let custom_minor_max_size = runtime_arg ~pos:__POS__ "custom_minor_max_size"

let pp_group ppf = function
  | None | Some "" -> ()
  | Some g -> Fmt.pf ppf "~group:%S " g

let pp_docs ppf = function
  | None | Some "" -> ()
  | Some g -> Fmt.pf ppf "~docs:%S " g

let pp_option pp ppf = function
  | None -> Fmt.pf ppf "None"
  | Some d -> Fmt.pf ppf "(Some %a)" pp d

let escape pp ppf = Fmt.kstr (fun str -> Fmt.Dump.string ppf str) "%a" pp

(** {3 Network keys} *)

let mk_name ?group name =
  match group with None | Some "" -> name | Some p -> Fmt.str "%s-%s" p name

let interface ?group ?docs default =
  let name = mk_name ?group "interface" in
  runtime_network_key ~pos:__POS__ ~name "interface %a%a%S" pp_group group
    pp_docs docs default

module V4 = struct
  open Ipaddr.V4

  let pp_prefix ppf p =
    Fmt.pf ppf "(Ipaddr.V4.Prefix.of_string_exn %a)" (escape Prefix.pp) p

  let pp ppf p = Fmt.pf ppf "(Ipaddr.V4.of_string_exn %a)" (escape pp) p

  let network ?group ?docs default =
    let name = mk_name ?group "ipv4" in
    runtime_network_key ~name ~pos:__POS__ "V4.network %a%a%a" pp_group group
      pp_docs docs pp_prefix default

  let gateway ?group ?docs default =
    let name = mk_name ?group "ipv4-gateway" in
    runtime_network_key ~name ~pos:__POS__ "V4.gateway %a%a%a" pp_group group
      pp_docs docs (pp_option pp) default
end

module V6 = struct
  open Ipaddr.V6

  let pp_prefix ppf p =
    Fmt.pf ppf "(Ipaddr.V6.Prefix.of_string_exn %a)" (escape Prefix.pp) p

  let pp ppf p = Fmt.pf ppf "(Ipaddr.V6.of_string_exn %a)" (escape pp) p

  let network ?group ?docs default =
    let name = mk_name ?group "ipv6" in
    runtime_network_key ~name ~pos:__POS__ "V6.network %a%a%a" pp_group group
      pp_docs docs (pp_option pp_prefix) default

  let gateway ?group ?docs default =
    let name = mk_name ?group "ipv6-gateway" in
    runtime_network_key ~name ~pos:__POS__ "V6.gateway %a%a%a" pp_group group
      pp_docs docs (pp_option pp) default

  let accept_router_advertisements ?group ?docs () =
    let name = mk_name ?group "accept-router-advertisements" in
    runtime_network_key ~name ~pos:__POS__
      "V6.accept_router_advertisements %a%a()" pp_group group pp_docs docs
end

let ipv4_only ?group ?docs () =
  let name = mk_name ?group "ipv4-only" in
  runtime_network_key ~name ~pos:__POS__ "ipv4_only %a%a()" pp_group group
    pp_docs docs

let ipv6_only ?group ?docs () =
  let name = mk_name ?group "ipv6-only" in
  runtime_network_key ~name ~pos:__POS__ "ipv6_only %a%a()" pp_group group
    pp_docs docs

let resolver ?group ?docs ?(default = []) () =
  let pp_default ppf = function
    | [] -> ()
    | l -> Fmt.pf ppf "~default:%a " Fmt.Dump.(list string) l
  in
  runtime_network_key ~pos:__POS__ ~name:"resolver" "resolver %a%a%a()" pp_group
    group pp_docs docs pp_default default

let pp_ipaddr ?group ?docs ppf p =
  Fmt.pf ppf "Ipaddr.of_string %a%a%a" pp_group group pp_docs docs
    (escape Ipaddr.pp) p

let syslog ?group ?docs default =
  let name = mk_name ?group "syslog" in
  runtime_network_key ~pos:__POS__ ~name "syslog %a%a%a" pp_group group pp_docs
    docs (pp_option pp_ipaddr) default

let monitor ?group ?docs default =
  let name = mk_name ?group "monitor" in
  runtime_network_key ~pos:__POS__ ~name "monitor %a%a%a" pp_group group pp_docs
    docs (pp_option pp_ipaddr) default

let syslog_port ?group ?docs default =
  let name = mk_name ?group "syslog-port" in
  runtime_network_key ~pos:__POS__ ~name "syslog_port %a%a%a" pp_group group
    pp_docs docs (pp_option Fmt.int) default

let syslog_hostname ?group ?docs default =
  let name = mk_name ?group "syslog-hostname" in
  runtime_network_key ~pos:__POS__ ~name "syslog_hostname %a%a%S" pp_group group
    pp_docs docs default

type log_threshold = [ `All | `Src of string ] * Logs.level option

let logs = runtime_arg ~pos:__POS__ "logs"
