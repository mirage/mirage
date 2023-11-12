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
include Runtime_key

(** {2 OCaml runtime} *)

let ocaml_section = "OCAML RUNTIME PARAMETERS"
let unikernel_section = "UNIKERNEL PARAMETERS"

let runtime_key ~name data =
  Runtime_key.create ~name
    ~packages:[ package "mirage-runtime" ]
    ("(" ^ data ^ ")")

let runtime_keyf ~name fmt =
  Fmt.kstr
    (Runtime_key.create ~name ~packages:[ package "mirage-runtime" ])
    ("Mirage_runtime.key" ^^ fmt)

let backtrace =
  runtime_key ~name:"backtrace"
    (Fmt.str
       {|
  let doc =
    "Trigger the printing of a stack backtrace when an uncaught exception \
     aborts the unikernel."
  in
  let doc = Cmdliner.Arg.info ~docs:%S ~docv:"BOOL" ~doc [ "backtrace" ] in
  Cmdliner.Arg.(value & opt bool true doc)|}
       ocaml_section)

let randomize_hashtables =
  runtime_key ~name:"randomize-hashtables"
    (Fmt.str
       {|
  let doc = "Turn on randomization of all hash tables by default." in
  let doc =
    Cmdliner.Arg.info ~docs:%S ~docv:"BOOL" ~doc [ "randomize-hashtables" ]
  in
  Cmdliner.Arg.(value & opt bool true doc)|}
       ocaml_section)

(** {3 GC control} *)

let allocation_policy =
  runtime_key ~name:"allocation-policy"
    (Fmt.str
       {|
    let allocation_policy, allocation_policy_doc_alts =
      let enum =
        [
          ("next-fit", `Next_fit);
          ("first-fit", `First_fit);
          ("best-fit", `Best_fit);
        ]
      in
      (Cmdliner.Arg.enum enum, Cmdliner.Arg.doc_alts_enum enum)
    in
    let doc =
      Printf.sprintf
        "The policy used for allocating in the OCaml heap. Possible values are: \
         %%s. Best-fit is only supported since OCaml 4.10."
        allocation_policy_doc_alts
    in
    let doc =
      Cmdliner.Arg.info ~docs:%S ~docv:"ALLOCATION" ~doc [ "allocation-policy" ]
    in
    Cmdliner.Arg.(value & opt allocation_policy `Best_fit doc)|}
       ocaml_section)

let minor_heap_size =
  runtime_key ~name:"minor-heap-size"
    (Fmt.str
       {|
  let doc = "The size of the minor heap (in words). Default: 256k." in
  let doc =
    Cmdliner.Arg.info ~docs:%S ~docv:"MINOR SIZE" ~doc [ "minor-heap-size" ]
  in
  Cmdliner.Arg.(value & opt (some int) None doc)|}
       ocaml_section)

let major_heap_increment =
  runtime_key ~name:"major-heap-increment"
    (Fmt.str
       {|
  let doc =
    "The size increment for the major heap (in words). If less than or equal \
     1000, it is a percentage of the current heap size. If more than 1000, it \
     is a fixed number of words. Default: 15."
  in
  let doc =
    Cmdliner.Arg.info ~docs:%S ~docv:"MAJOR INCREMENT" ~doc
      [ "major-heap-increment" ]
  in
  Cmdliner.Arg.(value & opt (some int) None doc)|}
       ocaml_section)

let space_overhead =
  runtime_key ~name:"space-overhead"
    (Fmt.str
       {|
  let doc =
    "The percentage of live data of wasted memory, due to GC does not \
     immediately collect unreachable blocks. The major GC speed is computed \
     from this parameter, it will work more if smaller. Default: 80."
  in
  let doc =
    Cmdliner.Arg.info ~docs:%S ~docv:"SPACE OVERHEAD" ~doc
      [ "space-overhead" ]
  in
  Cmdliner.Arg.(value & opt (some int) None doc)|}
       ocaml_section)

let max_space_overhead =
  runtime_key ~name:"max-space-overhead"
    (Fmt.str
       {|
  let doc =
    "Heap compaction is triggered when the estimated amount of wasted memory \
     exceeds this (percentage of live data). If above 1000000, compaction is \
     never triggered. Default: 500."
  in
  let doc =
    Cmdliner.Arg.info ~docs:%S ~docv:"MAX SPACE OVERHEAD" ~doc
      [ "max-space-overhead" ]
  in
  Cmdliner.Arg.(value & opt (some int) None doc)|}
       ocaml_section)

let gc_verbosity =
  runtime_key ~name:"gc-verbosity"
    (Fmt.str
       {|
  let doc =
    "GC messages on standard error output. Sum of flags. Check GC module \
     documentation for details."
  in
  let doc =
    Cmdliner.Arg.info ~docs:%S ~docv:"VERBOSITY" ~doc [ "gc-verbosity" ]
  in
  Cmdliner.Arg.(value & opt (some int) None doc)|}
       ocaml_section)

let gc_window_size =
  runtime_key ~name:"gc-window-size"
    (Fmt.str
       {|
  let doc =
    "The size of the window used by the major GC for smoothing out variations \
     in its workload. Between 1 adn 50, default: 1."
  in
  let doc =
    Cmdliner.Arg.info ~docs:%S ~docv:"WINDOW SIZE" ~doc [ "gc-window-size" ]
  in
  Cmdliner.Arg.(value & opt (some int) None doc)|}
       ocaml_section)

let custom_major_ratio =
  runtime_key ~name:"custom-major-ratio"
    (Fmt.str
       {|
  let doc =
    "Target ratio of floating garbage to major heap size for out-of-heap \
     memory held by custom values. Default: 44."
  in
  let doc =
    Cmdliner.Arg.info ~docs:%S ~docv:"CUSTOM MAJOR RATIO" ~doc
      [ "custom-major-ratio" ]
  in
  Cmdliner.Arg.(value & opt (some int) None doc)|}
       ocaml_section)

let custom_minor_ratio =
  runtime_key ~name:"custom-minor-ratio"
    (Fmt.str
       {|
  let doc =
    "Bound on floating garbage for out-of-heap memory held by custom values in \
     the minor heap. Default: 100."
  in
  let doc =
    Cmdliner.Arg.info ~docs:%S ~docv:"CUSTOM MINOR RATIO" ~doc
      [ "custom-minor-ratio" ]
  in
  Cmdliner.Arg.(value & opt (some int) None doc)|}
       ocaml_section)

let custom_minor_max_size =
  runtime_key ~name:"custom-minor-max-size"
    (Fmt.str
       {|
  let doc =
    "Maximum amount of out-of-heap memory for each custom value allocated in \
     the minor heap. Default: 8192 bytes."
  in
  let doc =
    Cmdliner.Arg.info ~docs:%S ~docv:"CUSTOM MINOR MAX SIZE" ~doc
      [ "custom-minor-max-size" ]
  in
  Cmdliner.Arg.(value & opt (some int) None doc)|}
       ocaml_section)

(** {3 Logs} *)

let logs =
  runtime_key ~name:"logs"
    (Fmt.str
       {|
  let logs = Cmdliner.Arg.list Mirage_runtime.Conv.log_threshold in
  let doc =
    "Be more or less verbose. $(docv) must be of the form \
     $(b,*:info,foo:debug) means that that the log threshold is set to \
     $(b,info) for every log sources but the $(b,foo) which is set to \
     $(b,debug)."
  in
  let doc = Cmdliner.Arg.info ~docv:"LEVEL" ~doc ~docs:%S [ "l"; "logs" ] in
  Cmdliner.Arg.(value & opt logs [] doc)|}
       unikernel_section)

(** {3 Initial delay} *)

let delay =
  runtime_key ~name:"delay"
    (Fmt.str
       {|
  let doc =
    Cmdliner.Arg.info ~docs:%S ~doc:"Delay n seconds before starting up"
      [ "delay" ]
  in
  Cmdliner.Arg.(value & opt int 0 doc)|}
       unikernel_section)

let runtime_network_key ~name fmt =
  Fmt.kstr
    (Runtime_key.create ~name
       ~packages:[ package "mirage-runtime" ~sublibs:[ "network" ] ])
    ("(Mirage_runtime_network." ^^ fmt ^^ ")")

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
  runtime_keyf ~name:"syslog" "syslog %a" (pp_option pp_ipaddr) default

let syslog_port default =
  runtime_keyf ~name:"syslog_port" "syslog_port %a" (pp_option Fmt.int) default

let syslog_hostname default =
  runtime_keyf ~name:"syslog_hostname" "syslog_hostname %S" default
