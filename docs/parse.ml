open Json
open Printf

let string_of_file name =
  let ch = open_in name in
  let len = 1024 in
  let buf = Buffer.create len in
  (try while true do
    let l = input_line ch in
    Buffer.add_string buf l
   done with _ -> ());
  close_in ch;
  Buffer.contents buf

let string_val k l =
  match List.assoc k l with |String x -> x |_ -> "" 

let array_val k l =
  match List.assoc k l with |Array x -> x |u -> failwith (Json.to_string u) 

let module_type l =
  if List.mem_assoc "module_structure" l then `Module else `Functor

let parse_module dir name fn =
  match Json.of_string (string_of_file (Filename.concat dir (name ^ ".json"))) with
  |Object [ "module", Object x ] ->  fn x
  |x -> failwith (Json.to_string x)
  
let index_map dir fn = 
  match Json.of_string (string_of_file (Filename.concat dir "index.json")) with
  |Array js -> List.map (function Object l -> fn l |_ -> assert false) js
  |x -> failwith (Json.to_string x)

let module_map dir fn =
  index_map dir (fun l -> parse_module dir (string_val "name" l) fn)
  
let make_tree dir =
  let rec sub_tree m =
    let name = string_val "name" m in
    let mstruct = match module_type m with
      |`Module -> array_val "module_structure" m
      |`Functor -> [] 
    in
    let mods = List.fold_left (fun a -> function Object ["module",Object x] -> x ::a  |_ -> a) [] mstruct in
    let children = List.map sub_tree mods in
    Object [ "data", String name; "attr", Object ["id", String ("tree" ^ name)]; "children", Array children ]
  in 
  Array (module_map dir sub_tree)

let _ =
  let dir = Sys.argv.(1) in
  let module_tree = make_tree dir in
  let module_info = module_map dir (fun x ->
    let name = string_val "name" x in
    name, Object ["module", Object x]
  ) in
  let out_json = Object [ "tree", module_tree; "info", Object module_info ] in
  print_endline (Json.to_string out_json)
