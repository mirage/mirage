open Cmdliner

let hello_t =
  let doc = Arg.info ~doc:"How to say hello." [ "hello" ] in
  Arg.(value @@ opt string "Hello World!" doc)

let hello = Functoria_runtime.Key.register hello_t

let arg_t =
  let doc =
    Arg.info ~docs:"APPLICATION OPTIONS" ~doc:"A runtime argument." [ "arg" ]
  in
  Arg.(value @@ opt string "-" doc)

let arg = Functoria_runtime.Key.register arg_t

module Make (_ : sig end) = struct
  let start () = Fmt.pr "Success: hello=%s arg=%s\n%!" (hello ()) (arg ())
end
