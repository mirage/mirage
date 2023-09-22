open Functoria
module Key = Mirage_key

type t = [ `Unix | `MacOSX ]

let cast = function #t as t -> t | _ -> invalid_arg "not a unix target."
let packages _ = [ Functoria.package ~min:"5.0.0" ~max:"6.0.0" "mirage-unix" ]

(*Mirage unix is built on the host build context.*)
let build_context ?build_dir:_ _ = []
let context_name _ = "default"
let configure _ = Action.ok ()
let main i = Fpath.(base (rem_ext (Info.main i)))
let public_name i = match Info.output i with None -> Info.name i | Some o -> o

let dune i =
  let libraries = Info.libraries i in
  let flags = Mirage_dune.flags i in
  let public_name = public_name i in
  let main = Fpath.to_string (main i) in
  let pp_list f = Dune.compact_list f in
  let dune =
    Dune.stanzaf
      {|
(rule
 (target %s)
 (enabled_if (= %%{context_name} "default"))
 (deps %s.exe)
 (action
  (copy %s.exe %%{target})))

(executable
 (name %s)
 (libraries %a)
 (link_flags (-thread))
 (modules (:standard \ %a))
 (flags %a)
 (enabled_if (= %%{context_name} "default"))
)
|}
      public_name main main main (pp_list "libraries") libraries Fpath.pp
      (Fpath.rem_ext (Fpath.base (Info.config_file i)))
      (pp_list "flags") flags
  in
  [ dune ]

let install i =
  let public_name = public_name i in
  Install.v ~bin:[ Fpath.(v public_name, v public_name) ] ()
