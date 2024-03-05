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

let runtime_arg name =
  Runtime_arg.create ~name
    ~packages:[ package "mirage-runtime" ]
    (Fmt.str "Mirage_runtime.%s" name)

let runtime_argf ~name fmt =
  Fmt.kstr
    (Runtime_arg.create ~name ~packages:[ package "mirage-runtime" ])
    ("Mirage_runtime." ^^ fmt)

let runtime_network_key ~name fmt =
  Fmt.kstr
    (Runtime_arg.create ~name
       ~packages:[ package "mirage-runtime" ~sublibs:[ "network" ] ])
    ("(Mirage_runtime_network." ^^ fmt ^^ ")")

let delay = runtime_arg "delay"
let backtrace = runtime_arg "backtrace"
let randomize_hashtables = runtime_arg "randomize_hashtables"
let allocation_policy = runtime_arg "allocation_policy"
let minor_heap_size = runtime_arg "minor_heap_size"
let major_heap_increment = runtime_arg "major_heap_increment"
let space_overhead = runtime_arg "space_overhead"
let max_space_overhead = runtime_arg "max_space_overhead"
let gc_verbosity = runtime_arg "gc_verbosity"
let gc_window_size = runtime_arg "gc_window_size"
let custom_major_ratio = runtime_arg "custom_major_ratio"
let custom_minor_ratio = runtime_arg "custom_minor_ratio"
let custom_minor_max_size = runtime_arg "custom_minor_max_size"

let pp_group ppf = function
  | None | Some "" -> ()
  | Some g -> Fmt.pf ppf "~group:%S " g

let pp_option pp ppf = function
  | None -> Fmt.pf ppf "None"
  | Some d -> Fmt.pf ppf "(Some %a)" pp d

let escape pp ppf = Fmt.kstr (fun str -> Fmt.Dump.string ppf str) "%a" pp

(** {3 Network keys} *)

let mk_name ?group name =
  match group with None | Some "" -> name | Some p -> Fmt.str "%s-%s" p name

let interface ?group default =
  let name = mk_name ?group "interface" in
  runtime_network_key ~name "interface %a%S" pp_group group default

module V4 = struct
  open Ipaddr.V4

  let pp_prefix ppf p =
    Fmt.pf ppf "(Ipaddr.V4.Prefix.of_string_exn %a)" (escape Prefix.pp) p

  let pp ppf p = Fmt.pf ppf "(Ipaddr.V4.of_string_exn %a)" (escape pp) p

  let network ?group default =
    let name = mk_name ?group "ipv4" in
    runtime_network_key ~name "V4.network %a%a" pp_group group pp_prefix default

  let gateway ?group default =
    let name = mk_name ?group "ipv4-gateway" in
    runtime_network_key ~name "V4.gateway %a%a" pp_group group (pp_option pp)
      default
end

module V6 = struct
  open Ipaddr.V6

  let pp_prefix ppf p =
    Fmt.pf ppf "(Ipaddr.V6.Prefix.of_string_exn %a)" (escape Prefix.pp) p

  let pp ppf p = Fmt.pf ppf "(Ipaddr.V6.of_string_exn %a)" (escape pp) p

  let network ?group default =
    let name = mk_name ?group "ipv6" in
    runtime_network_key ~name "V6.network %a%a" pp_group group
      (pp_option pp_prefix) default

  let gateway ?group default =
    let name = mk_name ?group "ipv6-gateway" in
    runtime_network_key ~name "V6.gateway %a%a" pp_group group (pp_option pp)
      default

  let accept_router_advertisements ?group () =
    let name = mk_name ?group "accept-router-advertisements" in
    runtime_network_key ~name "V6.accept_router_advertisements %a()" pp_group
      group
end

let ipv4_only ?group () =
  let name = mk_name ?group "ipv4-only" in
  runtime_network_key ~name "ipv4_only %a()" pp_group group

let ipv6_only ?group () =
  let name = mk_name ?group "ipv6-only" in
  runtime_network_key ~name "ipv6_only %a()" pp_group group

let resolver ?(default = []) () =
  let pp_default ppf = function
    | [] -> ()
    | l -> Fmt.pf ppf "~default:%a " Fmt.Dump.(list string) l
  in
  runtime_network_key ~name:"resolver" "resolver %a()" pp_default default

let pp_ipaddr ppf p = Fmt.pf ppf "Ipaddr.of_string %a" (escape Ipaddr.pp) p

let syslog default =
  runtime_argf ~name:"syslog" "syslog %a" (pp_option pp_ipaddr) default

let syslog_port default =
  runtime_argf ~name:"syslog_port" "syslog_port %a" (pp_option Fmt.int) default

let syslog_hostname default =
  runtime_argf ~name:"syslog_hostname" "syslog_hostname %S" default

let logs = runtime_arg "logs"
