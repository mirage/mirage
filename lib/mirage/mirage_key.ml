(*
 * Copyright (c) 2015 Gabriel Radanne <drupyog@zoho.com>
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
module Key = Key
module Alias = Key.Alias
open Astring

(** {2 Custom Descriptions} *)

module Arg = struct
  include Key.Arg

  let from_run s = "Mirage_runtime.Arg." ^ s

  let make d m of_string to_string =
    let parser s =
      match of_string s with
      | Error (`Msg m) -> `Error ("Can't parse ip address: " ^ s ^ ": " ^ m)
      | Ok ip -> `Ok ip
    and serialize ppf t = Fmt.pf ppf "(%s.of_string_exn %S)" m (to_string t)
    and pp ppf t = Fmt.string ppf (to_string t) in
    Key.Arg.conv ~conv:(parser, pp) ~serialize ~runtime_conv:(from_run d)

  module type S = sig
    type t

    val of_string : string -> (t, [ `Msg of string ]) result
    val to_string : t -> string
  end

  let of_module (type t) d m (module M : S with type t = t) =
    make d m M.of_string M.to_string

  let ipv4_address = of_module "ipv4_address" "Ipaddr.V4" (module Ipaddr.V4)
  let ipv4 = of_module "ipv4" "Ipaddr.V4.Prefix" (module Ipaddr.V4.Prefix)
  let ipv6_address = of_module "ipv6_address" "Ipaddr.V6" (module Ipaddr.V6)
  let ipv6 = of_module "ipv6" "Ipaddr.V6.Prefix" (module Ipaddr.V6.Prefix)
  let ip_address = of_module "ip_address" "Ipaddr" (module Ipaddr)
end

(** {2 Documentation helper} *)

let mirage_section = "MIRAGE PARAMETERS"
let unikernel_section = "UNIKERNEL PARAMETERS"
let pp_group = Fmt.(option ~none:(any "the unikernel") @@ fmt "the %s group")

(** {2 Special keys} *)

(** {3 Mode} *)

type mode_unix = [ `Unix | `MacOSX ]
type mode_xen = [ `Xen | `Qubes ]
type mode_solo5 = [ `Hvt | `Spt | `Virtio | `Muen | `Genode ]
type mode = [ mode_unix | mode_xen | mode_solo5 ]

let first_ukvm_mention = ref true

let ukvm_warning =
  "The `ukvm' target has been renamed to `hvt'. Support for the `ukvm` target \
   will be removed in a future MirageOS release. Please reconfigure using `-t \
   hvt' at your earliest convenience."

let target_conv : mode Cmdliner.Arg.conv =
  let parser, printer =
    Cmdliner.Arg.enum
      [
        ("unix", `Unix);
        ("macosx", `MacOSX);
        ("xen", `Xen);
        ("virtio", `Virtio);
        ("hvt", `Hvt);
        ("muen", `Muen);
        ("qubes", `Qubes);
        ("genode", `Genode);
        ("spt", `Spt);
      ]
  in
  let filter_ukvm s =
    let str =
      if s = "ukvm" then (
        if !first_ukvm_mention then (
          Logs.warn (fun m -> m "%s" ukvm_warning);
          first_ukvm_mention := false);
        "hvt")
      else s
    in
    parser str
  in
  (filter_ukvm, printer)

let target_serialize ppf = function
  | `Unix -> Fmt.pf ppf "`Unix"
  | `Xen -> Fmt.pf ppf "`Xen"
  | `Virtio -> Fmt.pf ppf "`Virtio"
  | `Hvt -> Fmt.pf ppf "`Hvt"
  | `Muen -> Fmt.pf ppf "`Muen"
  | `MacOSX -> Fmt.pf ppf "`MacOSX"
  | `Qubes -> Fmt.pf ppf "`Qubes"
  | `Genode -> Fmt.pf ppf "`Genode"
  | `Spt -> Fmt.pf ppf "`Spt"

let pp_target fmt m = snd target_conv fmt m

let default_target =
  match Sys.getenv "MIRAGE_DEFAULT_TARGET" with
  | "unix" -> `Unix
  | s -> Fmt.failwith "invalid default target: %S" s
  | exception Not_found -> (
      match Action.run @@ Action.run_cmd_out Bos.Cmd.(v "uname" % "-s") with
      | Ok "Darwin" -> `MacOSX
      | _ -> `Unix)

let target =
  let doc =
    "Target platform to compile the unikernel for. Valid values are: $(i,xen), \
     $(i,qubes), $(i,unix), $(i,macosx), $(i,virtio), $(i,hvt), $(i,spt), \
     $(i,muen), $(i,genode)."
  in
  let conv =
    Arg.conv ~conv:target_conv ~runtime_conv:"target"
      ~serialize:target_serialize
  in
  let doc =
    Arg.info ~docs:mirage_section ~docv:"TARGET" ~doc [ "t"; "target" ]
      ~env:"MODE"
  in
  let key = Arg.opt ~stage:`Configure conv default_target doc in
  Key.create "target" key

let is_unix =
  Key.match_ Key.(value target) @@ function
  | #mode_unix -> true
  | #mode_xen | #mode_solo5 -> false

let is_solo5 =
  Key.match_ Key.(value target) @@ function
  | #mode_solo5 -> true
  | #mode_xen | #mode_unix -> false

let is_xen =
  Key.match_ Key.(value target) @@ function
  | #mode_xen -> true
  | #mode_solo5 | #mode_unix -> false

let warn_error =
  let doc = "Enable -warn-error when compiling OCaml sources." in
  let doc = Arg.info ~docs:mirage_section ~docv:"BOOL" ~doc [ "warn-error" ] in
  let key = Arg.flag ~stage:`Configure doc in
  Key.create "warn_error" key

let target_debug =
  let doc =
    "Enables target-specific support for debugging. Supported targets: hvt \
     (compiles solo5-hvt with GDB server support)."
  in
  let doc = Arg.info ~docs:mirage_section ~docv:"DEBUG" ~doc [ "g" ] in
  let key = Arg.flag ~stage:`Configure doc in
  Key.create "target_debug" key

(** {3 Tracing} *)

let tracing_size default =
  let doc = "The size of the trace ring buffer." in
  let doc =
    Arg.info ~docs:mirage_section ~docv:"SIZE" ~doc [ "tracing-size" ]
  in
  let key = Arg.opt ~stage:`Configure Arg.int default doc in
  Key.create "tracing_size" key

(** {2 OCaml runtime} *)

let ocaml_section = "OCAML RUNTIME PARAMETERS"

let backtrace =
  let doc =
    "Trigger the printing of a stack backtrace when an uncaught exception \
     aborts the unikernel."
  in
  let doc = Arg.info ~docs:ocaml_section ~docv:"BOOL" ~doc [ "backtrace" ] in
  let key = Arg.opt Arg.bool true doc in
  Key.create "backtrace" key

let randomize_hashtables =
  let doc = "Turn on randomization of all hash tables by default." in
  let doc =
    Arg.info ~docs:ocaml_section ~docv:"BOOL" ~doc [ "randomize-hashtables" ]
  in
  let key = Arg.opt Arg.bool true doc in
  Key.create "randomize-hashtables" key

let allocation_policy =
  let doc =
    "The policy used for allocating in the OCaml heap. Possible values are: \
     $(i,next-fit), $(i,first-fit), $(i,best-fit). Best-fit is only supported \
     since OCaml 4.10."
  in
  let serialize ppf = function
    | `Next_fit -> Fmt.pf ppf "`Next_fit"
    | `First_fit -> Fmt.pf ppf "`First_fit"
    | `Best_fit -> Fmt.pf ppf "`Best_fit"
  and conv = Mirage_runtime.Arg.allocation_policy in
  let conv =
    Arg.conv ~conv ~runtime_conv:"Mirage_runtime.Arg.allocation_policy"
      ~serialize
  in
  let doc =
    Arg.info ~docs:ocaml_section ~docv:"ALLOCATION" ~doc [ "allocation-policy" ]
  in
  let key = Arg.opt conv `Next_fit doc in
  Key.create "allocation-policy" key

let minor_heap_size =
  let doc = "The size of the minor heap (in words). Default: 256k." in
  let doc =
    Arg.info ~docs:ocaml_section ~docv:"MINOR SIZE" ~doc [ "minor-heap-size" ]
  in
  let key = Arg.(opt (some int) None doc) in
  Key.create "minor-heap-size" key

let major_heap_increment =
  let doc =
    "The size increment for the major heap (in words). If less than or equal \
     1000, it is a percentage of the current heap size. If more than 1000, it \
     is a fixed number of words. Default: 15."
  in
  let doc =
    Arg.info ~docs:ocaml_section ~docv:"MAJOR INCREMENT" ~doc
      [ "major-heap-increment" ]
  in
  let key = Arg.(opt (some int) None doc) in
  Key.create "major-heap-increment" key

let space_overhead =
  let doc =
    "The percentage of live data of wasted memory, due to GC does not \
     immediately collect unreachable blocks. The major GC speed is computed \
     from this parameter, it will work more if smaller. Default: 80."
  in
  let doc =
    Arg.info ~docs:ocaml_section ~docv:"SPACE OVERHEAD" ~doc
      [ "space-overhead" ]
  in
  let key = Arg.(opt (some int) None doc) in
  Key.create "space-overhead" key

let max_space_overhead =
  let doc =
    "Heap compaction is triggered when the estimated amount of wasted memory \
     exceeds this (percentage of live data). If above 1000000, compaction is \
     never triggered. Default: 500."
  in
  let doc =
    Arg.info ~docs:ocaml_section ~docv:"MAX SPACE OVERHEAD" ~doc
      [ "max-space-overhead" ]
  in
  let key = Arg.(opt (some int) None doc) in
  Key.create "max-space-overhead" key

let gc_verbosity =
  let doc =
    "GC messages on standard error output. Sum of flags. Check GC module \
     documentation for details."
  in
  let doc =
    Arg.info ~docs:ocaml_section ~docv:"VERBOSITY" ~doc [ "gc-verbosity" ]
  in
  let key = Arg.(opt (some int) None doc) in
  Key.create "gc-verbosity" key

let gc_window_size =
  let doc =
    "The size of the window used by the major GC for smoothing out variations \
     in its workload. Between 1 adn 50, default: 1."
  in
  let doc =
    Arg.info ~docs:ocaml_section ~docv:"WINDOW SIZE" ~doc [ "gc-window-size" ]
  in
  let key = Arg.(opt (some int) None doc) in
  Key.create "gc-window-size" key

let custom_major_ratio =
  let doc =
    "Target ratio of floating garbage to major heap size for out-of-heap \
     memory held by custom values. Default: 44."
  in
  let doc =
    Arg.info ~docs:ocaml_section ~docv:"CUSTOM MAJOR RATIO" ~doc
      [ "custom-major-ratio" ]
  in
  let key = Arg.(opt (some int) None doc) in
  Key.create "custom-major-ratio" key

let custom_minor_ratio =
  let doc =
    "Bound on floating garbage for out-of-heap memory held by custom values in \
     the minor heap. Default: 100."
  in
  let doc =
    Arg.info ~docs:ocaml_section ~docv:"CUSTOM MINOR RATIO" ~doc
      [ "custom-minor-ratio" ]
  in
  let key = Arg.(opt (some int) None doc) in
  Key.create "custom-minor-ratio" key

let custom_minor_max_size =
  let doc =
    "Maximum amount of out-of-heap memory for each custom value allocated in \
     the minor heap. Default: 8192 bytes."
  in
  let doc =
    Arg.info ~docs:ocaml_section ~docv:"CUSTOM MINOR MAX SIZE" ~doc
      [ "custom-minor-max-size" ]
  in
  let key = Arg.(opt (some int) None doc) in
  Key.create "custom-minor-max-size" key

(** {2 General mirage keys} *)

let create_simple ?(group = "") ?(stage = `Both) ~doc ~default conv name =
  let prefix = if group = "" then group else group ^ "-" in
  let doc =
    Arg.info ~docs:unikernel_section
      ~docv:(String.Ascii.uppercase name)
      ~doc
      [ prefix ^ name ]
  in
  let key = Arg.opt ~stage conv default doc in
  Key.create (prefix ^ name) key

(** {3 File system keys} *)

let kv_ro ?group () =
  let conv =
    Cmdliner.Arg.enum
      [
        ("fat", `Fat);
        ("archive", `Archive);
        ("crunch", `Crunch);
        ("direct", `Direct);
      ]
  in
  let serialize =
    Fmt.of_to_string @@ function
    | `Fat -> "`Fat"
    | `Archive -> "`Archive"
    | `Crunch -> "`Crunch"
    | `Direct -> "`Direct"
  in
  let conv = Arg.conv ~conv ~serialize ~runtime_conv:"kv_ro" in
  let doc =
    Fmt.str
      "Use a $(i,fat), $(i,archive), $(i,crunch) or $(i,direct) pass-through \
       implementation for %a."
      pp_group group
  in
  create_simple ~doc ?group ~stage:`Configure ~default:`Crunch conv "kv_ro"

(** {3 Block device keys} *)
let block ?group () =
  let conv =
    Cmdliner.Arg.enum
      [ ("xenstore", `XenstoreId); ("file", `BlockFile); ("ramdisk", `Ramdisk) ]
  in
  let serialize =
    Fmt.of_to_string @@ function
    | `XenstoreId -> "`XenstoreId"
    | `BlockFile -> "`BlockFile"
    | `Ramdisk -> "`Ramdisk"
  in
  let conv = Arg.conv ~conv ~serialize ~runtime_conv:"block" in
  let doc =
    Fmt.str
      "Use a $(i,ramdisk), $(i,xenstore), or $(i,file) pass-through \
       implementation for %a."
      pp_group group
  in
  create_simple ~doc ?group ~stage:`Configure ~default:`Ramdisk conv "block"

(** {3 PRNG key} *)
let prng =
  let conv =
    Cmdliner.Arg.enum
      [ ("stdlib", `Stdlib); ("nocrypto", `Nocrypto); ("fortuna", `Nocrypto) ]
  in
  let serialize =
    Fmt.of_to_string @@ function
    | `Stdlib -> "`Stdlib"
    | `Nocrypto -> "`Nocrypto"
  in
  let conv = Arg.conv ~conv ~serialize ~runtime_conv:"prng" in
  let doc =
    Fmt.str
      "This boot parameter is deprecated. A Fortuna PRNG \
       (https://en.wikipedia.org/wiki/Fortuna_(PRNG)) will always be used. The \
       mirage-crypto-entropy (https://github.com/mirage/mirage-crypto) opam \
       package feeds entropy to Fortuna."
  in
  create_simple ~doc ~stage:`Configure ~default:`Stdlib conv "prng"

(** {3 Stack keys} *)

let dhcp ?group () =
  let doc = Fmt.str "Enable dhcp for %a." pp_group group in
  create_simple ~doc ?group ~stage:`Configure ~default:false Arg.bool "dhcp"

let net ?group () : [ `Socket | `Direct ] option Key.key =
  let conv = Cmdliner.Arg.enum [ ("socket", `Socket); ("direct", `Direct) ] in
  let serialize fmt = function
    | `Socket -> Fmt.string fmt "`Socket"
    | `Direct -> Fmt.string fmt "`Direct"
  in
  let conv = Arg.conv ~conv ~runtime_conv:"net" ~serialize in
  let doc =
    Fmt.str "Use $(i,socket) or $(i,direct) group for %a." pp_group group
  in
  create_simple ~doc ?group ~stage:`Configure ~default:None (Arg.some conv)
    "net"

(** {3 Network keys} *)

let interface ?group default =
  let doc = Fmt.str "The network interface listened by %a." pp_group group in
  create_simple ~doc ~default ?group Arg.string "interface"

module V4 = struct
  let network ?group default =
    let doc =
      Fmt.str
        "The network of %a specified as an IP address and netmask, e.g. \
         192.168.0.1/16 ."
        pp_group group
    in
    create_simple ~doc ~default ?group Arg.ipv4 "ipv4"

  let gateway ?group default =
    let doc = Fmt.str "The gateway of %a." pp_group group in
    create_simple ~doc ~default ?group Arg.(some ipv4_address) "ipv4-gateway"
end

module V6 = struct
  let network ?group default =
    let doc =
      Fmt.str "The network of %a specified as IPv6 address and prefix length."
        pp_group group
    in
    create_simple ~doc ~default ?group Arg.(some ipv6) "ipv6"

  let gateway ?group default =
    let doc = Fmt.str "The gateway of %a." pp_group group in
    create_simple ~doc ~default ?group Arg.(some ipv6_address) "ipv6-gateway"

  let accept_router_advertisements ?group () =
    let doc = Fmt.str "Accept router advertisements for %a." pp_group group in
    create_simple ~doc ?group ~default:true Arg.bool
      "accept-router-advertisements"
end

let ipv4_only ?group () =
  let doc = Fmt.str "Only use IPv4 for %a." pp_group group in
  create_simple ~doc ?group ~default:false Arg.bool "ipv4-only"

let ipv6_only ?group () =
  let doc = Fmt.str "Only use IPv6 for %a." pp_group group in
  create_simple ~doc ?group ~default:false Arg.bool "ipv6-only"

let resolver ?default () =
  let doc = Fmt.str "DNS resolver (default to anycast.censurfridns.dk)" in
  create_simple ~doc ~default Arg.(some ip_address) "resolver"

let resolver_port ?(default = 53) () =
  let doc = Fmt.str "DNS resolver port" in
  create_simple ~doc ~default Arg.int "resolver-port"

let syslog default =
  let doc = Fmt.str "syslog server" in
  create_simple ~doc ~default Arg.(some ip_address) "syslog"

let syslog_port default =
  let doc = Fmt.str "syslog server port" in
  create_simple ~doc ~default Arg.(some int) "syslog-port"

let syslog_hostname default =
  let doc = Fmt.str "hostname to report to syslog" in
  create_simple ~doc ~default Arg.string "syslog-hostname"

let pp_level ppf = function
  | Logs.Error -> Fmt.string ppf "Logs.Error"
  | Logs.Warning -> Fmt.string ppf "Logs.Warning"
  | Logs.Info -> Fmt.string ppf "Logs.Info"
  | Logs.Debug -> Fmt.string ppf "Logs.Debug"
  | Logs.App -> Fmt.string ppf "Logs.App"

let pp_pattern ppf = function
  | `All -> Fmt.string ppf "`All"
  | `Src s -> Fmt.pf ppf "`Src %S" s

let pp_threshold ppf (pattern, level) =
  Fmt.pf ppf "(%a,@ %a)" pp_pattern pattern pp_level level

let logs =
  let env = "MIRAGE_LOGS" in
  let docs = unikernel_section in
  let conv = Cmdliner.Arg.list Mirage_runtime.Arg.log_threshold in
  let serialize ppf levels =
    Fmt.(pf ppf "[%a]" (list ~sep:(const string "; ") pp_threshold) levels)
  in
  let runtime_conv = "(Cmdliner.Arg.list Mirage_runtime.Arg.log_threshold)" in
  let doc =
    strf
      "Be more or less verbose. $(docv) must be of the form@ \
       $(b,*:info,foo:debug) means that that the log threshold is set to@ \
       $(b,info) for every log sources but the $(b,foo) which is set to@ \
       $(b,debug)."
  in
  let logs = Key.Arg.conv ~conv ~serialize ~runtime_conv in
  let info = Key.Arg.info ~env ~docv:"LEVEL" ~doc ~docs [ "l"; "logs" ] in
  let arg = Key.Arg.(opt logs []) info in
  Key.create "logs" arg

include (Key : Functoria.KEY with module Arg := Arg and module Alias := Alias)
