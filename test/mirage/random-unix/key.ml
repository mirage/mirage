open Cmdliner

let opt =
  let doc = Arg.info ~doc:"An optional key." [ "opt" ] in
  Arg.(value & opt string "default" doc)

let opt_all =
  let doc = Arg.info ~doc:"All the optional keys." [ "opt-all" ] in
  Arg.(value & opt_all string [] doc)

let flag =
  let doc = Arg.info ~doc:"A flag." [ "flag" ] in
  Arg.(value & flag doc)

let required =
  let doc = Arg.info ~doc:"A required key." [ "required" ] in
  Arg.(required & opt (some string) None doc)
