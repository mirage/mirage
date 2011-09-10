open Lwt
open Printf

let main () =
  printf "Plugging device\n%!";
  lwt kv_ro = OS.Devices.find_kv_ro "foo" >>=
    function
    |None -> raise_lwt (Failure "no kv_ro")
    |Some x -> return x
  in
  printf "Reading file\n%!";
  match_lwt kv_ro#read "bar" with
  |Some s ->
    printf "File contents:\n%!";
    Lwt_stream.iter (fun b ->
      printf "%s%!" (Bitstring.string_of_bitstring b);
    ) s
  |None ->
    printf "File not found\n%!";
    return ()
