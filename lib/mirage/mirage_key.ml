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
open Astring

(** {2 Custom Descriptions} *)

module Arg = struct
  include Key.Arg

  let from_run s =
    Fmt.str "@[<2>(Functoria_runtime.Key.conv@ %s.of_string@ %s.to_string)@]" s
      s

  let make m of_string to_string =
    let parser s =
      match of_string s with
      | Error (`Msg m) -> `Error ("Can't parse ip address: " ^ s ^ ": " ^ m)
      | Ok ip -> `Ok ip
    and serialize ppf t = Fmt.pf ppf "(%s.of_string_exn %S)" m (to_string t)
    and pp ppf t = Fmt.string ppf (to_string t) in
    Key.Arg.conv ~conv:(parser, pp) ~serialize ~runtime_conv:(from_run m)

  module type S = sig
    type t

    val of_string : string -> (t, [ `Msg of string ]) result
    val to_string : t -> string
  end

  let of_module (type t) m (module M : S with type t = t) =
    make m M.of_string M.to_string

  let ipv4_address = of_module "Ipaddr.V4" (module Ipaddr.V4)
  let ipv4 = of_module "Ipaddr.V4.Prefix" (module Ipaddr.V4.Prefix)
  let ipv6_address = of_module "Ipaddr.V6" (module Ipaddr.V6)
  let ipv6 = of_module "Ipaddr.V6.Prefix" (module Ipaddr.V6.Prefix)
  let ip_address = of_module "Ipaddr" (module Ipaddr)
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
  (parser, printer)

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
  let key = Arg.opt conv default_target doc in
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

(** {2 General mirage keys} *)

let configure_key ?(group = "") ~doc ~default conv name =
  let prefix = if group = "" then group else group ^ "-" in
  let doc =
    Arg.info ~docs:unikernel_section
      ~docv:(String.Ascii.uppercase name)
      ~doc
      [ prefix ^ name ]
  in
  let key = Arg.opt conv default doc in
  Key.create (prefix ^ name) key

(** {3 File system keys} *)

let kv_ro ?group () =
  let conv = Cmdliner.Arg.enum [ ("crunch", `Crunch); ("direct", `Direct) ] in
  let serialize =
    Fmt.of_to_string @@ function `Crunch -> "`Crunch" | `Direct -> "`Direct"
  in
  let conv = Arg.conv ~conv ~serialize ~runtime_conv:"kv_ro" in
  let doc =
    Fmt.str
      "Use a $(i,crunch) or $(i,direct) pass-through implementation for %a."
      pp_group group
  in
  configure_key ~doc ?group ~default:`Crunch conv "kv_ro"

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
  configure_key ~doc ?group ~default:`Ramdisk conv "block"

(** {3 Stack keys} *)

let dhcp ?group () =
  let doc = Fmt.str "Enable dhcp for %a." pp_group group in
  configure_key ~doc ?group ~default:false Arg.bool "dhcp"

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
  configure_key ~doc ?group ~default:None (Arg.some conv) "net"

include (Key : Functoria.KEY with module Arg := Arg)
