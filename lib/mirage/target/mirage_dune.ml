open Mirage_impl_misc

let flags _ =
  (* Disable "70 [missing-mli] Missing interface file." as we are only
     generating .ml files currently. *)
  [ ":standard"; "-w"; "-70" ]
  @ if terminal () then [ "-color"; "always" ] else []
