open Functoria
module Key = Mirage_key
open Mirage_impl_misc

let flags i =
  let ctx = Info.context i in
  let warn_error = Key.(get ctx warn_error) in
  [
    "-g";
    "-w";
    "+A-4-41-42-44";
    "-bin-annot";
    "-strict-sequence";
    "-principal";
    "-safe-string";
  ]
  @ (if warn_error then [ "-warn-error"; "+1..49" ] else [])
  @ if terminal () then [ "-color"; "always" ] else []
