(* Copyright (C) 2009 Citrix Systems Inc.                                        *)
(* Copyright (C) 2005 Institut National de Recherche en Informatique et          *)
(*   en Automatique.                                                             *)
(*   Based on Odoc_xml by Maxence Guesdon                                        *)
(*   http://pauillac.inria.fr/~guesdon/odoc_generators/ocaml_3.11.0/odoc_xml.ml  *)

(*    This program is free software; you can redistribute it and/or modify       *)
(*    it under the terms of the GNU Lesser General Public License as published   *)
(*    by the Free Software Foundation; either version 2.1 of the License, or     *)
(*    any later version.                                                         *)
(*                                                                               *)
(*    This program is distributed in the hope that it will be useful,            *)
(*    but WITHOUT ANY WARRANTY; without even the implied warranty of             *)
(*    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the              *)
(*    GNU Lesser General Public License for more details.                        *)
(*                                                                               *)
(*    You should have received a copy of the GNU Lesser General Public License   *)
(*    along with this program; if not, write to the Free Software                *)
(*    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA                   *)
(*    02111-1307  USA                                                            *)
(*                                                                               *)

open Odoc_info
module Naming = Odoc_html.Naming
open Odoc_info.Value
open Odoc_info.Module

(* some stuff from stdext; should not be here *)

module String = struct include String
(** find all occurences of needle in haystack and return all their respective index *)
let find_all needle haystack =
	let m = String.length needle and n = String.length haystack in

	if m > n then
		[]
	else (
		let i = ref 0 and found = ref [] in
		while !i < (n - m + 1)
		do
			if (String.sub haystack !i m) = needle then (
				found := !i :: !found;
				i := !i + m
			) else (
				incr i
			)
		done;
		List.rev !found
	)

(* replace all @f substring in @s by @t *)
let replace f t s =
	let indexes = find_all f s in
	let n = List.length indexes in
	if n > 0 then (
		let len_f = String.length f and len_t = String.length t in
		let new_len = String.length s + (n * len_t) - (n * len_f) in
		let new_s = String.make new_len '\000' in
		let orig_offset = ref 0 and dest_offset = ref 0 in
		List.iter (fun h ->
			let len = h - !orig_offset in
			String.blit s !orig_offset new_s !dest_offset len;
			String.blit t 0 new_s (!dest_offset + len) len_t;
			orig_offset := !orig_offset + len + len_f;
			dest_offset := !dest_offset + len + len_t;
		) indexes;
		String.blit s !orig_offset new_s !dest_offset (String.length s - !orig_offset);
		new_s
	) else
		s
end

open String

let remove_asterisks str =
	let n = String.length str in
	let res = Buffer.create n in
	let phase = ref false in
	for i = 0 to n-1 do
		match !phase with
		| false ->
			if str.[i] == '\n' then begin
				phase := true;
				Buffer.add_char res ' '
			end else if i == 0 && str.[i] == '*' then
				phase := true
			else
				Buffer.add_char res str.[i]
		| true -> 
			if not (List.mem str.[i] ['\n'; '\t'; ' '; '*']) then begin
				phase := false;
				Buffer.add_char res str.[i]
			end
	done;
	Buffer.contents res

(* Dependencies *)

(** add node to graph *)
let rec add_node graph node =
	if List.exists (fun (n, _) -> n = node) graph then graph
	else (node, []) :: graph
	
(** add edge to graph *)
let rec add_edge graph src dest = match graph with
	| [] -> [(src, [dest])]
	| (node, lch) :: tl when node = src && not (List.mem dest lch) -> (src, dest :: lch) :: tl
	| hd :: tl -> hd :: add_edge tl src dest
	
(** return a slice "almost" as in Python s[a:b], where "-1" means the last
 *  char, "-2" the before-last, etc. *)
let slice s a b =
	let n = String.length s in
	let a0 = if a < 0 then n+a+1 else a in
	let b0 = if b < 0 then n+b-a0+1 else b-a0 in
	String.sub s a0 b0
	
(** obtain list of children *)
let get_childlist graph node =
	try	List.assoc node graph
	with Not_found -> []
	
(** reverse the edges of the given graph *)
let rec invert_graph g = function 
	| [] -> g
	| (node, lch) :: tl -> 
		let newg = add_node g node in
		let newg = List.fold_left (fun g ch -> add_edge g ch node) newg lch in
		invert_graph newg tl

(* JSON *)
  
let escape_json s =
  let len = String.length s in
  if len > 0 then begin
	  let buf = Buffer.create len in
	  for i = 0 to len - 1 do
		match s.[i] with
		| '\"' -> Buffer.add_string buf "\\\""
		| '\\' -> Buffer.add_string buf "\\\\"
		| '\b' -> Buffer.add_string buf "\\b"
		| '\n' -> Buffer.add_string buf "\\n"
		| '\r' -> Buffer.add_string buf "\\r"
		| '\t' -> Buffer.add_string buf "\\t"
		| c -> Buffer.add_char buf c
	  done;
	  Buffer.contents buf
  end
  else ""
  
type json =
| Object of (string * json) list
| Array of json list
| String of string
| Number of float
| True
| False
| Empty

let endl n =
	if n = 0 then ""
	else "\n" ^ String.make (2*n - 2) ' '

let rec json_to_string n = function
| Object l -> (endl n) ^ "{ " ^ (String.concat ("," ^ (endl (n+1))) (List.map (fun (s, j) -> "\"" ^ s ^ "\": " ^ (json_to_string (n+2) j)) l)) ^ " }"
| Array l -> "[ " ^ (String.concat ", " (List.map (fun j -> (json_to_string n j)) l)) ^ " ]"
| String s -> "\"" ^ (escape_json s) ^ "\""
| Number n -> Printf.sprintf "%.4f" n
| True -> "true"
| False -> "false"
| Empty -> "\"\""

let json_of_bool = function
| true -> True
| false -> False

(* HTML *)

let escape_quotes s =
  let len = String.length s in
  let buf = Buffer.create len in
  for i = 0 to len - 1 do
    match s.[i] with
      '"' -> Buffer.add_string buf "\\\""
    | c -> Buffer.add_char buf c
  done;
  Buffer.contents buf

type html =
| Node of string * (string * string) list * html list (** Node ("",_,_) will be discarded *)
| Leaf of string
| Raw_html of string

let node tag ?(atts=[]) subs = Node (tag, atts, subs)

let escape_entities s =
	let len = String.length s in
	let buf = Buffer.create len in
	for i = 0 to len - 1 do
		match s.[i] with
		| '<' -> Buffer.add_string buf "&lt;"
		| '>' -> Buffer.add_string buf "&gt;"
		| '&' -> Buffer.add_string buf "&amp;"
		| c -> Buffer.add_char buf c
	done;
	Buffer.contents buf

let string_of_bool b = if b then "true" else "false"

let rec print_one_t = function
| Leaf s -> escape_entities s
| Raw_html s -> s
| Node ("", _, _) -> ""
| Node (tag, atts, subs) ->
	"<" ^ tag ^
	(match atts with
	 | [] -> ""
	 | _ -> " " ^
		String.concat " " (List.map
		(fun (a,v) -> (Printf.sprintf "%s=\"%s\" " a (escape_entities (escape_quotes v)))) atts)
    ) ^ ">" ^
    (print_t_list subs) ^
    (Printf.sprintf "</%s>" tag)

and print_t_list l =
	String.concat "" (List.map print_one_t l)
	
let html_to_json l =
	String (print_t_list l)
  
(* the actual generator class *)

class gen () =
	object (self)
	
	(* Attributes *)
	
	val mutable g = []
	val mutable descr_cnt = 0
	val mutable completed_descr_cnt = 0
	
	(* Methods *)
	
	(* HTML *)
	
	method t_of_text = List.map self#t_of_text_element
	
	method t_of_raw s = Leaf (remove_asterisks s)
	
	method t_of_text_element = function
	| Odoc_info.Raw s -> self#t_of_raw s
	| Odoc_info.Code s -> node "span" ~atts:["class", "code"] [self#t_of_raw s]
	| Odoc_info.CodePre s -> node "span" ~atts:["class", "codepre"] [self#t_of_raw s]
	| Odoc_info.Verbatim s -> node "span" ~atts:["class", "verbatim"] [self#t_of_raw s]
	| Odoc_info.Bold t -> node "b" (self#t_of_text t)
	| Odoc_info.Italic t -> node "i" (self#t_of_text t)
	| Odoc_info.Emphasize t -> node "em" (self#t_of_text t)
	| Odoc_info.Center t -> node "span" ~atts:["class", "center"] (self#t_of_text t)
	| Odoc_info.Left t -> node "span" ~atts:["class", "left"] (self#t_of_text t)
	| Odoc_info.Right t -> node "span" ~atts:["class", "right"] (self#t_of_text t)
	| Odoc_info.List tl -> node "ul" (List.map (fun t -> node "li" (self#t_of_text t)) tl)
	| Odoc_info.Enum tl -> node "ol" (List.map (fun t -> node "li" (self#t_of_text t)) tl)
	| Odoc_info.Newline -> node "br" []
	| Odoc_info.Block t -> node "div" ~atts:["class", "block"] (self#t_of_text t)
	| Odoc_info.Title (n, l_opt, t) ->
		(*	(match l_opt with None -> [] | Some t -> ["name",t]) *)
		node ("h" ^ string_of_int n) (self#t_of_text t)
	| Odoc_info.Latex s -> node "span" ~atts:["class", "latex"] [self#t_of_raw s]
	| Odoc_info.Link (s, t) -> node "a" ~atts: ["href", s] (self#t_of_text t)
	| Odoc_info.Ref (name, ref_opt, _) -> self#t_of_Ref name ref_opt
	| Odoc_info.Superscript t -> node "sup" (self#t_of_text t)
	| Odoc_info.Subscript t -> node "sub" (self#t_of_text t)
	| Odoc_info.Module_list l -> Leaf "" (* self#json_of_Module_list l *)
	| Odoc_info.Index_list -> Leaf "" (* node "index_list" [] *)
	| Odoc_info.Custom (s,t) ->
		if s = "{html" then
			Raw_html (String.concat "" (List.map (fun (Odoc_info.Raw s) -> remove_asterisks s) t))
		else
			node "div" ~atts:["class", s] (self#t_of_text t)

	method t_of_Ref name ref_opt =
		let code = node "span" ~atts:["class", "code"] [Leaf name] in
		let k =
			match ref_opt with
			| None ->
				"none"
			| Some kind ->
				match kind with
				| Odoc_info.RK_module -> "module"
				| Odoc_info.RK_module_type -> "module_type"
				| Odoc_info.RK_class -> "class"
				| Odoc_info.RK_class_type -> "class_type"
				| Odoc_info.RK_value -> "value"
				| Odoc_info.RK_type -> "type"
				| Odoc_info.RK_exception -> "exception"
				| Odoc_info.RK_attribute -> "attribute"
				| Odoc_info.RK_method -> "method"
				| Odoc_info.RK_section t -> "section"
		in
		node "a" ~atts:[("href", "{" ^ k ^ "|" ^ name ^ "}")] [code]
	  
	(* JSON *)
	
	method json_of_loc l =
		let f tag = function
		| None -> [tag, String "unknown"]
		| Some (s,n) -> [tag, String (Printf.sprintf "%s|%d" s n)]
		in
		Object ((f "implementation" l.loc_impl) @ (f "interface" l.loc_inter))

    method json_of_module_type mt =
    	let name = "name", String mt.Module.mt_name in
		let loc = "location", self#json_of_loc mt.Module.mt_loc in
		let info = "info", self#json_of_info_opt mt.Module.mt_info in
		let mte = "type", match mt.Module.mt_type with
		| None -> Empty
		| Some t -> String (Odoc_info.string_of_module_type t) (* self#json_of_module_type_expr t *)
		in
		let mk = "kind", match mt.Module.mt_kind with
		| None -> Empty
  		| Some t -> Empty (* self#json_of_module_type_kind t *)
		in
		let file = "file", String mt.Module.mt_file in
		Object (name :: file :: loc :: info :: mte :: mk :: [])
			
	method json_of_module_element = function
	| Element_module m -> Object ["module", self#json_of_module m]
	| Element_module_type mt -> Object ["module_type", self#json_of_module_type mt]
	| Element_included_module im -> Object ["included_module", self#json_of_included_module im]
	| Element_class c -> Object ["class", self#json_of_class c]
	| Element_class_type ct -> Object ["class_type", self#json_of_class_type ct]
	| Element_value v -> Object ["value", self#json_of_value v]
	| Element_exception e -> Object ["exception", self#json_of_exception e]
	| Element_type t -> Object ["type", self#json_of_type t]
	| Element_module_comment text -> Object ["comment", self#json_of_comment text]
		
	method json_of_parameter = function
	| Parameter.Simple_name sn ->
		Object (["name", String sn.Parameter.sn_name;
		"type", self#json_of_type_expr sn.Parameter.sn_type] @
		(match sn.Parameter.sn_text with
		| None -> []
		| Some t -> ["comment", self#json_of_comment t])
		)
	| Parameter.Tuple (l,texpr) ->
		Object ["tuple", Object
		["type", self#json_of_type_expr texpr; "contents", Array (List.map self#json_of_parameter l)]]
	
	method json_of_class c = Empty
	method json_of_class_type c = Empty
	
	method json_of_value v =
		let name = "name", String v.Value.val_name in
		let loc = "location", self#json_of_loc v.Value.val_loc in
		let info = "info", self#json_of_info_opt v.Value.val_info in
		let te = "type", self#json_of_type_expr v.Value.val_type in
		let params = "params", Array (List.map self#json_of_parameter v.Value.val_parameters) in
(*		let code = match v.Value.val_code with
		None -> [] | Some s -> [node "code" [Leaf s]]
		in*)
		Object (name :: loc :: info :: te :: params :: []) (* @ code *)

	method json_of_exception e =
		let name = "name", String e.Exception.ex_name in
		let loc = "location", self#json_of_loc e.Exception.ex_loc in
		let info = "info", self#json_of_info_opt e.Exception.ex_info in
		let args = match e.Exception.ex_args with
		| [] -> []
		| l -> ["exception_args", Array (List.map self#json_of_type_expr l)]
		in
		let alias = match e.Exception.ex_alias with
		| None -> []
		| Some ea -> ["exception_alias", String ea.Exception.ea_name]
		in
(*		let code = match e.Exception.ex_code with
		| None -> []
		| Some s -> [node "code" [Leaf s]]
		in *)
		Object (name :: loc :: info :: args @ alias) (*  @ code *)

	method json_of_included_module im =
		let name = "name", String im.Module.im_name in
		let info = "info", self#json_of_info_opt im.Module.im_info in
		let kind = match im.im_module with
		| None -> []
		| Some (Module.Mod _) -> ["kind", String "module"]
		| Some (Module.Modtype _) -> ["kind", String "module_type"]
		in
		Object (name :: info :: kind @ [])

	method json_of_comment t =
		html_to_json (self#t_of_text t)
		
	method json_of_type t =
		let name = "name", String t.Type.ty_name in
		let loc = "location", self#json_of_loc t.Type.ty_loc in
		let info = "info", self#json_of_info_opt t.Type.ty_info in
		let params = "params", Array (List.map self#json_of_type_parameter t.Type.ty_parameters) in
		let kind = "kind", self#json_of_type_kind t.Type.ty_private t.Type.ty_kind in
		let manifest = match t.Type.ty_manifest with
		| None -> []
		| Some t -> ["manifest", self#json_of_type_expr t]
		in
(*		let code = match t.Type.ty_code with
		| None -> [] | Some s -> [node "code" [Leaf s]]
		in*)
		Object (name :: loc :: info :: params :: kind :: manifest @ []) (* @ code *)
	    
	method json_of_type_parameter (texp, covar, contravar) =
		Object ["covariant", (json_of_bool covar); "contravariant", (json_of_bool contravar); "type", self#json_of_type_expr_param texp]
	    
	method json_of_type_expr t =
		Odoc_info.reset_type_names ();
		String (Odoc_info.string_of_type_expr t)
		
	method json_of_type_expr_param t =
		String (Odoc_info.string_of_type_expr t)
	
	method json_of_type_kind priv = function
	| Type.Type_abstract -> Object ["type", String "abstract"]
	| Type.Type_variant cons ->
		Object ["type", String "variant"; "private", String (string_of_bool (priv = Type.Private));
		"constructors", Array (List.map self#json_of_variant_constructor cons)]
	| Type.Type_record fields ->
		Object ["type", String "record"; "private", String (string_of_bool (priv = Type.Private));
		"fields", Array (List.map self#json_of_record_field fields)]

	method json_of_variant_constructor c =
		let desc = match c.Type.vc_text with
		| None -> []
		| Some t ->
			completed_descr_cnt <- completed_descr_cnt + 1;
			["description", html_to_json (self#t_of_text t)]
		in
		descr_cnt <- descr_cnt + 1;
		Object (["name", String c.Type.vc_name] @ desc @ ["type", Array (List.map self#json_of_type_expr c.Type.vc_args)])

	method json_of_record_field f =
		let desc = match f.Type.rf_text with
		| None -> []
		| Some t ->
			completed_descr_cnt <- completed_descr_cnt + 1;
			["description", html_to_json (self#t_of_text t)]
		in
		descr_cnt <- descr_cnt + 1;
		Object (["name", String f.Type.rf_name; "mutable", json_of_bool f.Type.rf_mutable] @
		desc @ ["type", self#json_of_type_expr f.Type.rf_type])
	    
	method json_of_info_opt info =
		descr_cnt <- descr_cnt + 1;
		match info with
		| None -> Empty
		| Some i -> self#json_of_info i
    
	method json_of_info i =
		let desc = match i.i_desc with
		| None -> []
		| Some t ->
			completed_descr_cnt <- completed_descr_cnt + 1;
			["description", html_to_json (self#t_of_text t)]
		in
		let authors = match List.map (fun s -> String s) i.i_authors with
		| [] -> []
		| l -> ["authors", Array l] in
		let version = match i.i_version with
		| None -> []
		| Some s -> ["version", String s]
		in
		let see = match List.map self#json_of_see i.i_sees with
		| [] -> []
		| l -> ["see", Array l] in
		let since = match i.i_since with
		| None -> []
		| Some s -> ["since", String s]
		in
		let dep = match i.i_deprecated with
		| None -> []
		| Some t -> ["deprecated", html_to_json (self#t_of_text t)]
		in
		let params = [] in
		let raised = match List.map self#json_of_raised_exception i.i_raised_exceptions with 
		| [] -> []
		| l -> ["raised_exceptions", Array l]
		in
		let return_v = match i.i_return_value with
		| None -> []
		| Some t -> ["return", html_to_json (self#t_of_text t)]
		in
		let customs = List.map (fun (tag, t) -> tag, html_to_json (self#t_of_text t)) i.i_custom in
		Object (desc @ authors @ version @ see @ since @ dep @ params @ raised @ return_v @ customs)
		
	method json_of_see = function
	| (See_url s, t) -> Object ["url", String s; "text", html_to_json (self#t_of_text t)]
	| (See_file s, t) -> Object ["file", String s; "text", html_to_json (self#t_of_text t)]
	| (See_doc s, t) -> Object ["doc", String s; "text", html_to_json (self#t_of_text t)]

	method json_of_raised_exception (s, t) =
		Object ["raised_exception", String s; "text", html_to_json (self#t_of_text t)]

	method json_of_module_parameter mparam =
		let name = "name", String mparam.Module.mp_name in
		Object (name :: [])
		
	method json_of_module_kind = function
	| Module_struct l ->
		"module_structure", Array (List.map self#json_of_module_element l)
	| Module_alias ma ->
		"module_alias", String "unavailable" (* self#t_of_module_alias ma *)
	| Module_functor (mparam, mk) ->
		"module_functor", Object (["parameter", self#json_of_module_parameter mparam; self#json_of_module_kind mk])
(*		  node "module_functor"
		[ self#t_of_module_parameter mparam ; self#t_of_module_kind mk]*)
	| Module_apply (mk1, mk2) ->
		"module_apply", String "unavailable"
(*		  node "module_apply"
		[ self#t_of_module_kind mk1 ; self#t_of_module_kind mk2]*)
	| Module_with (mk, s) ->
		"module_with", String "unavailable"
(*		  node "module_with"
		[ self#t_of_module_type_kind mk; node "with" [Leaf s] ]*)
	| Module_constraint (mk, mtk) ->
		self#json_of_module_kind mk
(*		  node "module_constraint"
		[ self#t_of_module_kind mk ;
		  self#t_of_module_type_kind mtk ;
		]*)

	method json_of_module m =
		let name = "name", String m.Module.m_name in
		let loc = "location", self#json_of_loc m.Module.m_loc in
		let deps = "dependencies", Object ["uses", Array (List.map (fun d -> String d) m.Module.m_top_deps)] in
		let file = "file", String m.Module.m_file in
		let mte = "type", String (Odoc_info.string_of_module_type m.Module.m_type) in
		let mk = self#json_of_module_kind m.Module.m_kind in
		let info = "info", self#json_of_info_opt m.Module.m_info in
		
		(* dependencies *)
		let p = m.Module.m_name in
		let ch = m.Module.m_top_deps in
		g <- (p, ch) :: g;
		
		Object (name :: file :: loc :: info :: mte :: mk :: deps :: [])

	method generate (modules_list : t_module list) =
		let write_module_json (name, json, _) =
			let oc = open_out (!Odoc_args.target_dir ^ "/" ^ name ^ ".json") in
			output_string oc (json_to_string 0 json);
			close_out oc
		in
		let write_index_json ml =
			let oc = open_out (!Odoc_args.target_dir ^ "/index.json") in
			let make_record = function
			| (name, Object ["module", Object m], (dc, cdc)) ->
				let info = List.assoc "info" m in
				Object ["name", String name; "info", info; "descr_cnt", Number dc; "compl_descr_cnt", Number cdc]
			| _ -> Empty
			in
			let modules = Array (List.map make_record ml) in
			output_string oc (json_to_string 0 modules);
			close_out oc
		in
		let create_module_json m =
			let cur_descr_cnt = descr_cnt in
			let cur_completed_descr_cnt = completed_descr_cnt in
			let json = self#json_of_module m in
			m.Module.m_name, Object ["module", json],
				(float_of_int (descr_cnt - cur_descr_cnt), float_of_int (completed_descr_cnt - cur_completed_descr_cnt))
		in
		let modules = List.map create_module_json modules_list in
		let ig = invert_graph [] g in
		let rec add_used_by (name, json, stats) =
			let used_by = Array (List.map (fun s -> String s) (List.assoc name ig)) in
			let rec extend_object f tags = function
			| Object l -> Object ((List.map (fun (s,o) -> s, extend_object f (tags @ [s]) o) l) @ f tags)
			| x -> x
			in
			let aux = function
			| ["module"; "dependencies"] -> ["used_by", used_by]
			| l -> []
			in
			name, extend_object aux [] json, stats
		in
		let modules = List.map add_used_by modules in
		List.iter write_module_json modules;
		write_index_json modules
end

let generator = ((new gen ()) :> Odoc_args.doc_generator)

let _ = Odoc_args.set_doc_generator (Some generator)

