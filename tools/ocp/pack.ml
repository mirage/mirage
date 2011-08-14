(***********************************************************************)
(*                                                                     *)
(*                TypeRex : OCaml Development Tools                    *)
(*                                                                     *)
(*                       OCamlPro S.A.S.                               *)
(*                                                                     *)
(*  Copyright 2011 OCamlPro SAS                                        *)
(*  All rights reserved.  This file is distributed under the terms of  *)
(*  the GNU Public License version 3.0.                                *)
(*                                                                     *)
(***********************************************************************)

let functors_arg = ref []
let pack_functor_arg = ref None
let target_arg = ref None
let sources_arg = ref []
let rec_arg = ref false
let mli_arg = ref false
let ml_arg = ref true
let with_ns = ref false
let verbosity = ref 0
let file_number = ref 0

let oc_ml = ref None
let oc_mli = ref None

module StringSet = Set.Make(String)
module StringMap = Map.Make(String)

type namespace = {
  ns_name : string;
  mutable ns_closed : StringSet.t;
  mutable ns_open : namespace option;
}

let ns = {
  ns_name = "";
  ns_closed = StringSet.empty;
  ns_open = None;
}

let _ml s =
  match !oc_ml with
      None -> ()
    | Some oc -> output_string oc s

let _mli s =
  match !oc_mli with
      None -> ()
    | Some oc -> output_string oc s

let rec close_ns_open ns =
  match ns.ns_open with
      None -> ()
    | Some ns_in ->
      _ml "end\n";
      _mli "end\n";
      ns.ns_open <- None;
      ns.ns_closed <- StringSet.add ns_in.ns_name ns.ns_closed;
      close_ns_open ns_in

let dump_file _p filename =
  if !verbosity > 0 then
    Printf.eprintf "dump_file %s\n" filename;
  _p (Printf.sprintf "#0 \"%s\"\n" filename);
  let ic = open_in filename in
  try
    while true do
      let line = input_line ic in
      _p (Printf.sprintf "%s\n" line)
    done;
  with End_of_file ->
    close_in ic

let split s c =
  let len = String.length s in
  let rec iter pos =
    try
      if pos = len then [""] else
	let pos2 = String.index_from s pos c in
	if pos2 = pos then "" :: iter (pos+1) else
          (String.sub s pos (pos2-pos)) :: (iter (pos2+1))
    with _ -> [String.sub s pos (len-pos)]
  in
  iter 0

let split_filename filename = split filename '/'

let name = Sys.argv.(0)

let arg_usage = Printf.sprintf "\
Usage:

   %s -o target.ml [options] files.ml*

Options:
" name

let version () = Printf.printf "\
ocp-pack version %s-%s

Copyright (C) 2011 OCamlPro S.A.S.

This is free software; see the source for copying conditions.  There is NO
warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

"
  Version.number Version.git_commit;
  exit 0


let arg_list = Arg.align [
  "-o", Arg.String (fun s -> target_arg := Some s),
  " <filename.ml> : generate filename filename.ml";
  "-rec", Arg.Set rec_arg, " : use recursive modules (all .ml files must have a corresponding .mli file)";
    "-pack-functor", Arg.String (fun s -> pack_functor_arg := Some s),
  "<modname> : create functor with name <modname>";
  "-functor", Arg.String (fun s -> functors_arg := s :: !functors_arg),
  " <filename.mli> : use filename as an argument for functor";
  "-mli", Arg.Set mli_arg, " : output the .mli file too (.ml files without .mli file will not export any value)";
  "-no-ml", Arg.Clear ml_arg, " : do not output the .ml file";
  "-with-ns", Arg.Set with_ns, " : use directory structure to create a hierarchy of modules";
  "-v", Arg.Unit (fun _ -> incr verbosity), " : increment verbosity";
  "-version", Arg.Unit version,
  "               display version information";
]

let error msg =
  Printf.eprintf "ERROR: %s\n\n%!" msg;
  Arg.usage arg_list arg_usage;
  exit 2

let _ =
  Arg.parse arg_list (fun s -> sources_arg := s :: !sources_arg) arg_usage



let rec output_file ns prefix filename =
  let full_filename = String.concat "/" (prefix @ filename) in
  let dirname = Filename.dirname full_filename in

  match filename with
      [] -> assert false
    | ("." | "") :: filename ->
      output_file ns prefix filename
    | [ basename ] ->
      let basename = Filename.chop_extension basename in
      let ml_filename = Filename.concat dirname (basename ^ ".ml") in
      let mli_filename = Filename.concat dirname (basename ^ ".mli") in

      let modname = String.capitalize basename in
      close_ns_open ns;
      if StringSet.mem modname ns.ns_closed then
	error (Printf.sprintf "module %s already opened when reading %s" modname ml_filename);


      let has_ml_file = Sys.file_exists ml_filename in
      let has_mli_file = Sys.file_exists mli_filename in

      let keyword =
	if !rec_arg then
	  if !file_number = 0 then "module rec" else "and"
	else "module"
      in

      if has_ml_file then begin
	if has_mli_file then
	  begin
	    _mli (Printf.sprintf "%s %s : sig\n" keyword modname);
	    dump_file _mli mli_filename;
	    _mli (Printf.sprintf "end\n");
	  end
	else
	  if !rec_arg then
	    failwith (Printf.sprintf "File %s needs an interface with -rec option" ml_filename);

	_ml (Printf.sprintf "%s %s" keyword modname);
	if has_mli_file then begin
	  _ml (Printf.sprintf ": sig\n");
	  dump_file _ml mli_filename;
	  _ml (Printf.sprintf "end = struct\n");
	  if !rec_arg then begin
	    _ml (Printf.sprintf "module type INTERFACE = sig\n");
	    dump_file _ml mli_filename;
	    _ml (Printf.sprintf "end\n");
	    _ml (Printf.sprintf "module IMPLEMENTATION = struct\n");
	    dump_file _ml ml_filename;
	    _ml (Printf.sprintf "end\n");
	    _ml (Printf.sprintf "include (IMPLEMENTATION : INTERFACE)\n");
	  end else begin
	    dump_file _ml ml_filename;
	  end;
	  _ml (Printf.sprintf "end\n");
	end else begin
	  _ml (Printf.sprintf " = struct\n");
	  dump_file _ml ml_filename;
	  _ml (Printf.sprintf "end\n");
	end
      end else begin
	_ml (Printf.sprintf  "%s %s : sig\n" keyword modname);
	dump_file _ml mli_filename;
	_ml (Printf.sprintf  "end = struct\n");
	dump_file _ml mli_filename;
	_ml (Printf.sprintf  "end\n");

	_mli (Printf.sprintf "%s %s : sig\n" keyword modname);
	dump_file _mli mli_filename;
	_mli (Printf.sprintf "end\n");
      end;

      ns.ns_closed <- StringSet.add modname ns.ns_closed

    | dirname :: tail ->
      if !with_ns then
	let modname = String.capitalize dirname in
	if StringSet.mem modname ns.ns_closed then
	  failwith (Printf.sprintf "module %s already closed when reading %s" modname full_filename);
	let ns_in =
	  match ns.ns_open with
	      Some ns_in when ns_in.ns_name = modname -> ns_in
	    | _ ->
	      close_ns_open ns;
	      let ns_in = {
		ns_name = modname;
		ns_closed = StringSet.empty;
		ns_open = None;
	      } in
	      _mli (Printf.sprintf  "module %s : sig\n" modname);
	      _ml (Printf.sprintf  "module %s = struct \n" modname);
	      ns.ns_open <- Some ns_in;
	      ns_in
	in
	output_file ns_in (prefix @[ dirname ]) tail
      else
	output_file ns (prefix @[ dirname ]) tail

let _ =
  sources_arg := List.rev !sources_arg;
  match !target_arg with
      None -> error "You must specify a target with -o target.ml"
    | Some target ->
      if !ml_arg then oc_ml := Some (open_out target);
      if !mli_arg then oc_mli  := Some ( open_out (target ^ "i") );
      (match !pack_functor_arg with
	  None -> ()
	| Some modname ->
	  _ml (Printf.sprintf "module %s" modname);
	  List.iter (fun mli_filename ->
	    let modname = String.capitalize (Filename.chop_suffix (Filename.basename mli_filename) ".mli")in
	    _ml (Printf.sprintf "(%s : sig\n" modname);
	    dump_file _ml mli_filename;
	    _ml ("\nend)\n");
	  ) (List.rev !functors_arg);
	  _ml (Printf.sprintf " = struct\n");
      );
      List.iter (fun filename ->
	if Filename.check_suffix filename ".ml" ||
	  Filename.check_suffix filename ".mli"
	then begin
	  if !verbosity > 0 then
	    Printf.eprintf "Inserting %s\n" filename;
	  let filename = split_filename filename in
	  output_file ns [] filename;
	  incr file_number;
	end else
(*	if Filename.check_suffix filename ".mli" then
	  Printf.fprintf stderr "Discarding interface file %s\n%!" filename
	else *)
	  error (Printf.sprintf "Don't know what to do with anonymous argument [%s]" filename)
      ) !sources_arg;
      close_ns_open ns;
      (match !pack_functor_arg with
	  None -> ()
	| Some modname ->
	  _ml (Printf.sprintf "\nend\n");
      );
      (match !oc_ml with None -> () | Some oc ->
	close_out oc; oc_ml := None);
      (match !oc_mli with None -> () | Some oc ->
	close_out oc; oc_mli := None)
