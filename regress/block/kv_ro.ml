open Lwt
open Printf

let main () =
  printf "Plugging device\n%!";
  lwt kv_ro = OS.Devices.find_kv_ro "foo" >>=
    function
    |None -> raise_lwt (Failure "no kv_ro")
    |Some x -> return x
  in
  printf "Reading small file\n%!";
  lwt () =begin match_lwt kv_ro#read "bar" with
  |Some s ->
    printf "File contents:\n%!";
    Lwt_stream.iter (fun b ->
      printf "%s%!" (Bitstring.string_of_bitstring b);
    ) s
  |None ->
    printf "File not found\n%!";
    exit 1
  end in
  printf "Reading large file\n%!";
  begin match_lwt kv_ro#read "bar2" with
  |Some s ->
    lwt buf = Bitstring_stream.string_of_stream s in
    let len = String.length buf in
    printf "File size=%d\n%!" len;
    printf "Last 5 chars: %s\n%!" (String.sub buf (len-6) 5);
    return ()
  |None ->
    printf "File not found\n%!";
    exit 1
  end
