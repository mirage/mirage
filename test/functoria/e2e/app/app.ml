let arg_t =
  Cmdliner.Arg.(
    value
      (opt string "-"
         (info ~docs:"APPLICATION OPTIONS" ~doc:"A runtime argument." [ "arg" ])))

let arg = Functoria_runtime.Key.register arg_t

module Make (_ : sig end) = struct
  let start () =
    Fmt.pr "Success: vote=%s hello=%s arg=%s\n%!"
      Key_gen.(vote ())
      Key_gen.(hello ())
      (arg ())
end
