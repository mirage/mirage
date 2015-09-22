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

open Cmdliner
module Key = Functoria_key
module C = Mirage_runtime.Converter

(** {2 Custom Descriptions} *)

module Desc = struct
  include Key.Desc

  module type S = sig
    include C.S
    val sexp_of_t : t -> Sexplib.Type.t
  end

  (* Could be improved with metaocaml and/or some reflection.
     [description] and [m] should not need to be provided.
  *)
  let of_module
      (type t) description m (module M:S with type t=t) =
    let converter = C.of_module (module M) in
    let serializer fmt x =
      Fmt.pf fmt "(%s.t_of_sexp (Sexplib.Sexp.of_string %S))"
      m (Sexplib.Sexp.to_string @@ M.sexp_of_t x)
    in
    create ~converter ~serializer ~description

  let from_run s = "Mirage_runtime.Converter." ^ s
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

let target_conv : mode Arg.converter = Arg.enum [ "unix", `Unix; "macosx", `MacOSX; "xen", `Xen ]

let pp_target fmt m = snd target_conv fmt m

let serialize_mode fmt = function
  | `Unix -> Fmt.pf fmt "`Unix"
  | `Xen  -> Fmt.pf fmt "`Xen"
  | `MacOSX -> Fmt.pf fmt "`MacOSX"

let target =
  let doc = "Target platform to compile the unikernel for. Valid values are: $(i,xen), $(i,unix), $(i,macosx)." in
  let desc = Key.Desc.create
      ~serializer:serialize_mode
      ~description:"target"
      ~converter:target_conv
  in
  let doc = Key.Doc.create
      ~docs:mirage_section
      ~docv:"TARGET" ~doc ["t";"target"]
  in
  Key.create ~doc ~stage:`Configure ~default:`Unix "target" desc

let is_xen =
  Key.pipe Key.(value target) @@ function
  | `Xen -> true
  | `Unix | `MacOSX -> false

(** {3 Tracing} *)

let tracing default =
  let doc = "The tracing level. Accepts an integer" in
  let desc = Key.Desc.int in
  let doc = Key.Doc.create
      ~docs:mirage_section
      ~docv:"TRACING" ~doc ["tracing"]
  in
  Key.create ~doc ~stage:`Configure ~default "tracing" desc

(** {2 General mirage keys} *)

let create_simple ?(group="") ?(stage=`Both) ~doc ~default desc name =
  let prefix = if group = "" then group else group^"-" in
  let doc = Key.Doc.create
      ~docs:unikernel_section
      ~docv:(String.uppercase name) ~doc [prefix^name]
  in
  Key.create ~doc ~stage ~default (prefix^name) desc

(** {3 File system keys} *)

let kv_ro ?group () =
  let converter =
    Arg.enum [ "fat", `Fat ; "archive", `Archive ; "crunch", `Crunch ]
  in
  let serializer = Fmt.of_to_string @@ function
    | `Fat -> "`Fat" | `Archive -> "`Archive" | `Crunch -> "`Crunch"
  in
  let desc = Key.Desc.create ~converter ~serializer ~description:"kv_ro" in
  let doc =
    Fmt.strf
      "Use a $(i,fat), $(i,archive) or $(i,crunch) implementation for %a."
      pp_group group
  in
  create_simple ~doc ?group ~stage:`Configure ~default:`Crunch desc "kv_ro"

(** {3 Stack keys} *)

let dhcp ?group () =
  let doc = Fmt.strf "Enable dhcp for %a." pp_group group in
  create_simple
    ~doc ?group ~stage:`Configure ~default:false Key.Desc.bool "dhcp"

let net ?group () : [`Socket | `Direct] Key.key =
  let converter = Arg.enum ["socket", `Socket ; "direct", `Direct] in
  let serializer fmt = function
    | `Socket -> Fmt.pf fmt "`Socket"
    | `Direct -> Fmt.pf fmt "`Direct"
  in
  let desc = Key.Desc.create
      ~converter ~serializer ~description:"net"
  in
  let doc =
    Fmt.strf "Use $(i,socket) or $(i,direct) group for %a." pp_group group
  in
  create_simple
    ~doc ?group ~stage:`Configure ~default:`Direct desc "net"

(** {3 Network keys} *)

let network ?group default =
  let doc =
    Fmt.strf "The network interface listened by %a."
      pp_group group
  in
  create_simple
    ~doc ~default ?group Desc.string "network"

module V4 = struct

  let ip ?group default =
    let doc = Fmt.strf "The ip address of %a." pp_group group in
    create_simple ~doc ~default ?group Desc.ipv4 "ip"

  let netmask ?group default =
    let doc = Fmt.strf "The netmask of %a." pp_group group in
    create_simple ~doc ~default ?group Desc.ipv4 "netmask"

  let gateways ?group default =
    let doc = Fmt.strf "The gateways of %a." pp_group group in
    create_simple ~doc ~default ?group Desc.(list ipv4) "gateways"

  let socket ?group default =
    let doc =
      Fmt.strf "The address bounds by the socket in %a." pp_group group in
    create_simple ~doc ~default ?group Desc.(option ipv4) "socket"

  let interfaces ?group default =
    let doc =
      Fmt.strf "The interfaces bound by the socket in %a." pp_group group in
    create_simple ~doc ~default ?group Desc.(list ipv4) "interfaces"

end

module V6 = struct

  let ip ?group default =
    let doc = Fmt.strf "The ip address of %a." pp_group group in
    create_simple ~doc ~default ?group Desc.ipv6 "ip"

  let netmask ?group default =
    let doc = Fmt.strf "The netmasks of %a." pp_group group in
    create_simple ~doc ~default ?group Desc.(list ipv6_prefix) "netmask"

  let gateways ?group default =
    let doc = Fmt.strf "The gateways of %a." pp_group group in
    create_simple ~doc ~default ?group Desc.(list ipv6) "gateways"

end

include (Key : Functoria.KEY with module Desc := Desc)
