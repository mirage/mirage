open Functoria
open Action.Syntax
module Info = Functoria.Info

let clean_binary name suffix = Action.rm Fpath.(v name + suffix)

let clean i =
  let name = Info.name i in
  let* () = Mirage_target.clean i in
  let* () = Mirage_configure.clean_myocamlbuild () in
  let* () = Action.rm Fpath.(v "main.native.o") in
  let* () = Action.rm Fpath.(v "main.native") in
  let* () = Action.rm Fpath.(v name) in
  let* () =
    Action.List.iter ~f:(clean_binary name)
      [ "xen"; "elf"; "hvt"; "spt"; "virtio"; "muen"; "genode" ]
  in
  (* The following deprecated names are kept here to allow "mirage clean" to
   * continue to work after an upgrade. *)
  let* () = Action.rm Fpath.(v "Makefile.solo5-hvt") in
  let* () = Action.rmdir Fpath.(v "_build-solo5-hvt") in
  let* () = Action.rm Fpath.(v "solo5-hvt") in
  let* () = Action.rm Fpath.(v name + "ukvm") in
  let* () = Action.rm Fpath.(v "Makefile.ukvm") in
  let* () = Action.rmdir Fpath.(v "_build-ukvm") in
  Action.rm Fpath.(v "ukvm-bin")
