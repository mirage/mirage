open Functoria.DSL

type time = TIME

let time = typ TIME

let default_time =
  let unix_time =
    impl
      ~packages:
        [ package ~min:"4.0.0" ~max:"5.0.0" ~sublibs:[ "unix" ] "mirage-time" ]
      "Mirage_time" time
  in
  let solo5_time =
    impl
      ~packages:
        [ package ~min:"4.0.0" ~max:"5.0.0" ~sublibs:[ "solo5" ] "mirage-time" ]
      "Mirage_time" time
  in
  match_impl
    Key.(value target)
    [
      (`Unix, unix_time);
      (`MacOSX, unix_time);
      (`Xen, solo5_time);
      (`Qubes, solo5_time);
      (`Virtio, solo5_time);
      (`Hvt, solo5_time);
      (`Spt, solo5_time);
      (`Muen, solo5_time);
      (`Genode, solo5_time);
    ]
    ~default:unix_time
