open Functoria
open Action.Infix
module Info = Functoria.Info

let clean_binary name suffix = Action.rm Fpath.(v name + suffix)

let clean i =
  let name = Info.name i in
  Mirage_target.clean i >>= fun () ->
  Mirage_configure.clean_myocamlbuild () >>= fun () ->
  Action.rm Fpath.(v "main.native.o") >>= fun () ->
  Action.rm Fpath.(v "main.native") >>= fun () ->
  Action.rm Fpath.(v name) >>= fun () ->
  Action.List.iter ~f:(clean_binary name)
    [ "xen"; "elf"; "hvt"; "spt"; "virtio"; "muen"; "genode" ]
  >>= fun () ->
  (* The following deprecated names are kept here to allow "mirage clean" to
   * continue to work after an upgrade. *)
  Action.rm Fpath.(v "Makefile.solo5-hvt") >>= fun () ->
  Action.rmdir Fpath.(v "_build-solo5-hvt") >>= fun () ->
  Action.rm Fpath.(v "solo5-hvt") >>= fun () ->
  Action.rm Fpath.(v name + "ukvm") >>= fun () ->
  Action.rm Fpath.(v "Makefile.ukvm") >>= fun () ->
  Action.rmdir Fpath.(v "_build-ukvm") >>= fun () ->
  Action.rm Fpath.(v "ukvm-bin")
