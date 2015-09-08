
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

  let ip = builtin "ip" "Ipaddr" (module Ipaddr)
  let ipv4 = builtin "ipv4" "Ipaddr.V4" (module Ipaddr.V4)
  let ipv6 = builtin "ipv6" "Ipaddr.V6" (module Ipaddr.V6)
  let ipv6_prefix =
    builtin "ipv6_prefix" "Ipaddr.V6.Prefix" (module Ipaddr.V6.Prefix)

end

(** {2 Documentation helper} *)

let mirage_section = "MIRAGE PARAMETERS"
let unikernel_section = "UNIKERNEL PARAMETERS"

let pp_stack =
  Fmt.(option ~none:(unit "the unikernel") @@ fmt "the %s stack")

(** {2 Special keys} *)

(** {3 Mode} *)

type mode = [
  | `Unix
  | `Xen
  | `MacOSX
]

let mode_conv : mode Arg.converter = Arg.enum [ "unix", `Unix; "macosx", `MacOSX; "xen", `Xen ]

let serialize_mode fmt = function
  | `Unix -> Fmt.pf fmt "`Unix"
  | `Xen  -> Fmt.pf fmt "`Xen"
  | `MacOSX -> Fmt.pf fmt "`MacOSX"

let target =
  let doc = "Target platform to compile the unikernel for.  Valid values are: $(i,xen), $(i,unix), $(i,macosx)." in
  let desc = Key.Desc.create
      ~serializer:serialize_mode
      ~description:"target"
      ~converter:mode_conv
  in
  let doc = Key.Doc.create
      ~docs:mirage_section
      ~docv:"TARGET" ~doc ["t";"target"]
  in
  Key.create_raw ~doc ~stage:`Configure ~default:`Unix "target" desc


(** {3 Tracing} *)

let tracing =
  let doc = "The tracing level. Tracing is disabled if none is given." in
  let desc = Key.Desc.(option int) in
  let doc = Key.Doc.create
      ~docs:mirage_section
      ~docv:"TRACING" ~doc ["tracing"]
  in
  Key.create_raw ~doc ~stage:`Configure ~default:None "tracing" desc

(** {2 General mirage keys} *)

let create_simple ?(stack="") ?(stage=`Both) ~doc ~default desc name =
  let prefix = if stack = "" then stack else stack^"-" in
  let doc = Key.Doc.create
      ~docs:unikernel_section
      ~docv:(String.uppercase name) ~doc [prefix^name]
  in
  Key.create_raw ~doc ~stage:`Both ~default (prefix^name) desc

let network ?stack default =
  let doc =
    Fmt.strf "The network interface listened by %a."
      pp_stack stack
  in
  create_simple
    ~doc ~default ?stack Desc.string "network"

module V4 = struct

  let address ?stack default =
    let doc = Fmt.strf "The ip address of %a." pp_stack stack in
    create_simple ~doc ~default ?stack Desc.ipv4 "ip"

  let netmask ?stack default =
    let doc = Fmt.strf "The netmask of %a." pp_stack stack in
    create_simple ~doc ~default ?stack Desc.ipv4 "ip"

  let gateways ?stack default =
    let doc = Fmt.strf "The gateways of %a." pp_stack stack in
    create_simple ~doc ~default ?stack Desc.(list ipv4) "ip"

  let socket ?stack default =
    let doc =
      Fmt.strf "The address bounds by the socket in %a." pp_stack stack in
    create_simple ~doc ~default ?stack Desc.(option ipv4) "socket"

  let interfaces ?stack default =
    let doc =
      Fmt.strf "The interfaces bound by the socket in %a." pp_stack stack in
    create_simple ~doc ~default ?stack Desc.(list ipv4) "interfaces"

end

module V6 = struct

  let address ?stack default =
    let doc = Fmt.strf "The ip address of %a." pp_stack stack in
    create_simple ~doc ~default ?stack Desc.ipv6 "ip"

  let netmask ?stack default =
    let doc = Fmt.strf "The netmasks of %a." pp_stack stack in
    create_simple ~doc ~default ?stack Desc.(list ipv6_prefix) "ip"

  let gateways ?stack default =
    let doc = Fmt.strf "The gateways of %a." pp_stack stack in
    create_simple ~doc ~default ?stack Desc.(list ipv6) "ip"

end

include
  (Key :
   (* This preserves type equalities with {!Functoria_key}. *)
   sig include module type of Key end
   with module Desc := Desc)
