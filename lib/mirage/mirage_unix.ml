open Functoria
module Key = Mirage_key

let main i = Fpath.(base (rem_ext (Info.main i)))

let workspace _ = []

let configure _ = Action.ok ()

let dune ~name i =
  let libraries = Info.libraries i in
  let flags = Mirage_dune.flags i in
  let public_name =
    match Info.output i with None -> Info.name i | Some o -> o
  in
  let main = Fpath.to_string (main i) in
  let package = Info.name i in
  let pp_list f = Dune.compact_list f in
  let dune =
    Dune.stanzaf
      {|
(indir %s
 (copy_files# ../**)
 (executable
  (public_name %s)
  (name %s)
  (package %s)
  (libraries %a)
  (link_flags (-thread))
  (modules (:standard \ config))
  (flags %a)))
|}
      name public_name main package (pp_list "libraries") libraries
      (pp_list "flags") flags
  in
  [ dune ]
