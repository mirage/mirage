open Rresult
open Mirage_impl_misc

module Info = Functoria.Info

let clean_binary name suffix =
  Bos.OS.File.delete Fpath.(v name + suffix)

let clean i =
  let name = Info.name i in
  Mirage_configure_xen.clean_main_xl ~name ~ext:"xl" >>= fun () ->
  Mirage_configure_xen.clean_main_xl ~name ~ext:"xl.in" >>= fun () ->
  Mirage_configure_xen.clean_main_xe ~name >>= fun () ->
  Mirage_configure_libvirt.clean ~name >>= fun () ->
  Mirage_configure.clean_myocamlbuild () >>= fun () ->
  Mirage_configure.clean_dune () >>= fun () ->
  Mirage_configure.clean_dune_workspace () >>= fun () ->
  Mirage_configure.clean_dune_project () >>= fun () ->
  Mirage_configure_solo5.clean_manifest () >>= fun () ->
  Bos.OS.File.delete Fpath.(v "Makefile") >>= fun () ->
  rr_iter (Mirage_configure.clean_opam ~name)
    [`Unix; `MacOSX; `Xen; `Qubes; `Hvt; `Spt; `Virtio; `Muen; `Genode]
  >>= fun () ->
  Bos.OS.File.delete Fpath.(v "main.native.o") >>= fun () ->
  Bos.OS.File.delete Fpath.(v "main.native") >>= fun () ->
  Bos.OS.File.delete Fpath.(v name) >>= fun () ->
  rr_iter (clean_binary name)
    ["xen"; "elf"; "hvt"; "spt"; "virtio"; "muen"; "genode"]
  >>= fun () ->
  (* The following deprecated names are kept here to allow "mirage clean" to
   * continue to work after an upgrade. *)
  Bos.OS.File.delete Fpath.(v "Makefile.solo5-hvt") >>= fun () ->
  Bos.OS.Dir.delete ~recurse:true Fpath.(v "_build-solo5-hvt") >>= fun () ->
  Bos.OS.File.delete Fpath.(v "solo5-hvt") >>= fun () ->
  Bos.OS.File.delete (Mirage_configure.opam_path ~name:(Mirage_configure.opam_name ~name ~target:"ukvm")) >>= fun () ->
  Bos.OS.File.delete Fpath.(v name + "ukvm") >>= fun () ->
  Bos.OS.File.delete Fpath.(v "Makefile.ukvm") >>= fun () ->
  Bos.OS.Dir.delete ~recurse:true Fpath.(v "_build-ukvm") >>= fun () ->
  Bos.OS.File.delete Fpath.(v "ukvm-bin")


