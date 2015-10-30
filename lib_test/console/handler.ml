open V1_LWT
open Lwt

module Main (C: CONSOLE) = struct

  let start c =
    C.log_s c "Hello Mirage World"
    >>= fun () ->
    let rec aux () =
      C.log_s c (Bootvar_gen.hello ())
      >>= fun () ->
      OS.Time.sleep 1.
      >>= aux
    in
    aux ()

  let stop c =
    return_unit

end
