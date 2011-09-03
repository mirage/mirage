(* Simple openflow controller that listens on port 6633 and replies
   with echo request on every packet_in event *)

open Lwt
open Printf
let resolve t = Lwt.on_success t (fun _ -> ())

module OP = Openflow.Ofpacket
module OC = Openflow.Controller
module OE = OC.Event

let pp = Printf.printf
let sp = Printf.sprintf

(* TODO this the mapping is incorrect. the datapath must be moved to the key
*  of the hashtbl *)

let datapath_join_cb controller dpid evt =
  let dp = 
    match evt with
      | OE.Datapath_join c -> c
      | _ -> invalid_arg "bogus datapath_join event match!"
  in
  pp "+ datapath:0x%012Lx\n" dp;
  let flow_match = (OP.Match.create_flow_match (OP.Wildcards.l2_match) ~in_port:1 
                    ~dl_src:"\x11\x11\x11\x11\x11\x11" ~dl_dst:"\x22\x22\x22\x22\x22\x22" 
                    ~dl_type:0x0800  ()) in 
  let pkt = (OP.Flow_mod.create flow_match (Int64.of_int 0) OP.Flow_mod.ADD ~hard_timeout:10  
               ~flags:{OP.Flow_mod.send_flow_rem=true;emerg=false;overlap=false;} [| |] () )
  in 
    resolve(OC.send_of_data controller dpid (OP.Flow_mod.flow_mod_to_bitstring pkt))

let flow_removed_cb controller dpid evt =
  OS.Console.log (sp "* dpid:0x%012Lx evt:%s" dpid (OE.string_of_event evt));
  let (flow, reason, duration_sec, duration_usec, packet_count, byte_count, dpid) = 
    match evt with
      | OE.Flow_removed (flow, reason, duration_sec, duration_usec, packet_count, byte_count, dpid) -> 
          (flow, reason, duration_sec, duration_usec, packet_count, byte_count, dpid)
      | _ -> invalid_arg "bogus flow_removed event match!"
  in
    let pkt = (OP.Flow_mod.create flow (Int64.of_int 0) OP.Flow_mod.ADD 
                 ~flags:{OP.Flow_mod.send_flow_rem=true;emerg=false;overlap=false;}                 
                 ~hard_timeout:10 [| |] () ) in 
      resolve(OC.send_of_data controller dpid
      (OP.Flow_mod.flow_mod_to_bitstring pkt)); 
    pp "flow_removed received\n"

let init controller = 
  pp "test controller register datapath cb\n";
  OC.register_cb controller OE.DATAPATH_JOIN datapath_join_cb;
  pp "test controller register packet_in cb\n";
  OC.register_cb controller OE.FLOW_REMOVED flow_removed_cb

let main () =
  lwt mgr, mgr_t = Net.Manager.create () in
  let port = 6633 in 
  let ip = None in (* Net.Nettypes.ipv4_addr_of_string "172.16.0.1" in *)
  OC.listen mgr ip port init

let _ =
  OS.Main.run (main ()) 

