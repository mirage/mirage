(* 
 *  Copyright (c) 2012 Charalampos Rotsos <cr409@cl.cam.ac.uk>
 * 
 *  Permission to use, copy, modify, and distribute this software for any
 *  purpose with or without fee is hereby granted, provided that the above
 *  copyright notice and this permission notice appear in all copies.
 * 
 *  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 *  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 *  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 *  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 *  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 *  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 *  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *)

open Lwt
open Printf 

external ns3_add_node : string -> unit = "ocaml_ns3_add_node"
external ns3_add_link : string -> string -> int -> int -> int -> bool -> unit 
= "ocaml_ns3_add_link_bytecode" "ocaml_ns3_add_link_native"
external ns3_add_net_intf : string -> string -> string -> string -> unit = "ns3_add_net_intf"
external ns3_log : string -> unit = "ocaml_ns3_log"
external ns3_get_dev_byte_counter : string -> string -> int = 
  "ocaml_ns3_get_dev_byte_counter"

(* Main run thread *) 
external ns3_run : int -> int = "ocaml_ns3_run" 

type node_t = {
  name: string;
  cb_init : (unit -> unit Lwt.t);
}

type topo_t = {
  nodes : (string, node_t) Hashtbl.t;
  mutable links : (string * string * float) list;
} 

let topo = 
  {nodes=(Hashtbl.create 64);links=[];}

let log typ data = 
  let msg = Json.to_string (
    Json.Object [
      ("ts", (Json.Float (Clock.time ())));
      ("type", (Json.String typ)); 
    ("data", (Json.String data));]) in
    ns3_log msg

let get_topology () =
  let ix = ref 0L in 
  let names = Hashtbl.create 64 in 
  let nodes = Hashtbl.fold
    (fun name _ r ->
      Hashtbl.add names name !ix;
      let _ = ix := Int64.add !ix 1L in 
      r @ [(Json.Object [
        ("name", (Json.String name));
        ("flows", (Json.Array []));
        ("dev", (Json.Array []));
    ] )]
    ) topo.nodes [] in
  let links = List.fold_right (
    fun (nodes_a, nodes_b, _) r -> 
      let ix_a = Hashtbl.find names nodes_a in 
      let ix_b = Hashtbl.find names nodes_b in
      r @ [(Json.Object 
      [("source",(Json.Int ix_a));
      ("target",(Json.Int ix_b));
      ("ts", (Json.Float (Clock.time ()) ));
      ("value",(Json.Int 1L))])] 
  ) topo.links [] in 
      Json.Object [("nodes",(Json.Array nodes));
      ("links", (Json.Array links));]

let get_link_utilization () = 
  let utilisation = List.fold_right (
    fun (node_a, node_b, rate) r -> 
      let utilization_a_b = 
        float_of_int ((ns3_get_dev_byte_counter node_a node_b) lsl 11) in
      let res = r @ (
        if (utilization_a_b < 0.0) then
          []
        else
         [(Json.Object [
          ("source", (Json.String node_a));
          ("target", (Json.String node_b));
          ("ts", (Json.Float (Clock.time ()) ));
          ("value", (Json.Float (utilization_a_b /. rate)))])])
      in
      let utilization_b_a = 
        float_of_int ((ns3_get_dev_byte_counter node_b node_a) lsl 11) in 
        if (utilization_b_a < 0.0) then
          res
        else
          res @ [
            (Json.Object [
              ("source", (Json.String node_b));
              ("target", (Json.String node_a));
              ("ts", (Json.Float (Clock.time ()) ));
              ("value", (Json.Float (utilization_b_a /. rate) ))]);]
  ) topo.links [] in 
        Json.to_string (Json.Array utilisation) 

let monitor_links () = 
  let _ = printf "starting link monitoring\n%!" in
  while_lwt true do 
    lwt _ = Time.sleep 1.0 in 
    let _ = printf "getting link stats\n%!" in 
    let res = get_link_utilization () in 
    let _ = log "link_utilization" res in 
      return ()
  done

let exec fn () =
  Lwt.ignore_result (fn ())

let load t =
  Printf.printf "OS.Topology started...\n%!";
  let _ = t () in
  let _ = log "topology" (Json.to_string (get_topology ())) in 
  let _ = exec (monitor_links) () in 
  let _ = ns3_run (Time.get_duration ()) in
    ()

let add_node name cb_init =
  let _ = ns3_add_node name in
    Hashtbl.replace topo.nodes name {name; cb_init;} 

let no_act_init () =
  return ()

let add_external_dev dev node ip mask =
(*  let (ip, mask) = 
    match config with 
    | `DHCP ->
      eprintf "DHCP cannot be assigned to an external dev\n%!";
      failwith "DHCP cannot be assigned to an external dev"
    | `IPv4 (ip, mask, gws) ->
      (ip, mask)
  in *)
  Hashtbl.replace topo.nodes dev {name=dev; cb_init=no_act_init;};
  ns3_add_net_intf dev node ip mask
  
  (* rate is in Mbps. *)
let add_link ?(rate=1000) ?(prop_delay=0) ?(queue_size=100) ?(pcap=false)
    node_a node_b =
  try 
    let _ = Hashtbl.find topo.nodes node_a in 
    let _ = Hashtbl.find topo.nodes node_b in 
    let _ = topo.links <- topo.links @ [(node_a, node_b, 
    (float_of_int (rate*1000000)))] in 
      ns3_add_link node_a node_b rate prop_delay queue_size pcap  
  with Not_found -> ()

let node_name = Lwt.new_key ()


let init_node name =
  let _ = Printf.printf "Initialising node %s....\n%!" name in
    try
      let node = Hashtbl.find topo.nodes name in 
        Lwt.with_value node_name (Some(node.name)) (exec node.cb_init)
    with Not_found -> 
      printf "Node '%s' (len %d) was ot found\n%!" name (String.length name)


let _ = Callback.register "init" init_node

