open Functoria
module Name = Functoria_app.Name
module Key = Mirage_key

type console = CONSOLE
let console = Type CONSOLE

let console_unix str = impl @@ object
    inherit base_configurable
    method ty = console
    val name = Name.ocamlify @@ "console_unix_" ^ str
    method name = name
    method module_name = "Console_unix"
    method! packages = Key.pure [ package ~min:"2.2.0" "mirage-console-unix" ]
    method! connect _ modname _args = Fmt.strf "%s.connect %S" modname str
  end

let console_xen str = impl @@ object
    inherit base_configurable
    method ty = console
    val name = Name.ocamlify @@ "console_xen_" ^ str
    method name = name
    method module_name = "Console_xen"
    method! packages = Key.pure [ package ~min:"2.2.0" "mirage-console-xen" ]
    method! connect _ modname _args = Fmt.strf "%s.connect %S" modname str
  end

let console_solo5 str = impl @@ object
    inherit base_configurable
    method ty = console
    val name = Name.ocamlify @@ "console_solo5_" ^ str
    method name = name
    method module_name = "Console_solo5"
    method! packages = Key.pure [ package ~min:"0.3.0" "mirage-console-solo5" ]
    method! connect _ modname _args = Fmt.strf "%s.connect %S" modname str
  end

let custom_console str =
  match_impl Key.(value target) [
    `Xen, console_xen str;
    `Qubes, console_xen str;
    `Virtio, console_solo5 str;
    `Hvt, console_solo5 str;
    `Muen, console_solo5 str
  ] ~default:(console_unix str)

let default_console = custom_console "0"
