open Astring
module Key = F0.Key

let warn_error =
  let doc = "Enable -warn-error when compiling OCaml sources." in
  let doc = Key.Arg.info ~docv:"BOOL" ~doc ["warn-error"] in
  let key = Key.Arg.(opt ~stage:`Configure bool false doc) in
  Key.create "warn_error" key

let vote =
  let doc = "Vote." in
  let doc = Key.Arg.info ~docv:"VOTE" ~doc ["vote"] in
  let key = Key.Arg.(opt ~stage:`Configure string "cat" doc) in
  Key.create "vote" key

let test fmt =
  Fmt.kstrf (fun l ->
      let l = String.cuts ~sep:" " l in
      F0.run_with_argv (Array.of_list ("" :: l))
    ) fmt

let () = test "configure -f src/config.ml"
