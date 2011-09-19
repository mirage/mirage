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
  for flow = 0 to 10 do
    let flow_match = (OP.Match.create_flow_match (OP.Wildcards.l3_match) ~in_port:1 
    ~dl_src:"\x11\x11\x11\x11\x11\x11" 
    ~dl_dst:"\x22\x22\x22\x22\x22\x22" 
    ~dl_type:0x0800 ~nw_src:(Int32.of_int 0x0a010001) 
    ~nw_dst:(Int32.of_int(0x0a010101 + flow)) ()) in 
    let pkt = (OP.Flow_mod.create flow_match (Int64.of_int 0) OP.Flow_mod.ADD ~hard_timeout:60  
    ~flags:{OP.Flow_mod.send_flow_rem=true;emerg=false;overlap=false;} 
    [|OP.Output(OP.All , 2000) |] () )
    in 
    resolve(OC.send_of_data controller dpid (OP.Flow_mod.flow_mod_to_bitstring pkt))
  done;
  let flow_match = (OP.Match.create_flow_match OP.Wildcards.full_wildcard ()) in 
  let flow_stats_req = (OP.Stats.create_flow_stat_req flow_match ())in 
  resolve(OC.send_of_data controller dpid flow_stats_req )

let flow_stats_reply_cb controller dpid evt =
  match evt with 
  | OE.Flow_stats_reply(xid, more, flows, dpid) -> 
      OS.Console.log (sp "* dpid:0x%012Lx evt:%s" dpid (OE.string_of_event evt))
  | _ -> invalid_arg "bogus flow_stats_reply event match!"

let init controller = 
  pp "test controller register datapath cb\n";
  OC.register_cb controller OE.DATAPATH_JOIN datapath_join_cb;  
  pp "test controller register flow stats cb\n";
  OC.register_cb controller OE.FLOW_STATS_REPLY flow_stats_reply_cb 

let main () =
  lwt mgr, mgr_t = Net.Manager.create () in
let port = 6633 in 
let ip = None in   
OC.listen mgr ip port init

let _ =
  OS.Main.run (main ()) 

