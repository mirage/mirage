(* Simple openflow controller that listens on port 6633 and replies with echo
* request on every pkt_in event *)

open Printf
open Lwt
open Openflow
open Openflow.Controller
open Openflow.Controller_event
open Openflow.Ofpacket

type mac_port = {
  addr:eaddr; 
  switch: dpid;
  port:port
}

type state = {
  mutable mac_cache : (eaddr, mac_port) Hashtbl.t;
  mutable dpid : (string) list
}

let data = {mac_cache = Hashtbl.create 0; dpid = []} 

let datapath_join_cb controller dpid evnt =
  let dp = 
    match evnt with
        Datapath_join c -> c
  in
    printf "registering dp %s\n" dp

let pkt_in_cb controller dpid evnt =
  let port, data, dp = 
    match evnt with
        Pkt_in (a, b, c) -> a, b, c
  in
    Controller.send_of_data controller dpid  (BITSTRING{1:8; 2:8; 8:16; (Int32.of_int 10):32});

let init_controller controller = 
  printf "test conroller register datapath cb\n";
  Controller.register_cb controller 1 datapath_join_cb;
  printf "test controller register pkt_in cb\n";
  Controller.register_cb controller 3 pkt_in_cb

let main () =
  lwt mgr, mgr_t = Net.Manager.create () in
let port = 6633 in 
  Controller.listen mgr port init_controller

let _ =
  OS.Main.run (main ()) 

