(* 
 * Copyright (c) 2005-2011 Charalampos Rotsos <cr409@cl.cam.ac.uk>
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
open Printf
open Net
open Ofpacket

let process_of_packet of_pkt t = 
  match of_pkt.ty with
    hello ->  OS.Console.log "hello packet received";
              Channel.write_bitstring t (BITSTRING{(int_of_char of_pkt.version):8; 
                                                  (int_of_msg_code of_pkt.ty):8; 
                                                  (of_pkt.length):16; (of_pkt.xid):32});
             Channel.flush t
    | _ -> OS.Console.log "New packet received"; return ()
    

let get_data t len =
  match len with
      0 -> Bitstring.empty_bitstring
    | _ -> let res = (Channel.read_some ~len:len t) in res

let controller  (remote_addr, remote_port) t =
  OS.Console.log( sprintf "Connection  from %s:%d "
                    (Net.Nettypes.ipv4_addr_to_string remote_addr) remote_port);

  let rec echo () =
    try_lwt
      (* Parse firstly the header to see how much data we need to pull from them channel *)
      lwt res = Channel.read_some ~len:8 t in
        let buf = Bitstring.takebits 64 res in 
          let of_header = parse_of_header buf in
            OS.Console.log( Printf.sprintf "v:%d l:%d x:%ld "
                              (int_of_char of_header.version)  of_header.length of_header.xid 
            );
            OS.Console.log ( sprintf "receiving packet %d" (of_header.length - 8));
             let buf = get_data t (of_header.length - 8) in  
(*
               match (of_header.length - 8) with
                   0 -> Bitstring.empty_bitstring
                 | _ -> ( Channel.read_some ~len:(of_header.length - 8) t) in
 *)
                OS.Console.log "received packet";
                 let buf = Bitstring.concat [res; buf] in 
                  let of_pkt = parse_of buf in
                  process_of_packet of_pkt t ;
                  echo ()
      with Nettypes.Closed -> return ()
                                in echo () 


let listen mgr port =
  let src = (None, port) in (* Listen on all interfaces *)
    (* Flow.listen mgr (`TCPv4 (src, controller)) *)
    Net.Channel.listen mgr (`TCPv4 (src, controller)) 
