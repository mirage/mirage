open Functoria
module Key = Mirage_key

let choose : Key.mode -> (module S.TARGET) = function
  | #Solo5.t -> (module Solo5)
  | #Unix.t -> (module Unix)

let dune i =
  let target = Info.get i Key.target in
  let (module Target) = choose target in
  Target.dune i

let configure i =
  let target = Info.get i Key.target in
  let (module Target) = choose target in
  Target.configure i

let build_context ?build_dir i =
  let target = Info.get i Key.target in
  let (module Target) = choose target in
  Target.build_context ?build_dir i

let context_name i =
  let target = Info.get i Key.target in
  let (module Target) = choose target in
  Target.context_name i

let packages target =
  let (module Target) = choose target in
  Target.(packages (cast target))

let install i =
  let target = Info.get i Key.target in
  let (module Target) = choose target in
  Target.install i
