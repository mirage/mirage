(* Simple echo server that listens on 8081 and sends back everything it reads *)

open Printf
open Lwt
(* open Openflow *)

let port = 6633

let datapath_join_cb controller dpid =
	printf "Datapath %s joined\n" dpid 

let main () =
  lwt mgr, mgr_t = Net.Manager.create () in
  Openflow.Controller.listen mgr port

let _ =
  OS.Main.run (main ())

