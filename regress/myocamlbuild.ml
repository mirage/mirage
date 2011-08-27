(*
 * Copyright (c) 2010-2011 Anil Madhavapeddy <anil@recoil.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *)

open Ocamlbuild_plugin
open Command
open Ocamlbuild_pack.Ocaml_compiler
open Ocamlbuild_pack.Ocaml_utils
open Ocamlbuild_pack.Tools
open Printf

(* Utility functions (e.g. to execute a command and return lines read) *)
module Util = struct
  let split s ch =
    let x = ref [] in
    let rec go s =
      try
        let pos = String.index s ch in
        x := (String.before s pos)::!x;
        go (String.after s (pos + 1))
      with Not_found -> x := s :: !x
    in
    go s;
    List.rev !x

    let split_nl s = split s '\n'

    let run_and_read x = List.hd (split_nl (Ocamlbuild_pack.My_unix.run_and_read x))
end

module Spec = struct
  (** Supported Mirage backends *)
  type backend =  
   |Xen
   |Node
   |Unix_direct
   |Unix_socket

  (** Spec file describing the test and dependencies *)
  type t = {
    backends: backend list;
  }

  let backend_of_string = function
    |"xen" -> Xen 
    |"unix-direct" -> Unix_direct
    |"node" -> Node 
    |"unix-socket" -> Unix_socket
    |x -> failwith ("unknown backend: " ^ x)

  (** Give a backend and target, return a build command *)
  let command targ =
    function
    |Xen -> [A"mir-xen"; P(sprintf "%s.xen" targ) ]
    |Node -> [A"mir-node"; P(sprintf "%s.js" targ)] 
    |Unix_socket -> [A"mir-unix-socket"; P(sprintf "%s.bin" targ)]
    |Unix_direct -> [A"mir-unix-direct"; P(sprintf "%s.bin" targ)]

  let all_backends = [Xen;Node;Unix_socket;Unix_direct]

  let backend_is_supported b spec =
    List.mem b spec.backends

  (** Spec file contains key:value pairs: 

    backend:node,xen,unix-direct
    backend:* (short form of above)
    no backend key results in "backend:*" being default

    *)
  let parse file = 
    let lines = string_list_of_file file in
    let kvs = List.map (fun line ->
      match Util.split line ':' with
      |[k;v] -> (String.lowercase k), (String.lowercase v)
      |_ -> failwith (sprintf "unknown spec entry '%s'" line)
    ) lines in
    let backends =
      try (match List.assoc "backend" kvs with
       |"*" -> all_backends
       |backends -> List.map backend_of_string (Util.split backends ',')
      ) with Not_found -> all_backends
    in {backends}

end

let () =
  rule "start"
    ~prod:"%.start"
    ~dep:"%.spec"
    (fun env builder ->
       printf "start %s\n%!" (env "%.start");
       Cmd (S[ A"echo"; A"shell start"; A (env "%.start")])
    )

let () =
  rule "build"
    ~prod:"tests/%(test).%(backend).build"
    ~dep:"tests/%(test).mir"
    (fun env build ->
       let log = env "%(test).%(backend).build" in
       let backend = Spec.backend_of_string (env "%(backend)") in
       let cmd = Spec.command (env "%(test)") backend in
       Seq [
      ]
    )

let () =
  rule "end" 
    ~prod:"%.end"
    ~dep:"%.start"
    (fun env builder ->
      printf "end %s\n%!" (env "%.end");
      Cmd (S[ A"echo"; A"shell end"; A (env "%.end")])
    )

let () =
  rule "exec"
    ~prod:"%(test).%(backend).exec"
    ~dep:"%(test).spec"
    (fun env build ->
      let spec = Spec.parse (env "%(test).spec") in
      let os = Spec.backend_of_string (env "%(backend)") in
      let prod = env "%(test).%(backend).exec" in
      if Spec.backend_is_supported os spec then begin
        ignore (build [[ env "%(test).%(backend).build" ]]);
        Echo (["OK"], prod)
      end else
        Echo (["SKIPPED (backend not supported for this test)"],prod)
    )

let () =
  rule "run"
    ~prod:"%(spec).run"
    ~dep:"%(spec).suite"
    (fun env builder ->
       let spec = env "%(spec)" in
       let deps = string_list_of_file (spec ^ ".spec") in
       let targets = List.map (fun dep ->
         [dep ^ ".start"]
       ) deps in
       ignore(builder targets);
       let targets = List.map (fun dep ->
         [dep ^ ".exec"]
       ) deps in
       ignore(builder targets);
        let targets = List.map (fun dep ->
         [dep ^ ".end"]
       ) deps in
       ignore(builder targets);
       Nop
    )
