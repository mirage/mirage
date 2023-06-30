open Cmdliner

let hello =
  let doc = Arg.info ~doc:"How to say hello." [ "hello" ] in
  let key = Arg.(value @@ opt string "Hello World!" doc) in
  Functoria_runtime.key key

let arg =
  let doc =
    Arg.info ~docs:"APPLICATION OPTIONS" ~doc:"A runtime argument." [ "arg" ]
  in
  let key = Arg.(value & opt string "-" doc) in
  Functoria_runtime.key key

module Make (_ : sig end) = struct
  let start () = Fmt.pr "Success: hello=%s arg=%s\n%!" (hello ()) (arg ())
end
