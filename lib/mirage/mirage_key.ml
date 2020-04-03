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
    and serialize ppf t =
      Fmt.pf ppf "(Ipaddr.%s.of_string_exn %S)" m (to_string t)
    and pp ppf t = Fmt.string ppf (to_string t) in
    Key.Arg.conv ~conv:(parser, pp) ~serialize ~runtime_conv:(from_run d)

  module type S = sig
    type t

    val of_string : string -> (t, [ `Msg of string ]) result

    val to_string : t -> string
  end

  let of_module (type t) d m (module M : S with type t = t) =
    make d m M.of_string M.to_string

  let ipv4_address = of_module "ipv4_address" "V4" (module Ipaddr.V4)

  let ipv4 =
    let serialize fmt (prefix, ip) =
      Format.fprintf fmt "(Ipaddr.V4.Prefix.of_address_string_exn %S)"
      @@ Ipaddr.V4.Prefix.to_address_string prefix ip
    in
    let print fmt (prefix, ip) =
      Format.fprintf fmt "%s" @@ Ipaddr.V4.Prefix.to_address_string prefix ip
    in
    let parse str =
      match Ipaddr.V4.Prefix.of_address_string str with
      | Error (`Msg m) ->
          `Error (str ^ " is not a valid IPv4 address and netmask: " ^ m)
      | Ok n -> `Ok n
    in
    let runtime_conv = "Mirage_runtime.Arg.ipv4" in
    Key.Arg.conv ~conv:(parse, print) ~serialize ~runtime_conv

  let ipv6 = of_module "ipv6" "V6" (module Ipaddr.V6)

  let ipv6_prefix = of_module "ipv6_prefix" "V6.Prefix" (module Ipaddr.V6.Prefix)
end

(** {2 Documentation helper} *)

let mirage_section = "MIRAGE PARAMETERS"

let unikernel_section = "UNIKERNEL PARAMETERS"

let pp_group = Fmt.(option ~none:(unit "the unikernel") @@ fmt "the %s group")

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

let target_conv : mode Cmdliner.Arg.converter =
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
          first_ukvm_mention := false );
        "hvt" )
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
      | _ -> `Unix )

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

(** {2 General mirage keys} *)

let create_simple ?(group = "") ?(stage = `Both) ~doc ~default conv name =
  let prefix = if group = "" then group else group ^ "-" in
  let doc =
    Arg.info ~docs:unikernel_section
      ~docv:(String.Ascii.uppercase name)
      ~doc [ prefix ^ name ]
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
    Fmt.strf
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
    Fmt.strf
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
    Fmt.strf
      "This boot parameter is deprecated. A Fortuna PRNG \
       (https://en.wikipedia.org/wiki/Fortuna_(PRNG)) will always be used. The \
       mirage-crypto-entropy (https://github.com/mirage/mirage-crypto) opam \
       package feeds entropy to Fortuna."
  in
  create_simple ~doc ~stage:`Configure ~default:`Stdlib conv "prng"

(** {3 Stack keys} *)

let dhcp ?group () =
  let doc = Fmt.strf "Enable dhcp for %a." pp_group group in
  create_simple ~doc ?group ~stage:`Configure ~default:false Arg.bool "dhcp"

let net ?group () : [ `Socket | `Direct ] option Key.key =
  let conv = Cmdliner.Arg.enum [ ("socket", `Socket); ("direct", `Direct) ] in
  let serialize fmt = function
    | `Socket -> Fmt.string fmt "`Socket"
    | `Direct -> Fmt.string fmt "`Direct"
  in
  let conv = Arg.conv ~conv ~runtime_conv:"net" ~serialize in
  let doc =
    Fmt.strf "Use $(i,socket) or $(i,direct) group for %a." pp_group group
  in
  create_simple ~doc ?group ~stage:`Configure ~default:None (Arg.some conv)
    "net"

(** {3 Network keys} *)

let interface ?group default =
  let doc = Fmt.strf "The network interface listened by %a." pp_group group in
  create_simple ~doc ~default ?group Arg.string "interface"

module V4 = struct
  let network ?group default =
    let doc =
      Fmt.strf
        "The network of %a specified as an IP address and netmask, e.g. \
         192.168.0.1/16 ."
        pp_group group
    in
    create_simple ~doc ~default ?group Arg.ipv4 "ipv4"

  let gateway ?group default =
    let doc = Fmt.strf "The gateway of %a." pp_group group in
    create_simple ~doc ~default ?group Arg.(some ipv4_address) "ipv4-gateway"

  let socket ?group default =
    let doc =
      Fmt.strf "The IPv4 address bound by the socket in %a." pp_group group
    in
    create_simple ~doc ~default ?group Arg.(some ipv4_address) "socket"

  let ips ?group default =
    let doc =
      Fmt.strf "The IPv4 addresses bound by the socket in %a." pp_group group
    in
    create_simple ~doc ~default ?group Arg.(list ipv4_address) "ips"
end

module V6 = struct
  let ips ?group default =
    let doc = Fmt.strf "The ip addresses of %a." pp_group group in
    create_simple ~doc ~default ?group Arg.(list ipv6) "ips"

  let netmasks ?group default =
    let doc = Fmt.strf "The netmasks of %a." pp_group group in
    create_simple ~doc ~default ?group Arg.(list ipv6_prefix) "netmasks"

  let gateways ?group default =
    let doc = Fmt.strf "The gateways of %a." pp_group group in
    create_simple ~doc ~default ?group Arg.(list ipv6) "gateways"
end

let resolver ?(default = Ipaddr.V4.of_string_exn "91.239.100.100") () =
  let doc = Fmt.strf "DNS resolver (default to anycast.censurfridns.dk)" in
  create_simple ~doc ~default Arg.ipv4_address "resolver"

let resolver_port ?(default = 53) () =
  let doc = Fmt.strf "DNS resolver port" in
  create_simple ~doc ~default Arg.int "resolver-port"

let syslog default =
  let doc = Fmt.strf "syslog server" in
  create_simple ~doc ~default Arg.(some ipv4_address) "syslog"

let syslog_port default =
  let doc = Fmt.strf "syslog server port" in
  create_simple ~doc ~default Arg.(some int) "syslog-port"

let syslog_hostname default =
  let doc = Fmt.strf "hostname to report to syslog" in
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
