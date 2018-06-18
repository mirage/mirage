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

module Key = Functoria_key
module Alias = Key.Alias
open Astring

(** {2 Custom Descriptions} *)

module Arg = struct
  include Key.Arg

  module type S = sig
    include Mirage_runtime.Arg.S
    val sexp_of_t : t -> Sexplib.Type.t
  end

  (* Could be improved with metaocaml and/or some reflection.
     [description] and [m] should not need to be provided.
  *)
  let of_module
      (type t) runtime_conv m (module M: S with type t=t) =
    let conv = Mirage_runtime.Arg.of_module (module M) in
    let serialize ppf x =
      Fmt.pf ppf "(%s.t_of_sexp (Sexplib.Sexp.of_string %S))"
        m (Sexplib.Sexp.to_string @@ M.sexp_of_t x)
    in
    Functoria_key.Arg.conv ~conv ~serialize ~runtime_conv

  let from_run s = "Mirage_runtime.Arg." ^ s
  let builtin d mn m = of_module (from_run d) mn m

  let ipv4_address = builtin "ipv4_address" "Ipaddr.V4" (module Ipaddr.V4)
  let ipv6 = builtin "ipv6" "Ipaddr.V6" (module Ipaddr.V6)
  let ipv6_prefix =
    builtin "ipv6_prefix" "Ipaddr.V6.Prefix" (module Ipaddr.V6.Prefix)

  let ipv4 =
    let serialize fmt (prefix, ip) =
      Format.fprintf fmt "(Ipaddr.V4.Prefix.of_address_string_exn \"%s\")"
      @@ Ipaddr.V4.Prefix.to_address_string prefix ip
    in
    let print fmt (prefix, ip) =
      Format.fprintf fmt "%s" @@ Ipaddr.V4.Prefix.to_address_string prefix ip
    in
    let parse str =
      match Ipaddr.V4.Prefix.of_address_string str with
      | None -> `Error (str ^ " is not a valid IPv4 address and netmask")
      | Some (network, ip) -> `Ok (network, ip)
    in
    let runtime_conv = "Mirage_runtime.Arg.ipv4"
    in
    Functoria_key.Arg.conv
      ~conv:(parse, print)
      ~serialize
      ~runtime_conv
end

(** {2 Documentation helper} *)

let mirage_section = "MIRAGE PARAMETERS"
let unikernel_section = "UNIKERNEL PARAMETERS"

let pp_group =
  Fmt.(option ~none:(unit "the unikernel") @@ fmt "the %s group")

(** {2 Special keys} *)

(** {3 Mode} *)

type mode = [
  | `Unix
  | `Xen
  | `Virtio
  | `Ukvm
  | `Muen
  | `MacOSX
  | `Qubes
]

let target_conv: mode Cmdliner.Arg.converter =
  Cmdliner.Arg.enum [
    "unix"  , `Unix;
    "macosx", `MacOSX;
    "xen"   , `Xen;
    "virtio", `Virtio;
    "ukvm"  , `Ukvm;
    "muen"  , `Muen;
    "qubes" , `Qubes
  ]

let pp_target fmt m = snd target_conv fmt m

let default_unix = lazy (
  let open Bos in
  let uname arg = OS.Cmd.(run_out (Cmd.(v "uname" % arg)) |> OS.Cmd.out_string) in
  match uname "-s" with
  | Ok ("Darwin", _) -> `MacOSX
  | _ -> `Unix
)

let target =
  let doc =
    "Target platform to compile the unikernel for. Valid values are: \
     $(i,xen), $(i,qubes), $(i,unix), $(i,macosx), $(i,virtio), $(i,ukvm), $(i,muen)."
  in
  let serialize ppf = function
    | `Unix   -> Fmt.pf ppf "`Unix"
    | `Xen    -> Fmt.pf ppf "`Xen"
    | `Virtio -> Fmt.pf ppf "`Virtio"
    | `Ukvm   -> Fmt.pf ppf "`Ukvm"
    | `Muen   -> Fmt.pf ppf "`Muen"
    | `MacOSX -> Fmt.pf ppf "`MacOSX"
    | `Qubes  -> Fmt.pf ppf "`Qubes"
  in
  let conv = Arg.conv ~conv:target_conv ~runtime_conv:"target" ~serialize in
  let doc =
    Arg.info ~docs:mirage_section ~docv:"TARGET" ~doc ["t";"target"] ~env:"MODE"
  in
  let default = Lazy.force default_unix in
  let key = Arg.opt ~stage:`Configure conv default doc in
  Key.create "target" key

let is_unix =
  Key.match_ Key.(value target) @@ function
  | `Unix | `MacOSX -> true
  | `Qubes | `Xen | `Virtio | `Ukvm | `Muen -> false

let warn_error =
  let doc = "Enable -warn-error when compiling OCaml sources." in
  let doc = Arg.info ~docs:mirage_section ~docv:"BOOL" ~doc ["warn-error"] in
  let key = Arg.(opt ~stage:`Configure bool false doc) in
  Key.create "warn_error" key

let target_debug =
  let doc = "Enables target-specific support for debugging. Supported \
             targets: ukvm (compiles ukvm-bin with GDB server support)." in
  let doc = Arg.info ~docs:mirage_section ~docv:"DEBUG" ~doc ["g"] in
  let key = Arg.flag ~stage:`Configure doc in
  Key.create "target_debug" key

(** {3 Tracing} *)

let tracing_size default =
  let doc = "The size of the trace ring buffer." in
  let doc = Arg.info ~docs:mirage_section ~docv:"SIZE" ~doc ["tracing-size"] in
  let key = Arg.opt ~stage:`Configure Arg.int default doc in
  Key.create "tracing_size" key

(** {2 General mirage keys} *)

let create_simple ?(group="") ?(stage=`Both) ~doc ~default conv name =
  let prefix = if group = "" then group else group^"-" in
  let doc =
    Arg.info ~docs:unikernel_section ~docv:(String.Ascii.uppercase name) ~doc
      [prefix ^ name]
  in
  let key = Arg.opt ~stage conv default doc in
  Key.create (prefix ^ name) key

(** {3 File system keys} *)

let kv_ro ?group () =
  let conv =
    Cmdliner.Arg.enum [
      "fat"    , `Fat ;
      "archive", `Archive ;
      "crunch" , `Crunch ;
      "direct" , `Direct
    ]
  in
  let serialize = Fmt.of_to_string @@ function
    | `Fat     -> "`Fat"
    | `Archive -> "`Archive"
    | `Crunch  -> "`Crunch"
    | `Direct  -> "`Direct"
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
    Cmdliner.Arg.enum [
      "xenstore", `XenstoreId;
      "file", `BlockFile;
      "ramdisk", `Ramdisk;
    ]
  in
  let serialize = Fmt.of_to_string @@ function
    | `XenstoreId -> "`XenstoreId"
    | `BlockFile -> "`BlockFile"
    | `Ramdisk   -> "`Ramdisk"
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
let prng ?group () =
  let conv =
    Cmdliner.Arg.enum [
      "stdlib"  , `Stdlib ;
      "nocrypto", `Nocrypto ;
      "fortuna" , `Nocrypto ;
    ]
  in
  let serialize = Fmt.of_to_string @@ function
    | `Stdlib   -> "`Stdlib"
    | `Nocrypto -> "`Nocrypto"
  in
  let conv = Arg.conv ~conv ~serialize ~runtime_conv:"prng" in
  let doc =
    Fmt.strf
      "Use a $(i,stdlib) or $(i,nocrypto) PRNG implementation for %a."
      pp_group group
  in
  create_simple ~doc ?group ~stage:`Configure ~default:`Stdlib conv "prng"

(** {3 Stack keys} *)

let dhcp ?group () =
  let doc = Fmt.strf "Enable dhcp for %a." pp_group group in
  create_simple
    ~doc ?group ~stage:`Configure ~default:false Arg.bool "dhcp"

let net ?group (): [`Socket | `Direct] Key.key =
  let conv = Cmdliner.Arg.enum ["socket", `Socket ; "direct", `Direct] in
  let serialize fmt = function
    | `Socket -> Fmt.pf fmt "`Socket"
    | `Direct -> Fmt.pf fmt "`Direct"
  in
  let conv = Arg.conv ~conv ~runtime_conv:"net" ~serialize in
  let doc =
    Fmt.strf "Use $(i,socket) or $(i,direct) group for %a." pp_group group
  in
  create_simple ~doc ?group ~stage:`Configure ~default:`Direct conv "net"

(** {3 Network keys} *)

let interface ?group default =
  let doc = Fmt.strf "The network interface listened by %a." pp_group group in
  create_simple ~doc ~default ?group Arg.string "interface"

module V4 = struct

  let network ?group default =
    let doc = Fmt.strf "The network of %a specified as an IP address and netmask, e.g. 192.168.0.1/16 ." pp_group group in
    create_simple ~doc ~default ?group Arg.ipv4 "ipv4"

  let gateway ?group default =
    let doc = Fmt.strf "The gateway of %a." pp_group group in
    create_simple ~doc ~default ?group Arg.(some ipv4_address) "ipv4-gateway"

  let socket ?group default =
    let doc =
      Fmt.strf "The address bounds by the socket in %a." pp_group group
    in
    create_simple ~doc ~default ?group Arg.(some ipv4_address) "socket"

  let interfaces ?group default =
    let doc =
      Fmt.strf "The interfaces bound by the socket in %a." pp_group group
    in
    create_simple ~doc ~default ?group Arg.(list ipv4_address) "interfaces"

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
  | Logs.Error    -> Fmt.string ppf "Logs.Error"
  | Logs.Warning  -> Fmt.string ppf "Logs.Warning"
  | Logs.Info     -> Fmt.string ppf "Logs.Info"
  | Logs.Debug    -> Fmt.string ppf "Logs.Debug"
  | Logs.App      -> Fmt.string ppf "Logs.App"

let pp_pattern ppf = function
  | `All   -> Fmt.string ppf "`All"
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
    strf "Be more or less verbose. $(docv) must be of the form@ \
          $(b,*:info,foo:debug) means that that the log threshold is set to@ \
          $(b,info) for every log sources but the $(b,foo) which is set to@ \
          $(b,debug)."
  in
  let logs = Key.Arg.conv ~conv ~serialize ~runtime_conv in
  let info = Key.Arg.info ~env ~docv:"LEVEL" ~doc ~docs ["l";"logs"] in
  let arg = Key.Arg.(opt logs []) info in
  Key.create "logs" arg

(* FIXME: this is a crazy *)
include (Key: module type of struct include Functoria_key end
         with module Arg := Arg and module Alias := Alias)
