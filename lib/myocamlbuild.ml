open Ocamlbuild_plugin
open Command
open Ocamlbuild_pack.Ocaml_compiler
open Ocamlbuild_pack.Ocaml_utils
open Ocamlbuild_pack.Tools

let ps = Printf.sprintf
let ep = Printf.eprintf

let debug = false
let profiling = false

(* This decides the global OS backend. It could be moved into explicit
   dependencies in the future, but for now is set as an environment
   variable *)
let os =
  let os = getenv "MIRAGEOS" ~default:"unix" in
  if os <> "unix" && os <> "xen" && os <> "node" then
    (ep "`%s` is not a supported OS\n" os; exit (-1))
  else
    (Ocamlbuild_pack.Log.dprintf 0 "OS: %s" os; os)

(* This decides which Net module to use (direct or socket) *)
let flow = 
  let flow = getenv "MIRAGEFLOW" ~default:"direct" in
  if flow <> "direct" && flow <> "socket" then
    (ep "`%s` is not a supported Flow type\n" flow; exit (-1))
  else
    (Ocamlbuild_pack.Log.dprintf 0 "Flow: %s" flow; flow)

let _ =
  let subdir = match os,flow with
  | "unix","socket" -> "unix-socket"
  | "unix","direct" -> "unix-direct"
  | "xen" ,"direct" -> "xen-direct"
  | "node","socket" -> "node-socket"
  | _ -> ep "%s-%s is not a supported kernel combination\n" os flow; exit (-1) in
  Options.build_dir := "_build/" ^ subdir

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

(* OS detection *)
module OS = struct

  type u = Linux | Darwin
  type t = Unix of u | Xen | Node
  let host = match String.lowercase (Util.run_and_read "uname -s") with
    | "linux"  -> Unix Linux
    | "darwin" -> Unix Darwin
    | os -> Printf.eprintf "`%s` is not a supported host OS\n" os; exit (-1)

  let unix_ext = match host with
    | Unix Linux  -> "linux"
    | Unix Darwin -> "macosx"
    | _ -> Printf.eprintf "unix_ext called on a non-UNIX host OS\n"; exit (-1)

  let target = match String.lowercase os with
    | "unix" -> host (* Map the target to the current host, as cross-compiling is no use *)
    | "xen"  -> Xen
    | "node" -> Node
    | x -> failwith ("unknown target os: " ^ x)
end

(* Rules for MPL compiler *)
module MPL = struct

  let mplc_bin = "mplc" 

  let mpl_c tags arg out =
    Cmd (S [A mplc_bin; A"-q"; T(tags++"mpl"); P arg; Sh">"; Px out])

  let mpl_compile mpl ml env build =
    let mpl = env mpl and ml = env ml in
    let tags = tags_of_pathname mpl in
    mpl_c tags mpl ml

  let () =
    rule "mpl: mpl -> ml"
      ~prod:"%.ml"
      ~dep:"%.mpl"
      (mpl_compile "%.mpl" "%.ml")
end

(* Rules to directly invoke GCC rather than go through OCaml. *)
module CC = struct

  let cc = getenv "CC" ~default:"cc"
  let ar = getenv "AR" ~default:"ar"
  let cflags = ref ["-Wall"; "-g"; "-O3"]

  (* All the xen cflags for compiling against an embedded environment *)
  let xen_incs =
    (* base GCC standard include dir *)
    let gcc_install =
      let cmd = ps "LANG=C %s -print-search-dirs | sed -n -e 's/install: \\(.*\\)/\\1/p'" cc in
      Util.run_and_read cmd in
    (* root dir of xen bits *)
    let rootdir = ps "%s/os/runtime_xen" Pathname.pwd in
    let root_incdir = ps "%s/include" rootdir in
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
      List.map (fun x ->[A"-isystem"; A (ps "%s/%s" root_incdir x)])
        [""; "mini-os"; "mini-os/x86"]) in
    all_cflags @ incdirs

  (* The private libm include dir *)
  let libm_incs =
    [ A (ps "-I%s/os/runtime_xen/libm" Pathname.pwd) ]

  (* defines used by the ocaml runtime, as well as includes *)
  let ocaml_debug_inc = if debug then [A "-DDEBUG"] else []
  let ocaml_incs = [
    A "-DCAML_NAME_SPACE"; A "-DNATIVE_CODE"; A "-DTARGET_amd64"; A "-DSYS_xen";
    A (ps "-I%s/os/runtime_xen/ocaml" Pathname.pwd) ] @ ocaml_debug_inc

  (* dietlibc bits, mostly extra warnings *)
  let dietlibc_incs = [
    A "-Wextra"; A "-Wchar-subscripts"; A "-Wmissing-prototypes";
    A "-Wmissing-declarations"; A "-Wno-switch"; A "-Wno-unused"; A "-Wredundant-decls"; A "-D__dietlibc__";
    A (ps "-I%s/os/runtime_xen/dietlibc" Pathname.pwd)
  ]

  let cc_cflags = List.map (fun x -> A x) !cflags

  let cc_c tags arg out =
    let tags = tags++"cc"++"c" in
    Cmd (S (A cc :: [ A"-c"; T(tags++"compile"); A"-I"; Px (Lazy.force stdlib_dir); A"-o"; Px out; P arg]))

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

    rule "cc: _linux.c -> _os.c platform file"
      ~prod:"%_os.c"
      ~dep:("%_" ^ OS.unix_ext ^ ".c")
      (fun env _ ->
        let filename = env "%" in
        ln_s (ps "%s_%s.c" (Pathname.basename filename) OS.unix_ext) (ps "%s_os.c" filename);
      );

    rule "archive: cclib .o -> .a archive"
      ~prod:"%(path:<**/>)lib%(libname:<*> and not <*.*>).a"
      ~dep:"%(path)lib%(libname).cclib"
      (cc_archive "%(path)lib%(libname).cclib" "%(path)lib%(libname).a" "%(path)")
end

(* Need to register manual dependency on libev included files/
   The C files below are #included, so need to be present but are
   not picked up by dependency analysis *)
let libev_files = List.map (fun x -> "os/runtime_unix/" ^ x)
  ["ev.h"; "ev_vars.h"; "ev_wrap.h"; "ev.c";
   "ev_select.c"; "ev_epoll.c"; "ev_kqueue.c"; "ev_poll.c"; "ev_port.c"]

let libexts = match OS.target with
  | OS.Node  -> ["cmo"; "cmi" ]
  | OS.Xen
  | OS.Unix _ -> ["cmx"; "cmi"; "a"; "o"]

let libbits dir name = List.map (fun e -> dir / name ^ "." ^ e) libexts

(* Compile the right OS module *)
let () = rule
  ~prods:(libbits "std" "oS")
  ~deps:(libbits ("os" / os) "oS")
   "OS link"
   (fun env builder ->
     Seq (List.map (fun f -> cp ("os" / os / "oS." ^ f) ("std" / "oS." ^ f)) libexts)
   )

(* Compile the right Net module *)
let () = rule
  ~prods:(libbits "std" "net")
  ~deps:(libbits ("net" / flow) "net")
   "Net link"
   (fun env builder ->
     Seq (List.map (fun f -> cp ("net" / flow / "net." ^ f) ("std" / "net." ^ f)) libexts)
   )

(* Block is only direct for Xen and socket/ for UNIX *)
let () =
   let mode = match OS.target with
     |OS.Xen -> "direct"
     |OS.Unix _ -> "socket"
     |OS.Node -> failwith "add block support to Node"
   in
   rule
  ~prods:(libbits "std" "block")
  ~deps:(libbits ("block" / mode) "block")
   "Block link"
   (fun env builder ->
     Seq (List.map (fun f -> cp ("block" / mode / "block." ^ f) ("std" / "block." ^ f)) libexts)
   )

let otherlibs = ["http"; "dns"; "dyntype"; "cow"; "resolv"]
(* Copy over independent modules *)
let () =
  List.iter (fun lib ->
    rule ~prods:(libbits "std" lib) ~deps:(libbits lib lib) (lib ^ " lib")
      (fun env _ -> Seq (List.map (fun f -> cp (lib / lib ^ "." ^ f) ("std" / lib ^ "." ^ f)) libexts))
  ) otherlibs     

let _ = dispatch begin function
  | After_rules ->
     (* do not compile and pack with the standard lib *)
     flag ["ocaml"; "compile"; "mirage" ] & S [A"-nostdlib"];
     flag ["ocaml"; "pack"; "mirage"] & S [A"-nostdlib"];
     if profiling then
       flag ["ocaml"; "compile"; "native" ] & S [A"-p"];

     (* use pa_`lib` syntax extension if the _tags file specifies it *)
     let p4_build = "../../../syntax/_build" in
     let cow_deps = "pa_ulex.cma pa_type_conv.cmo dyntype.cmo pa_dyntype.cmo str.cma" in
     List.iter (fun lib ->
      flag ["ocaml"; "compile" ; "pa_" ^ lib] & S[A"-pp"; A (ps "camlp4o -I %s pa_%s.cma" p4_build lib)];
      flag ["ocaml"; "ocamldep"; "pa_" ^ lib] & S[A"-pp"; A (ps "camlp4o -I %s pa_%s.cma" p4_build lib)];
      flag ["ocaml"; "doc"; "pa_" ^ lib] & S[A"-pp"; A (ps "camlp4o -I %s pa_%s.cma" p4_build lib)];
     ) [ "lwt"; "ulex"; "js"];
     List.iter (fun lib ->
      flag ["ocaml"; "compile" ; "pa_" ^ lib] & S[A"-pp"; A (ps "camlp4o -I %s %s pa_%s.cmo" p4_build cow_deps lib)];
      flag ["ocaml"; "ocamldep"; "pa_" ^ lib] & S[A"-pp"; A (ps "camlp4o -I %s %s pa_%s.cmo" p4_build cow_deps lib)];
      flag ["ocaml"; "doc"; "pa_" ^ lib] & S[A"-pp"; A (ps "camlp4o -I %s %s pa_%s.cmo" p4_build cow_deps lib)];
     ) ["cow"; "css"; "html"; "xml" ];

     (* add a dependency to the local pervasives, only used in stdlib compile *)
     dep ["ocaml"; "compile"; "need_pervasives"] ["std/pervasives.cmi"];

     (* For re-packing libraries (ocamlbuild doesnt pick up for-pack in a pack target) *)
     pflag ["ocaml"; "pack"] "for-repack" (fun param -> S [A "-for-pack"; A param]);

     (* net/direct includes *)
     Pathname.define_context "net/direct/mpl/protocols" ["mpl"];
     Pathname.define_context "net/direct/tcp" ["net/direct/mpl"; "net/direct"];
     Pathname.define_context "net/direct" ["net/direct/mpl"; "net/direct/tcp"; "net/direct/dhcp"];
     Pathname.define_context "net/direct/dhcp" ["net/direct/mpl"; "net/direct" ];

     (* some C code will use local ev.h *)
     dep  ["c"; "compile"; "include_libev"] libev_files;

     (* unix code deps *)
     dep ["c"; "compile"; "unix_header"] ["os/runtime_unix/istring.h"];

     (* base cflags for C code *)
     flag ["c"; "compile"] & S CC.cc_cflags;
     flag ["asm"; "compile"] & S [A "-D__ASSEMBLY__"];
     if profiling then
       flag ["c"; "compile"] & S [A"-pg"];

     (* xen code needs special cflags *)
     flag ["c"; "compile"; "include_xen"] & S CC.xen_incs;
     flag ["c"; "compile"; "include_libm"] & S CC.libm_incs;
     flag ["c"; "compile"; "include_ocaml"] & S CC.ocaml_incs;
     flag ["c"; "compile"; "include_dietlibc"] & S CC.dietlibc_incs;
     flag ["c"; "compile"; "pic"] & S [A"-fPIC"];

     ()
  | _ -> ()
end
