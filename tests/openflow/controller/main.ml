(* Simple openflow controller that listens on port 6633 and replies
   with echo request on every packet_in event *)

open Lwt
let resolve t = Lwt.on_success t (fun _ -> ())

module OP = Openflow.Ofpacket
module OC = Openflow.Controller
module OE = OC.Event

let pp = Printf.printf
let sp = Printf.sprintf

(*
type mac_port = {
  addr: OP.eaddr; 
  switch: OP.datapath_id;
  port: OP.port;
}

type state = {
  mutable mac_cache: (OP.eaddr, mac_port) Hashtbl.t;
  mutable dpid: string list
}

let data = { mac_cache = Hashtbl.create 0; 
             dpid = [] 
           } 
*)

let datapath_join_cb controller dpid evt =
  let dp = 
    match evt with
      | OE.Datapath_join c -> c
      | _ -> invalid_arg "bogus datapath_join event match!"
  in
  pp "+ datapath:0x%012Lx\n" dp

let packet_in_cb controller dpid evt =
  OS.Console.log (sp "* dpid:0x%012Lx evt:%s" dpid (OE.string_of_event evt));
  resolve
    (OC.send_of_data
       controller dpid (BITSTRING{1:8; 2:8; 8:16; 10_l:32}))

let init controller = 
  pp "test controller register datapath cb\n";
  OC.register_cb controller OE.DATAPATH_JOIN datapath_join_cb;
  pp "test controller register packet_in cb\n";
  OC.register_cb controller OE.PACKET_IN packet_in_cb

let main () =
  lwt mgr, mgr_t = Net.Manager.create () in
  let port = 6633 in 
  let ip = None in (* Net.Nettypes.ipv4_addr_of_string "172.16.0.1" in *)
  OC.listen mgr ip port init

let _ =
  OS.Main.run (main ()) 

