(*
 * Copyright (c) 2010 Anil Madhavapeddy <anil@recoil.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *)

open Lwt
open Lwip
open Printf

let host_ip = ( 128, 232, 39, 246 )
let host_netmask = ( 255, 255, 240, 0 )
let host_gw = ( 128, 232, 32, 1 )

let g () = Gc.compact()

let process_connection pcb =
    print_endline "process_connection: start";
    let rec read_and_echo () = 
       try_lwt
           g ();
           print_endline "ML read";
           lwt buf = TCP.read pcb in
           g ();
           print_endline "ML write";
           lwt wr = TCP.write pcb buf in
           g ();
           print_endline "ML loop";
           g ();
           read_and_echo ()
        with _ -> (print_endline "process_connection: closed"; return ())
    in
    read_and_echo ()
    
let lwip_main netif =
    let ip = ( 0, 0, 0, 0 ) in
    let pcb = TCP.bind ip 7 in
    print_endline "bind done";
    let listener = TCP.listen process_connection pcb in
    print_endline "listen done";
    Lwt.join (listener :: (Timer.start ()))

let _ = 
    lwip_init ();
    let netif = Netif.create ~ip:host_ip ~netmask:host_netmask ~gw:host_gw () in
    Lwt_mirage.run (lwip_main netif);
    Netif.close netif
