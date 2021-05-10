open Functoria
module Key = Mirage_key

type t = [ `Unix | `MacOSX ]

let cast = function #t as t -> t | _ -> invalid_arg "not a unix target."

let packages _ = [ Functoria.package ~min:"4.0.1" ~max:"5.0.0" "mirage-unix" ]

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
 (action
  (copy %s.exe %%{target})))

(executable
 (name %s)
 (libraries %a)
 (link_flags (-thread))
 (modules (:standard \ config))
 (flags %a)
 (enabled_if (= %%{context_name} "default"))
)
|}
      public_name main main (pp_list "libraries") libraries (pp_list "flags")
      flags
  in
  [ dune ]

let install i =
  let public_name = public_name i in
  Install.v ~bin:[ Fpath.(v public_name, v public_name) ] ()
