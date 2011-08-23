open Printf
open Ofpacket

open Bitstring

type dpid = string 

(* Add on this one the switch details? *)
type of_event = 
				| Pkt_in of port*bitstring*dpid 
				|	Datapath_join of dpid  
				| Datapath_leave of dpid
(*
let int_of_of_event = function
	| 1 -> Datapath_join
	| 2 -> Datapath_leave
	| 3 -> Pkt_in
	| _ -> invalid arg "int_of_of_event"
*)
