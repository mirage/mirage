open Functoria
module Key = Mirage_key

let main i = Fpath.(base (rem_ext (Info.main i)))

let files _ = []

let workspace _ = Action.ok []

let build _ = Action.ok ()

let dune i =
  let libraries = Info.libraries i in
  let flags = Mirage_dune.flags i in
  let public_name =
    match Info.output i with None -> Info.name i | Some o -> o
  in
  let main = Fpath.to_string (main i) in
  let package = Info.name i in
  let pp_list = Fmt.(list ~sep:(unit " ") string) in
  let dune =
    Dune.stanzaf
      {|
(executable
  (public_name %s)
  (name %s)
  (package %s)
  (promote (until-clean))
  (libraries %a)
  (link_flags (-thread))
  (modules (:standard \ config))
  (flags %a)
  (variants unix))
|}
      public_name main package pp_list libraries pp_list flags
  in
  Action.ok [ dune ]
