open Ocamlbuild_plugin
open Command

let sf = Printf.sprintf
let lib x =
  let r =
    try 
      Sys.getenv "MIRAGELIB" ^ "/std"
    with Not_found ->
      "../../std/_build" 
  in
  sf "%s/%s" r x

(* Utility functions (e.g. to execute a command and return lines read) *)
module Util = struct
  let split s ch =
    let x = ref [] in
    let rec go s =
      let pos = String.index s ch in
      x := (String.before s pos)::!x;
      go (String.after s (pos + 1))
    in
    try
      go s
    with Not_found -> !x

    let split_nl s = split s '\n'

    let run_and_read x = List.hd (split_nl (Ocamlbuild_pack.My_unix.run_and_read x))
end

(* Rules to directly invoke GCC rather than go through OCaml. *)
module CC = struct
  let cc = ref (A"cc")
  let ocamlc_where = Util.run_and_read "ocamlc -where" 
  let cflags = [A"-O2"; A("-Wall")]
  let cc_c tags arg out =
    let tags = tags++"cc"++"c" in
    Cmd (S (!cc :: cflags @ [ A"-c"; T(tags++"compile");
                 A"-I"; Px ocamlc_where;
                 A"-o"; Px out; P arg]))

  let cc_compile_c_implem ?tag c o env build =
    let c = env c and o = env o in
    cc_c (tags_of_pathname c++"implem"+++tag) c o

  let () =
    rule "cc: .c -> .o include ocaml dir"
      ~tags:["cc"; "c"]
      ~prod:"%.o" ~dep:"%.c"
      (cc_compile_c_implem "%.c" "%.o");
end

(* Need to register manual dependency on libev included files/
   The C files below are also #included, so need to be present *)
let libev_files = List.map (fun x -> "runtime_unix/" ^ x) 
  ["ev.h"; "ev_vars.h"; "ev_wrap.h"; "ev.c"; 
   "ev_select.c"; "ev_epoll.c"; "ev_kqueue.c"; "ev_poll.c"; "ev_port.c"]

let _ = dispatch begin function
  | After_rules ->

    (* do not compile and pack with the standard lib *)
    flag ["ocaml"; "compile"] & S [A"-I"; A (lib "lib"); A"-nostdlib"];
    flag ["ocaml"; "pack"   ] & S [A"-I"; A (lib "lib"); A"-nostdlib"];

    (* use pa_lwt syntax extension if needed *)
    flag ["ocaml"; "compile" ; "pa_lwt"] & S[A"-pp"; A(sf "camlp4o -I %s pa_lwt.cmo" (lib "syntax"))];
    flag ["ocaml"; "ocamldep"; "pa_lwt"] & S[A"-pp"; A(sf "camlp4o -I %s pa_lwt.cmo" (lib "syntax"))];

    (* some C code will use local ev.h *)
    dep  ["c"; "compile"; "include_libev"] libev_files;
  | _ -> ()
end
