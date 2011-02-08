open Ocamlbuild_plugin
open Command
open Ocamlbuild_pack.Ocaml_utils

let debug = true (* compile in debug mode with additional checks *)

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

  let cc = getenv "CC" ~default:"cc"
  let ar = getenv "AR" ~default:"ar"
  let cflags = ref ["-Wall"; "-g"]

  (* All the xen cflags for compiling against an embedded environment *)
  let xen_incs =
    (* base GCC standard include dir *)
    let gcc_install = 
      let cmd = sf "LANG=C %s -print-search-dirs | sed -n -e 's/install: \\(.*\\)/\\1/p'" cc in
      Util.run_and_read cmd in
    (* root dir of xen bits *)
    let rootdir = sf "%s/runtime_xen" Pathname.pwd in
    let root_incdir = sf "%s/include" rootdir in
    (* Basic cflags *)
    let all_cflags = List.map (fun x -> A x)
      [ "-U"; "__linux__"; "-U"; "__FreeBSD__"; 
        "-U"; "__sun__"; "-D__MiniOS__";
        "-D__MiniOS__"; "-D__x86_64__";
        "-D__XEN_INTERFACE_VERSION__=0x00030205";
        "-D__INSIDE_MINIOS__";
        "-nostdinc"; "-std=gnu99"; "-fno-stack-protector"; 
        "-m64"; "-mno-red-zone"; "-fno-reorder-blocks";
        "-fstrict-aliasing"; "-momit-leaf-frame-pointer"; "-mfancy-math-387"
      ] in
    (* Include dirs *)
    let incdirs= A ("-I"^gcc_install^"include") :: List.flatten (
      List.map (fun x ->[A"-isystem"; A (sf "%s/%s" root_incdir x)])
        [""; "mini-os"; "mini-os/x86"]) in
    all_cflags @ incdirs 

  (* The private libm include dir *)
  let libm_incs =
    [ A (sf "-I%s/runtime_xen/libm" Pathname.pwd) ]

  (* defines used by the ocaml runtime, as well as includes *)
  let ocaml_debug_inc = if debug then [A "-DDEBUG"] else []
  let ocaml_incs = [ 
    A "-DCAML_NAME_SPACE"; A "-DNATIVE_CODE"; A "-DTARGET_amd64"; A "-DSYS_xen";
    A (sf "-I%s/runtime_xen/ocaml" Pathname.pwd) ] @ ocaml_debug_inc
 
  (* dietlibc bits, mostly extra warnings *)
  let dietlibc_incs = [
    A "-Wextra"; A "-Wchar-subscripts"; A "-Wmissing-prototypes";
    A "-Wmissing-declarations"; A "-Wno-switch"; A "-Wno-unused"; A "-Wredundant-decls"; A "-D__dietlibc__";
    A (sf "-I%s/runtime_xen/dietlibc" Pathname.pwd)
  ]

  let ocamlc_where = Lazy.force stdlib_dir

  let cc_cflags = List.map (fun x -> A x) !cflags

  let cc_c tags arg out =
    let tags = tags++"cc"++"c" in
    Cmd (S (A cc :: [ A"-c"; T(tags++"compile"); A"-I"; Px ocamlc_where; A"-o"; Px out; P arg]))

  let cc_compile_c_implem ?tag c o env build =
    let c = env c and o = env o in
    cc_c (tags_of_pathname c++"implem"+++tag) c o

  let cc_archive clib a path env build =
    let clib = env clib and a = env a and path = env path in
    let objs = List.map (fun x -> path / x) (string_list_of_file clib) in
    let resluts = build (List.map (fun x -> [x]) objs) in
    let objs = List.map (function
      | Outcome.Good o -> o
      | Outcome.Bad exn -> raise exn) resluts in
    Cmd(S[A ar; A"rc"; Px a; T(tags_of_pathname a++"c"++"archive"); atomize objs])

  let () =
    rule "cc: .c -> .o include ocaml dir"
      ~tags:["cc"; "c"]
      ~prod:"%.o" ~dep:"%.c"
      (cc_compile_c_implem "%.c" "%.o");

    rule "cc: .S -> .o assembly compile"
      ~prod:"%.o" ~dep:"%.S"
      (cc_compile_c_implem ~tag:"asm" "%.S" "%.o");
 
    rule "archive: cclib .o -> .a archive" 
      ~prod:"%(path:<**/>)lib%(libname:<*> and not <*.*>).a"
      ~dep:"%(path)lib%(libname).cclib"
      (cc_archive "%(path)lib%(libname).cclib" "%(path)lib%(libname).a" "%(path)")

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
    flag ["ocaml"; "compile" ; "pa_lwt"] & S[A"-pp"; A(sf "camlp4o -I %s pa_lwt.cma" (lib "syntax"))];
    flag ["ocaml"; "ocamldep"; "pa_lwt"] & S[A"-pp"; A(sf "camlp4o -I %s pa_lwt.cma" (lib "syntax"))];

    (* some C code will use local ev.h *)
    dep  ["c"; "compile"; "include_libev"] libev_files;

    (* unix code deps *)
    dep ["c"; "compile"; "unix_header"] ["runtime_unix/istring.h"];

    (* base cflags for C code *)
    flag ["c"; "compile"] & S CC.cc_cflags;
    flag ["asm"; "compile"] & S [A "-D__ASSEMBLY__"];

    (* xen code needs special cflags *)
    flag ["c"; "compile"; "include_xen"] & S CC.xen_incs;
    flag ["c"; "compile"; "include_libm"] & S CC.libm_incs;
    flag ["c"; "compile"; "include_ocaml"] & S CC.ocaml_incs;
    flag ["c"; "compile"; "include_dietlibc"] & S CC.dietlibc_incs;
    flag ["c"; "compile"; "optimization_ok"] & S [A"-O2"];
    flag ["c"; "compile"; "pic"] & S [A"-fPIC"];
   
  | _ -> ()
end
