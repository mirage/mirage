open Printf
open Lwt
open Mpl_ethernet

let recv nf buf =
    (* Just a temporary copying fill function until the paging
       interface is in *)
    let envbuf = String.make 4096 '\000' in
    let fillfn targ off len =
       assert(String.length envbuf > (String.length buf));
       assert(off = 0);
       String.blit buf 0 envbuf off (String.length buf);
       String.length buf in

    let env = Mpl_stdlib.new_env ~fillfn envbuf in
    (try
        let ethernet = Ethernet.unmarshal env in
        match ethernet with
        |`ARP o ->
            Ethernet.ARP.prettyprint o
        |`IPv4 o ->
            Ethernet.IPv4.prettyprint o
        |_ -> printf "discarding non-IPv4/ARP ethernet frame"
    with exn -> printf "exn: %s\n%!" (Printexc.to_string exn));
    return ()
