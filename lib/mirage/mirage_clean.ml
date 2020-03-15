open Functoria
open Action.Infix
module Info = Functoria.Info

let clean_binary name suffix = Action.rm Fpath.(v name + suffix)

let clean i =
  let name = Info.name i in
  Mirage_configure_xen.clean_main_xl ~name ~ext:"xl" >>= fun () ->
  Mirage_configure_xen.clean_main_xl ~name ~ext:"xl.in" >>= fun () ->
  Mirage_configure_xen.clean_main_xe ~name >>= fun () ->
  Mirage_configure_libvirt.clean ~name >>= fun () ->
  Mirage_configure.clean_myocamlbuild () >>= fun () ->
  Mirage_configure_solo5.clean_manifest () >>= fun () ->
  Action.rm Fpath.(v "Makefile") >>= fun () ->
  Action.List.iter
    ~f:(Mirage_configure.clean_opam ~name)
    [ `Unix; `MacOSX; `Xen; `Qubes; `Hvt; `Spt; `Virtio; `Muen; `Genode ]
  >>= fun () ->
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
  Action.rm
    (Mirage_configure.opam_path
       ~name:(Mirage_configure.opam_name ~name ~target:"ukvm"))
  >>= fun () ->
  Action.rm Fpath.(v name + "ukvm") >>= fun () ->
  Action.rm Fpath.(v "Makefile.ukvm") >>= fun () ->
  Action.rmdir Fpath.(v "_build-ukvm") >>= fun () ->
  Action.rm Fpath.(v "ukvm-bin")
