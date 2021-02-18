open Functoria
open Action.Infix
module Key = Mirage_key

let choose : Key.mode -> (module S.TARGET) = function
  | #Solo5.t -> (module Solo5)
  | #Unix.t -> (module Unix)

let packages target =
  let (module Target) = choose target in
  Target.(packages (cast target))

let install i =
  let target = Info.get i Key.target in
  let (module Target) = choose target in
  Target.install i

let link ~name i =
  let target = Info.get i Key.target in
  let (module Target) = choose target in
  Target.link ~name i

let configure i =
  let target = Info.get i Key.target in
  let (module Target) = choose target in
  Target.configure i

let configure_files i =
  let target = Info.get i Key.target in
  let (module Target) = choose target in
  Target.configure_files i

let build i =
  let target = Info.get i Key.target in
  let (module Target) = choose target in
  Target.build i

let result target =
  let (module Target) = choose target in
  Target.result

let dontlink target =
  let (module Target) = choose target in
  Target.dontlink

let ocamlbuild_tags target =
  let (module Target) = choose target in
  Target.ocamlbuild_tags

let clean i = Solo5.clean i >>= fun () -> Unix.clean i
