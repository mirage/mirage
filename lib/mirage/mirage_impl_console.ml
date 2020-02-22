open Functoria
module Key = Mirage_key

type console = CONSOLE

let console = Type.v CONSOLE

let connect str _ m _ = Fmt.strf "%s.connect %S" m str

let console_unix str =
  let packages = [ package ~min:"3.0.0" ~max:"4.0.0" "mirage-console-unix" ] in
  impl ~packages ~connect:(connect str) "Console_unix" console

let console_xen str =
  let packages = [ package ~min:"3.0.0" ~max:"4.0.0" "mirage-console-xen" ] in
  impl ~packages ~connect:(connect str) "Console_xen" console

let console_solo5 str =
  let packages = [ package ~min:"0.6.1" ~max:"0.7.0" "mirage-console-solo5" ] in
  impl ~packages ~connect:(connect str) "Console_solo5" console

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
    ]
    ~default:(console_unix str)

let default_console = custom_console "0"
