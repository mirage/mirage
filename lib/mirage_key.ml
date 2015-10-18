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

  let ipv4 = builtin "ipv4" "Ipaddr.V4" (module Ipaddr.V4)
  let ipv6 = builtin "ipv6" "Ipaddr.V6" (module Ipaddr.V6)
  let ipv6_prefix =
    builtin "ipv6_prefix" "Ipaddr.V6.Prefix" (module Ipaddr.V6.Prefix)

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
  | `MacOSX
]

let target_conv: mode Cmdliner.Arg.converter =
  Cmdliner.Arg.enum [
    "unix"  , `Unix;
    "macosx", `MacOSX;
    "xen"   , `Xen
  ]

let pp_target fmt m = snd target_conv fmt m

let target =
  let doc =
    "Target platform to compile the unikernel for. Valid values are: \
     $(i,xen), $(i,unix), $(i,macosx)."
  in
  let serialize ppf = function
    | `Unix   -> Fmt.pf ppf "`Unix"
    | `Xen    -> Fmt.pf ppf "`Xen"
    | `MacOSX -> Fmt.pf ppf "`MacOSX"
  in
  let conv = Arg.conv ~conv:target_conv ~runtime_conv:"target" ~serialize in
  let doc =
    Arg.info ~docs:mirage_section ~docv:"TARGET" ~doc ["t";"target"] ~env:"MODE"
  in
  let key = Arg.opt ~stage:`Configure conv `Unix doc in
  Key.create "target" key

let is_xen =
  Key.match_ Key.(value target) @@ function
  | `Xen -> true
  | `Unix | `MacOSX -> false

let unix =
  let doc = "Set $(b,target) to $(i,unix)." in
  let doc = Arg.info ~docs:mirage_section ~docv:"BOOL" ~doc ["unix"] in
  let setter b = if b then Some `Unix else None in
  let alias = Alias.flag doc in
  let alias = Alias.add target setter alias in
  Key.alias "unix" alias

let xen =
  let doc = "Set $(b,target) to $(i,xen)." in
  let doc = Arg.info ~docs:mirage_section ~docv:"BOOL" ~doc ["xen"] in
  let setter b = if b then Some `Xen else None in
  let alias = Alias.flag doc in
  let alias = Alias.add target setter alias in
  Key.alias "xen" alias

(** {3 Tracing} *)

let tracing default =
  let doc = "The tracing level. Accepts an integer" in
  let doc = Arg.info ~docs:mirage_section ~docv:"TRACING" ~doc ["tracing"] in
  let key = Arg.opt ~stage:`Configure Arg.int default doc in
  Key.create "tracing" key

(** {2 General mirage keys} *)

let create_simple ?(group="") ?(stage=`Both) ~doc ~default conv name =
  let prefix = if group = "" then group else group^"-" in
  let doc =
    Arg.info ~docs:unikernel_section ~docv:(String.uppercase name) ~doc
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
      "crunch" , `Crunch ]
  in
  let serialize = Fmt.of_to_string @@ function
    | `Fat     -> "`Fat"
    | `Archive -> "`Archive"
    | `Crunch  -> "`Crunch"
  in
  let conv = Arg.conv ~conv ~serialize ~runtime_conv:"kv_ro" in
  let doc =
    Fmt.strf
      "Use a $(i,fat), $(i,archive) or $(i,crunch) implementation for %a."
      pp_group group
  in
  create_simple ~doc ?group ~stage:`Configure ~default:`Crunch conv "kv_ro"

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

let network ?group default =
  let doc = Fmt.strf "The network interface listened by %a." pp_group group in
  create_simple ~doc ~default ?group Arg.string "network"

module V4 = struct

  let ip ?group default =
    let doc = Fmt.strf "The ip address of %a." pp_group group in
    create_simple ~doc ~default ?group Arg.ipv4 "ip"

  let netmask ?group default =
    let doc = Fmt.strf "The netmask of %a." pp_group group in
    create_simple ~doc ~default ?group Arg.ipv4 "netmask"

  let gateways ?group default =
    let doc = Fmt.strf "The gateways of %a." pp_group group in
    create_simple ~doc ~default ?group Arg.(list ipv4) "gateways"

  let socket ?group default =
    let doc =
      Fmt.strf "The address bounds by the socket in %a." pp_group group
    in
    create_simple ~doc ~default ?group Arg.(some ipv4) "socket"

  let interfaces ?group default =
    let doc =
      Fmt.strf "The interfaces bound by the socket in %a." pp_group group
    in
    create_simple ~doc ~default ?group Arg.(list ipv4) "interfaces"

end

module V6 = struct

  let ip ?group default =
    let doc = Fmt.strf "The ip address of %a." pp_group group in
    create_simple ~doc ~default ?group Arg.ipv6 "ip"

  let netmask ?group default =
    let doc = Fmt.strf "The netmasks of %a." pp_group group in
    create_simple ~doc ~default ?group Arg.(list ipv6_prefix) "netmask"

  let gateways ?group default =
    let doc = Fmt.strf "The gateways of %a." pp_group group in
    create_simple ~doc ~default ?group Arg.(list ipv6) "gateways"

end

(* FIXME: this is a crazy *)
include (Key: module type of struct include Functoria_key end
         with module Arg := Arg and module Alias := Alias)
