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

open Functoria.DSL
include Functoria.Runtime_arg

(** {2 OCaml runtime} *)

let runtime_arg ~pos name =
  create ~pos
    ~packages:[ package "mirage-runtime" ]
    (Fmt.str "Mirage_runtime.%s" name)

let runtime_network_key ~pos fmt =
  Fmt.kstr
    (create ~pos ~packages:[ package "mirage-runtime" ~sublibs:[ "network" ] ])
    ("Mirage_runtime_network." ^^ fmt)

let delay = runtime_arg ~pos:__POS__ "delay"

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

let interface ?group ?docs default =
  runtime_network_key ~pos:__POS__ "interface %a%a%S" pp_group group pp_docs
    docs default

module V4 = struct
  open Ipaddr.V4

  let pp_prefix ppf p =
    Fmt.pf ppf "(Ipaddr.V4.Prefix.of_string_exn %a)" (escape Prefix.pp) p

  let pp ppf p = Fmt.pf ppf "(Ipaddr.V4.of_string_exn %a)" (escape pp) p

  let network ?group ?docs default =
    runtime_network_key ~pos:__POS__ "V4.network %a%a%a" pp_group group pp_docs
      docs pp_prefix default

  let gateway ?group ?docs default =
    runtime_network_key ~pos:__POS__ "V4.gateway %a%a%a" pp_group group pp_docs
      docs (pp_option pp) default
end

module V6 = struct
  open Ipaddr.V6

  let pp_prefix ppf p =
    Fmt.pf ppf "(Ipaddr.V6.Prefix.of_string_exn %a)" (escape Prefix.pp) p

  let pp ppf p = Fmt.pf ppf "(Ipaddr.V6.of_string_exn %a)" (escape pp) p

  let network ?group ?docs default =
    runtime_network_key ~pos:__POS__ "V6.network %a%a%a" pp_group group pp_docs
      docs (pp_option pp_prefix) default

  let gateway ?group ?docs default =
    runtime_network_key ~pos:__POS__ "V6.gateway %a%a%a" pp_group group pp_docs
      docs (pp_option pp) default

  let accept_router_advertisements ?group ?docs () =
    runtime_network_key ~pos:__POS__ "V6.accept_router_advertisements %a%a()"
      pp_group group pp_docs docs
end

let ipv4_only ?group ?docs () =
  runtime_network_key ~pos:__POS__ "ipv4_only %a%a()" pp_group group pp_docs
    docs

let ipv6_only ?group ?docs () =
  runtime_network_key ~pos:__POS__ "ipv6_only %a%a()" pp_group group pp_docs
    docs

let resolver ?group ?docs ?(default = []) () =
  let pp_default ppf = function
    | [] -> ()
    | l -> Fmt.pf ppf "~default:%a " Fmt.Dump.(list string) l
  in
  runtime_network_key ~pos:__POS__ "resolver %a%a%a()" pp_group group pp_docs
    docs pp_default default

let dns_servers ?group ?docs default =
  runtime_network_key ~pos:__POS__ "dns_servers %a%a%a" pp_group group pp_docs
    docs
    (pp_option Fmt.Dump.(list string))
    default

let dns_timeout ?group ?docs default =
  runtime_network_key ~pos:__POS__ "dns_timeout %a%a%a" pp_group group pp_docs
    docs (pp_option Fmt.int64) default

let dns_cache_size ?group ?docs default =
  runtime_network_key ~pos:__POS__ "dns_cache_size %a%a%a" pp_group group
    pp_docs docs (pp_option Fmt.int) default

let he_aaaa_timeout ?group ?docs default =
  runtime_network_key ~pos:__POS__ "he_aaaa_timeout %a%a%a" pp_group group
    pp_docs docs (pp_option Fmt.int64) default

let he_connect_delay ?group ?docs default =
  runtime_network_key ~pos:__POS__ "he_connect_delay %a%a%a" pp_group group
    pp_docs docs (pp_option Fmt.int64) default

let he_connect_timeout ?group ?docs default =
  runtime_network_key ~pos:__POS__ "he_connect_timeout %a%a%a" pp_group group
    pp_docs docs (pp_option Fmt.int64) default

let he_resolve_timeout ?group ?docs default =
  runtime_network_key ~pos:__POS__ "he_resolve_timeout %a%a%a" pp_group group
    pp_docs docs (pp_option Fmt.int64) default

let he_resolve_retries ?group ?docs default =
  runtime_network_key ~pos:__POS__ "he_resolve_retries %a%a%a" pp_group group
    pp_docs docs (pp_option Fmt.int) default

let he_timer_interval ?group ?docs default =
  runtime_network_key ~pos:__POS__ "he_timer_interval %a%a%a" pp_group group
    pp_docs docs (pp_option Fmt.int64) default

let ssh_key ?group ?docs default =
  runtime_network_key ~pos:__POS__ "ssh_key %a%a%a" pp_group group pp_docs docs
    (pp_option Fmt.Dump.string)
    default

let ssh_password ?group ?docs default =
  runtime_network_key ~pos:__POS__ "ssh_password %a%a%a" pp_group group pp_docs
    docs
    (pp_option Fmt.Dump.string)
    default

let ssh_authenticator ?group ?docs default =
  runtime_network_key ~pos:__POS__ "ssh_authenticator %a%a%a" pp_group group
    pp_docs docs
    (pp_option Fmt.Dump.string)
    default

let tls_authenticator ?group ?docs default =
  runtime_network_key ~pos:__POS__ "tls_authenticator %a%a%a" pp_group group
    pp_docs docs
    (pp_option Fmt.Dump.string)
    default

let http_headers ?group ?docs default =
  runtime_network_key ~pos:__POS__ "http_headers %a%a%a" pp_group group pp_docs
    docs
    (pp_option Fmt.Dump.(list (pair string string)))
    default

let pp_ipaddr ppf p = Fmt.pf ppf "Ipaddr.of_string %a" (escape Ipaddr.pp) p

let syslog ?group ?docs default =
  runtime_network_key ~pos:__POS__ "syslog %a%a%a" pp_group group pp_docs docs
    (pp_option pp_ipaddr) default

let syslog_port ?group ?docs default =
  runtime_network_key ~pos:__POS__ "syslog_port %a%a%a" pp_group group pp_docs
    docs (pp_option Fmt.int) default

let syslog_truncate ?group ?docs default =
  runtime_network_key ~pos:__POS__ "syslog_truncate %a%a%a" pp_group group
    pp_docs docs (pp_option Fmt.int) default

let syslog_keyname ?group ?docs default =
  runtime_network_key ~pos:__POS__ "syslog_keyname %a%a%a" pp_group group
    pp_docs docs (pp_option Fmt.string) default

let monitor ?group ?docs default =
  runtime_network_key ~pos:__POS__ "monitor %a%a%a" pp_group group pp_docs docs
    (pp_option pp_ipaddr) default

type log_threshold = [ `All | `Src of string ] * Logs.level option

let logs = runtime_arg ~pos:__POS__ "logs"
