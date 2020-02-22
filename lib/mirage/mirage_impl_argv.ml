open Functoria
module Key = Mirage_key

let ty = Functoria.argv

let argv_unix =
  let packages = [ package ~min:"0.1.0" ~max:"0.2.0" "mirage-bootvar-unix" ] in
  let connect _ _ _ = "Bootvar.argv ()" in
  impl ~packages ~connect "Bootvar" ty

let argv_solo5 =
  let packages = [ package ~min:"0.6.0" ~max:"0.7.0" "mirage-bootvar-solo5" ] in
  let connect _ _ _ = "Bootvar.argv ()" in
  impl ~packages ~connect "Bootvar" ty

let no_argv =
  let connect _ _ _ = "return [|\"\"|]" in
  impl ~connect "Mirage_runtime" ty

let argv_xen =
  let packages = [ package ~min:"0.7.0" ~max:"0.8.0" "mirage-bootvar-xen" ] in
  let connect _ _ _ =
    Fmt.strf
      (* Some hypervisor configurations try to pass some extra arguments.
       * They means well, but we can't do much with them,
       * and they cause Functoria to abort. *)
      "let filter (key, _) = List.mem key (List.map snd Key_gen.runtime_keys) \
       in@ Bootvar.argv ~filter ()"
  in
  impl ~packages ~connect "Bootvar" ty

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
