open Functoria
module Key = Mirage_key

let argv_unix = impl @@ object
    inherit [_] base_configurable
    method ty = Functoria_app.argv
    method name = "argv_unix"
    method module_name = "Bootvar"
    method! packages =
      Key.pure [ package ~min:"0.1.0" ~max:"0.2.0" "mirage-bootvar-unix" ]
    method! connect _ _ _ = "Bootvar.argv ()"
  end

let argv_solo5 = impl @@ object
    inherit [_] base_configurable
    method ty = Functoria_app.argv
    method name = "argv_solo5"
    method module_name = "Bootvar"
    method! packages =
      Key.pure [ package ~min:"0.6.0" ~max:"0.7.0" "mirage-bootvar-solo5" ]
    method! connect _ _ _ = "Bootvar.argv ()"
  end

let no_argv = impl @@ object
    inherit [_] base_configurable
    method ty = Functoria_app.argv
    method name = "argv_empty"
    method module_name = "Mirage_runtime"
    method! connect _ _ _ = "Lwt.return [|\"\"|]"
  end

let argv_xen = impl @@ object
    inherit [_] base_configurable
    method ty = Functoria_app.argv
    method name = "argv_xen"
    method module_name = "Bootvar"
    method! packages =
      Key.pure [ package ~min:"0.8.0" ~max:"0.9.0" "mirage-bootvar-xen" ]
    method! connect _ _ _ = "Bootvar.argv ()"
  end

let default_argv =
  match_impl Key.(value target) [
    `Xen, argv_xen;
    `Qubes, argv_xen;
    `Virtio, argv_solo5;
    `Hvt, argv_solo5;
    `Muen, argv_solo5;
    `Genode, argv_solo5;
    `Spt, argv_solo5
  ] ~default:argv_unix
