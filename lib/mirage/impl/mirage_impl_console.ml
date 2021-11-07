open Functoria
module Key = Mirage_key

type console = CONSOLE

let console = Type.v CONSOLE
let connect str _ m _ = Fmt.str "%s.connect %S" m str

let console_unix str =
  let packages = [ package ~min:"4.0.0" ~max:"5.0.0" "mirage-console-unix" ] in
  impl ~packages ~connect:(connect str) "Console_unix" console

let console_xen str =
  let packages = [ package ~min:"4.0.0" ~max:"5.0.0" "mirage-console-xen" ] in
  impl ~packages ~connect:(connect str) "Console_xen" console

let console_solo5 str =
  let packages = [ package ~min:"0.6.1" ~max:"0.7.0" "mirage-console-solo5" ] in
  impl ~packages ~connect:(connect str) "Console_solo5" console

let console_rpi4 =
  let packages = [ package "mirage-console-gilbraltar" ] in
  let connect _ modname _ = Fmt.str "%s.connect ()" modname in
  impl ~packages ~connect "Console_gilbraltar" console

let custom_console str =
  match_impl
    Key.(value target)
    [
      (`Xen, console_xen str);
      (`Qubes, console_xen str);
      (`Virtio, console_solo5 str);
      (`Hvt, console_solo5 str);
      (`Spt, console_solo5 str);
      (`Muen, console_solo5 str);
      (`Genode, console_solo5 str);
      (`RPi4, console_rpi4);
    ]
    ~default:(console_unix str)

let default_console = custom_console "0"
