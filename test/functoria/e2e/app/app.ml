open Cmdliner

let arg =
  let doc =
    Arg.info ~docs:"APPLICATION OPTIONS" ~doc:"A runtime argument." [ "arg" ]
  in
  let key = Arg.(value & opt string "-" doc) in
  Functoria_runtime.key key

module Make (_ : sig end) = struct
  let start () =
    Fmt.pr "Success: vote=%s hello=%s arg=%s\n%!"
      Key_gen.(vote ())
      Key_gen.(hello ())
      (arg ())
end
