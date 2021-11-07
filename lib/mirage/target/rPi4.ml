open Functoria
module Key = Mirage_key

type t = [ `RPi4 ]

let cast = function #t as t -> t | _ -> invalid_arg "not a rpi4 target."

let build_packages =
  [ Functoria.package ~scope:`Switch ~build:true "gilbraltar"
  ; Functoria.package ~scope:`Switch ~build:true "gilbraltar-toolchain" ]

let runtime_packages target =
  match target with
  | `RPi4 -> [ Functoria.package "mirage-gilbraltar" ]
  | _ -> invalid_arg "It's not a RPi 4 target."

let packages target = build_packages @ runtime_packages target

let context_name i =
  let target = Info.get i Key.target in
  Fmt.str "mirage-%a" Key.pp_target target

let build_context ?build_dir:_ i =
  let profile_release = Dune.stanza "(profile release)" in
  let build_context =
    Dune.stanzaf
      {dune|
(context
 (default
  (name %s)
  (host default)
  (toolchain rpi4)
  (disable_dynamically_linked_foreign_archives true)))
|dune}
      (context_name i)
  in
  [ profile_release; build_context ]

let configure i =
  let target = Info.get i Key.target in
  match target with `RPi4 -> Action.ok () | _ -> assert false

let out i =
  let public_name =
    match Info.output i with None -> Info.name i | Some o -> o
  in
  public_name ^ ".elf"

let main info = Fpath.(base (rem_ext (Info.main info)))

let rename info =
  let out = out info in
  let main = Fpath.to_string (main info) in
  Dune.stanzaf
    {dune|
(rule
 (target %s)
 (enabled_if (= %%{context_name} "%s"))
 (deps %s.exe)
 (action
  (copy %s.exe %%{target})))
|dune}
    out (context_name info) main main

let alias_override info =
  Dune.stanzaf
    {dune|
(alias
 (name default)
 (enabled_if (= %%{context_name} "%s"))
 (deps (alias_rec all)))
|dune}
    (context_name info)

let main i =
  let libraries = Info.libraries i in
  let flags = Mirage_dune.flags i in
  let main = Fpath.(to_string (base (rem_ext (Info.main i)))) in
  Dune.stanzaf
    {dune|
(executable
 (enabled_if (= %%{context_name} "%s"))
 (name %s)
 (modes (native exe))
 (libraries %a)
 (link_flags %a -cclib "-z rpi4-abi=rpi4")
 (modules (:standard \ config)))
|dune}
    (context_name i) main
    (Dune.compact_list "libraries")
    libraries
    (Dune.compact_list "link_flags")
    flags

let dune info = [ main info; rename info; alias_override info ]

let install info =
  let out = out info in
  let open Fpath in
  Install.v ~bin:[ (v out, v out) ] ()
