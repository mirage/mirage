open Mirage_types.V1
open Lwt

module Main (C: CONSOLE) (F: FS) = struct

  let start c fs =
    F.listdir fs "/" >>= function
    | `Ok s    -> C.log_s c (String.concat " " s)
    | `Error e -> C.log_s c "error"

end
