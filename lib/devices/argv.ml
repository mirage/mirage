open Functoria.DSL

let ty = Functoria.argv

let no_argv =
  let connect _ _ _ = code ~pos:__POS__ "return [|\"\"|]" in
  impl ~connect "Mirage_runtime" ty

let impl sublib =
  let packages =
    [
      package ~min:"1.0.0" ~max:"2.0.0" ~sublibs:[ ""; sublib ] "mirage-bootvar";
    ]
  in
  let connect _ _ _ = code ~pos:__POS__ "return (Mirage_bootvar.argv ())" in
  impl ~packages ~connect "Mirage_bootvar" ty

let argv_unix = impl "unix"
let argv_solo5 = impl "solo5"
let argv_xen = impl "xen"

let default_argv =
  match_impl
    Key.(value target)
    [
      (`Xen, argv_xen);
      (`Qubes, argv_xen);
      (`Virtio, argv_solo5);
      (`Hvt, argv_solo5);
      (`Muen, argv_solo5);
      (`Genode, argv_solo5);
      (`Spt, argv_solo5);
    ]
    ~default:argv_unix
