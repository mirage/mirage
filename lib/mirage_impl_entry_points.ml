open Functoria

type entry_points = ENTRY_POINTS
let entry_points = Type ENTRY_POINTS

let entry_points_unix = impl @@ object
  inherit base_configurable
  method ty = entry_points
  val name = "entry-points-unix"
  method name = name
  method module_name = "Mirage_unix_main"
  method! packages =
    Mirage_key.pure
      [ package ~sublibs:[ "main" ] "mirage-unix" ]
end

let entry_points_solo5 = impl @@ object
  inherit base_configurable
  method ty = entry_points
  val name = "entry-points-solo5"
  method name = name
  method module_name = "Mirage_solo5_main"
  method! packages =
    Mirage_key.pure
      [ package ~sublibs:[ "main" ] "mirage-solo5" ]
end

let entry_points_xen = impl @@ object
  inherit base_configurable
  method ty = entry_points
  val name = "entry-points-xen"
  method name = name
  method module_name = "Mirage_xen_main"
  method! packages =
    Mirage_key.pure
      [ package ~sublibs:[ "main" ] "mirage-xen" ]
end

let default_entry_points =
  match_impl Mirage_key.(value target)
    [ `Xen,    entry_points_xen
    ; `Qubes,  entry_points_xen
    ; `Virtio, entry_points_solo5
    ; `Hvt,    entry_points_solo5
    ; `Spt,    entry_points_solo5
    ; `Muen,   entry_points_solo5
    ; `Genode, entry_points_solo5 ]
  ~default:entry_points_unix
