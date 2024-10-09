open Functoria.DSL

type timer = job

let timer = Functoria.job
let no_timer = impl "Mirage_runtime" timer

let impl sublib =
  let packages =
    [ package ~min:"1.0.0" ~max:"2.0.0" ~sublibs:[ ""; sublib ] "mirage-timer" ]
  in
  impl ~packages "Mirage_timer" timer

let timer_unix = impl "unix"
let timer_solo5 = impl "solo5"
let timer_xen = impl "xen"

let default_timer =
  match_impl
    Key.(value target)
    [
      (`Unix, timer_unix);
      (`MacOSX, timer_unix);
      (`Xen, timer_xen);
      (`Qubes, timer_xen);
      (`Virtio, timer_solo5);
      (`Hvt, timer_solo5);
      (`Spt, timer_solo5);
      (`Muen, timer_solo5);
      (`Genode, timer_solo5);
    ]
    ~default:timer_unix
