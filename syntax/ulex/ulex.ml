(* NFA *)

type node = { 
  id : int; 
  mutable eps : node list; 
  mutable trans : (Cset.t * node) list;
}

(* Compilation regexp -> NFA *)

type regexp = node -> node

let cur_id = ref 0
let new_node () =
  incr cur_id;
  { id = !cur_id; eps = []; trans = [] }

let seq r1 r2 succ = r1 (r2 succ)

let alt r1 r2 succ =
  let n = new_node () in
  n.eps <- [r1 succ; r2 succ];
  n

let rep r succ =
  let n = new_node () in
  n.eps <- [r n; succ];
  n

let plus r succ =
  let n = new_node () in
  let nr = r n in
  n.eps <- [nr; succ];
  nr

let eps succ = succ

let chars c succ =
  let n = new_node () in
  n.trans <- [c,succ];
  n

let compile_re re =
  let final = new_node () in
  (re final, final)

(* Determinization *)

type state = node list

let rec add_node state node = 
  if List.memq node state then state else add_nodes (node::state) node.eps
and add_nodes state nodes =
  List.fold_left add_node state nodes


let transition state =
  (* Merge transition with the same target *)
  let rec norm = function
    | (c1,n1)::((c2,n2)::q as l) ->
	if n1 == n2 then norm ((Cset.union c1 c2,n1)::q)
	else (c1,n1)::(norm l)
    | l -> l in
  let t = List.concat (List.map (fun n -> n.trans) state) in
  let t = norm (List.sort (fun (c1,n1) (c2,n2) -> n1.id - n2.id) t) in

  (* Split char sets so as to make them disjoint *)
  let rec split (all,t) ((c0 : Cset.t),n0) = 
    let t = 
      [(Cset.difference c0 all, [n0])] @
      List.map (fun (c,ns) -> (Cset.intersection c c0, n0::ns)) t @
      List.map (fun (c,ns) -> (Cset.difference c c0, ns)) t in
    (Cset.union all c0,
    List.filter (fun (c,ns) -> not (Cset.is_empty c)) t) in

  let (_,t) = List.fold_left split (Cset.empty,[]) t in

  (* Epsilon closure of targets *)
  let t = List.map (fun (c,ns) -> (c,add_nodes [] ns)) t in

  (* Canonical ordering *)
  let t = Array.of_list t in
  Array.sort (fun (c1,ns1) (c2,ns2) -> compare c1 c2) t;
  Array.map fst t, Array.map snd t

let find_alloc tbl counter x =
  try Hashtbl.find tbl x
  with Not_found ->
    let i = !counter in
    incr counter;
    Hashtbl.add tbl x i;
    i
 
let part_tbl = Hashtbl.create 31
let part_id = ref 0
let get_part (t : Cset.t array) = find_alloc part_tbl part_id t


let compile rs =
  let rs = Array.map compile_re rs in
  let counter = ref 0 in
  let states = Hashtbl.create 31 in
  let states_def = ref [] in
  let rec aux state =
    try Hashtbl.find states state
    with Not_found ->
      let i = !counter in
      incr counter;
      Hashtbl.add states state i;
      let (part,targets) = transition state in
      let part = get_part part in
      let targets = Array.map aux targets in
      let finals = Array.map (fun (_,f) -> List.mem f state) rs in
      states_def := (i, (part,targets,finals)) :: !states_def;
      i
  in
  let init = ref [] in
  Array.iter (fun (i,_) -> init := add_node !init i) rs;
  ignore (aux !init);
  Array.init !counter (fun id -> List.assoc id !states_def)
  
let partitions () =
  let aux part =
    let seg = ref [] in
    Array.iteri
      (fun i c -> 
	 List.iter (fun (a,b) -> seg := (a,b,i) :: !seg) c)
      part;
     List.sort (fun (a1,_,_) (a2,_,_) -> compare a1 a2) !seg in
  let res = ref [] in
  Hashtbl.iter (fun part i -> res := (i, aux part) :: !res) part_tbl;
  Hashtbl.clear part_tbl;
  !res

