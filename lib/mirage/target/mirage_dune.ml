open Functoria
module Key = Mirage_key
open Mirage_impl_misc

let flags i =
  let ctx = Info.context i in
  let warn_error = Key.(get ctx warn_error) in
  [
    "-g";
    "-bin-annot";
    "-strict-sequence";
    "-principal";
  ]
  @ (if warn_error then [ "-warn-error"; "-31" ] else [])
  @ if terminal () then [ "-color"; "always" ] else []
