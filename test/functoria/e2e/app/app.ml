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

let hello =
  let doc = Arg.info ~doc:"How to say hello." [ "hello" ] in
  let key = Arg.(value @@ opt string "Hello World!" doc) in
  Functoria_runtime.register key

let arg =
  let doc =
    Arg.info ~docs:"APPLICATION OPTIONS" ~doc:"A runtime argument." [ "arg" ]
  in
  let key = Arg.(value & opt string "-" doc) in
  Functoria_runtime.register key

module Make (_ : sig end) = struct
  let start () = Fmt.pr "Success: hello=%s arg=%s\n%!" (hello ()) (arg ())
end
