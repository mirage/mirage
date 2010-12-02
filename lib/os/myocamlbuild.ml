open Ocamlbuild_plugin
open Command
open Ocamlbuild_pack.Ocaml_utils

let sf = Printf.sprintf
let lib x =
  try 
    sf "%s/std/%s" (Sys.getenv "MIRAGELIB") x
  with Not_found ->
    "../../std/_build/" ^ x

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
 
  let cc = ref "cc"
  let cflags = ref ["-O2"; "-Wall"; "-fPIC"]

  (* All the xen cflags for compiling against an embedded environment *)
  let xen_incs =
    (* base GCC standard include dir *)
    let gcc_install = 
      let cmd = sf "LANG=C %s -print-search-dirs | sed -n -e 's/install: \\(.*\\)/\\1/p'" !cc in
      Util.run_and_read cmd in
    (* root dir of xen bits *)
    let rootdir = sf "%s/runtime_xen" Pathname.pwd in
    let root_incdir = sf "%s/include" rootdir in
    (* Basic cflags *)
    let all_cflags = List.map (fun x -> A x)
      [ "-U"; "__linux__"; "-U"; "__FreeBSD__"; 
       "-U"; "__sun__"; "-D__MiniOS__"; "-DHAVE_LIBC"; "-D__x86_64__";
       "-nostdinc"; "-std=gnu99"; "-fno-stack-protector"] in
    (* Include dirs *)
    let incdirs= List.flatten (
      List.map (fun x -> [A"-isystem"; A (sf "%s/%s" root_incdir x)])
        [""; "mini-os"; "mini-os/x86"]) in
    all_cflags @ incdirs 

  (* The private libm include dir *)
  let libm_incs =
    [ A (sf "-I%s/runtime_xen/libm" Pathname.pwd) ]

  let ocamlc_where = Lazy.force stdlib_dir

  let cc_cflags = List.map (fun x -> A x) !cflags

  let cc_c tags arg out =
    let tags = tags++"cc"++"c" in
    Cmd (S (A !cc :: [ A"-c"; T(tags++"compile");
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

    rule "cc: .S -> .o assembly compile"
      ~prod:"%.o" ~dep:"%.S"
      (cc_compile_c_implem "%.S" "%.o");
  
end

(* Need to register manual dependency on libev included files/
   The C files below are #included, so need to be present but are
   not picked up by dependency analysis *)
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

    (* base cflags for C code *)
    flag ["c"; "compile"] & S CC.cc_cflags;
    (* xen code needs special cflags *)
    flag ["c"; "compile"; "include_xen"] & S CC.xen_incs;
    flag ["c"; "compile"; "include_libm"] & S CC.libm_incs;
  | _ -> ()
end
