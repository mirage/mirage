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
open Nettypes

open Ofpacket
open Controller_event

open Hashtbl

type endhost = {
  ip : Net.Nettypes.ipv4_addr;
  port : int
}

type controller_state = {
  mutable dp_db :  (string, Channel.t) Hashtbl.t;
  mutable channel_dp : (endhost, string) Hashtbl.t;
  mutable datapath_join_cb : (controller_state -> string -> of_event -> unit) list;
  mutable datapath_leave_cb : (controller_state -> string -> of_event -> unit) list;
  mutable pkt_in_cb : (controller_state -> string -> of_event -> unit) list;
}

let register_cb controller event_type cb =
  match event_type with 
      1 -> controller.datapath_join_cb <- List.append controller.datapath_join_cb [cb]
    | 2 -> controller.datapath_leave_cb <- List.append controller.datapath_leave_cb [cb]
    | 3 -> controller.pkt_in_cb <-  List.append controller.pkt_in_cb [cb]
  

let process_of_packet controller_state (remote_addr, remote_port) of_pkt t = 
  match int_of_msg_code of_pkt.ty with
    (* Reply to a hello msg with a hello and a feature request *)
      0 -> Channel.write_bitstring t (BITSTRING{1:8; (int_of_msg_code of_pkt.ty ):8; 
                                                      8:16; (of_pkt.xid):32;
                                                 1:8;5:8;8:16;( Int32.of_int 0):32}); 
               Channel.flush t 
    (* Reply to echo requests *)
    | 2 -> Channel.write_bitstring t (BITSTRING{1:8; 3:8; 8:16; (of_pkt.xid):32});
                  Channel.flush t

    (* Generate a datapath join event *)
    | 6 ->  let get_datapathid = function 
          Features_resp (c,a) -> Int64.to_string c.datapath_id
        | _ ->  "" in
      let dpid = Datapath_join(get_datapathid of_pkt.data) in 
        if not (Hashtbl.mem controller_state.dp_db (get_datapathid of_pkt.data)) then
           (Hashtbl.add controller_state.dp_db (get_datapathid of_pkt.data) t;
            Hashtbl.add controller_state.channel_dp {ip = remote_addr; port = remote_port} 
              (get_datapathid of_pkt.data));
              List.iter (fun v -> v controller_state (get_datapathid of_pkt.data) dpid ) controller_state.datapath_join_cb;
        return ();

    (* Generate a pkt_in event *)
    | 10 -> let get_pkt_in = function 
          Packet_in (pkt_in,data) -> pkt_in.in_port, Bitstring.bitstring_of_string data
      in
      let port, data = get_pkt_in of_pkt.data in
(*        printf "received packet on port %d\n" (int_of_port port);
        if not (Hashtbl.mem controller_state.channel_dp  {ip = remote_addr; port = remote_port}) then
          printf "channel found on the hashtable\n";*) 
        let dpid = (Hashtbl.find controller_state.channel_dp {ip = remote_addr; port = remote_port}) in  
        let evnt = Pkt_in(port, data, dpid) in
          List.iter (fun v -> v controller_state dpid evnt) 
            controller_state.pkt_in_cb;
          return ();
    | _ -> OS.Console.log "New packet received"; return () 
    
 
let send_of_data controller dpid data = 
  let t = Hashtbl.find controller.dp_db dpid in
    return (Channel.write_bitstring t data >> Channel.flush t)

let get_data t len =
  match len with
      0 -> return Bitstring.empty_bitstring
    | _ -> let res = (Channel.read_some ~len:len t) in res



let listen mgr port init =
  let src = (None, port) in (* Listen on all interfaces *)
  (* Flow.listen mgr (`TCPv4 (src, controller)) *)

  (* Main controller method *)
  let controller  (remote_addr, remote_port) t =
    OS.Console.log( sprintf "Connection  from %s:%d "
                      (Net.Nettypes.ipv4_addr_to_string remote_addr) remote_port);
    let controller_st = {dp_db = Hashtbl.create 0 ; channel_dp =  Hashtbl.create 0; 
                         datapath_join_cb = []; 
                         datapath_leave_cb = []; pkt_in_cb = [] } in
      init controller_st;
    let rec echo () =
      try_lwt
        (* Parse firstly the header to see how much data we need to pull from them channel *)
        lwt res = Channel.read_some ~len:8 t in
    let buf = Bitstring.takebits 64 res in 
    let of_header = parse_of_header buf in
      lwt buf = get_data t (of_header.length - 8) in  
  let buf = Bitstring.concat [res; buf] in
  let of_pkt = parse_of buf in
    process_of_packet controller_st (remote_addr, remote_port) of_pkt t ; 
    echo ()
      with Nettypes.Closed -> return ()
                                in echo () 
                                     in
  Net.Channel.listen mgr (`TCPv4 (src, controller)) 
