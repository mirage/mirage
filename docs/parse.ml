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
  try match List.assoc k l with
    | String x -> x
    | _        -> ""
  with Not_found ->
    Printf.eprintf "string_val %s %s\n%!" k (Json.to_string (Object l)); exit 1

let object_val k l =
  try match List.assoc k l with
    | Object x -> x
    | _        -> []
  with Not_found ->
    Printf.eprintf "string_val %s %s\n%!" k (Json.to_string (Object l)); exit 1

let array_val k l =
  try match List.assoc k l with
    | Array x -> x
    | _       -> []
  with Not_found ->
    []

let get_object = function
  | Object x -> x
  | j        -> Printf.eprintf "%s\n!" (Json.to_string j); exit 1

let module_type l =
  if List.mem_assoc "module_type" l then
    `Module_type (object_val "module_type" l)
  else if List.mem_assoc "module" l then
    `Module (object_val "module" l)
  else
    `Other

let parse_module dir name fn =
  match Json.of_string (string_of_file (Filename.concat dir (name ^ ".json"))) with
  |Object [ "module", Object x ] ->  fn x
  |x -> failwith ("b" ^ Json.to_string x)
  
let index_map dir fn = 
  match Json.of_string (string_of_file (Filename.concat dir "index.json")) with
  |Array js -> List.map (function Object l -> fn l |_ -> assert false) js
  |x -> failwith ("c" ^ Json.to_string x)

let module_map dir fn =
  index_map dir (fun l -> parse_module dir (string_val "name" l) fn)
  
let make_tree dir =
  let node name children = Object [
    "data", String name;
    "attr", Object ["id", String ("tree" ^ name)];
    "children", Array children;
  ] in
  let rec subtree l =
    let name = string_val "name" l in
    let children =
      List.fold_left (fun accu m ->
        match module_type (get_object m) with
          | `Module_type m
          | `Module m -> subtree m :: accu
          | `Other -> accu
      ) [] (array_val "module_structure" l) in
    node name children in
  Array (module_map dir subtree)

let _ =
  let dir = Sys.argv.(1) in
  let module_tree = make_tree dir in
  let module_info = module_map dir (fun x ->
    let name = string_val "name" x in
    name, Object ["module", Object x]
  ) in
  let out_json = Object [ "tree", module_tree; "info", Object module_info ] in
  print_endline (Json.to_string out_json)
