open Lwt

module Main (C: V1_LWT.CONSOLE) (F: V1_LWT.FS) = struct

  let start c fs =
    F.listdir fs "/" >>= function
    | `Ok s    -> C.log_s c (String.concat " " s)
    | `Error e -> C.log_s c "error"

end
