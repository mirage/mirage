open Mirage_types.V1

(* XXX: we don't have yet NET types in mirage-types *)
module type MANAGER = module type of Net.Manager

module Main (C: CONSOLE) (M: MANAGER) = struct

  let start c ip =
    ip (fun ip ->
        while_lwt true do
          C.log c "Still alive!";
          OS.Time.sleep 1.
        done)

end
