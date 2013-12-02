(*
 * Copyright (c) 2013 Thomas Gazagnaire <thomas@gazagnaire.org>
 * Copyright (c) 2013 Anil Madhavapeddy <anil@recoil.org>
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


let (|>) a f = f a

let (/) = Filename.concat

let finally f cleanup =
  try
    let res = f () in cleanup (); res
  with exn -> cleanup (); raise exn

let output_kv oc kvs sep =
  List.iter (fun (k,v) -> Printf.fprintf oc "%s %s %s\n" k sep v) kvs

let lines_of_file file =
  let ic = open_in file in
  let lines = ref [] in
  let rec aux () =
    let line =
      try Some (input_line ic)
      with _ -> None in
    match line with
    | None   -> ()
    | Some l ->
      lines := l :: !lines;
      aux () in
  aux ();
  close_in ic;
  List.rev !lines

let strip str =
  let p = ref 0 in
  let l = String.length str in
  let fn = function
    | ' ' | '\t' | '\r' | '\n' -> true
    | _ -> false in
  while !p < l && fn (String.unsafe_get str !p) do
    incr p;
  done;
  let p = !p in
  let l = ref (l - 1) in
  while !l >= p && fn (String.unsafe_get str !l) do
    decr l;
  done;
  String.sub str p (!l - p + 1)

let cut_at s sep =
  try
    let i = String.index s sep in
    let name = String.sub s 0 i in
    let version = String.sub s (i+1) (String.length s - i - 1) in
    Some (name, version)
  with _ ->
    None

let split s sep =
  let rec aux acc r =
    match cut_at r sep with
    | None       -> List.rev (r :: acc)
    | Some (h,t) -> aux (strip h :: acc) t in
  aux [] s

let key_value line =
  match cut_at line ':' with
  | None       -> None
  | Some (k,v) -> Some (k, strip v)

let filter_map f l =
  let rec loop accu = function
    | []     -> List.rev accu
    | h :: t ->
        match f h with
        | None   -> loop accu t
        | Some x -> loop (x::accu) t in
  loop [] l

let subcommand ~prefix (command, value) =
  let p1 = String.uncapitalize prefix in
  match cut_at command '-' with
  | None      -> None
  | Some(p,n) ->
    let p2 = String.uncapitalize p in
    if p1 = p2 then
      Some (n, value)
    else
      None

let append oc fmt =
  Printf.kprintf (fun str ->
    Printf.fprintf oc "%s\n" str
  ) fmt

let newline oc =
  append oc ""

let error fmt =
  Printf.kprintf (fun str ->
    Printf.eprintf "[mirari] ERROR: %s\n%!" str;
    exit 1;
  ) fmt

let info fmt =
  Printf.kprintf (Printf.printf "[mirari] %s\n%!") fmt

let debug fmt =
  Printf.kprintf (Printf.printf "[mirari] %s\n%!") fmt

let remove file =
  if Sys.file_exists file then (
    info "+ Removing %s." file;
    Sys.remove file
  )

let command ?switch fmt =
  Printf.kprintf (fun str ->
    let cmd = match switch with
      | None -> str
      | Some cmp -> Printf.sprintf "opam config exec \"%s\" --switch=%s" str cmp in
    info "+ Executing: %s" cmd;
    match Sys.command cmd with
    | 0 -> ()
    | i -> error "The command %S exited with code %d." cmd i
  ) fmt

let opam_install ?switch deps =
  let deps_str = String.concat " " deps in
  match switch with
  | None -> command "opam install --yes %s" deps_str
  | Some cmp -> command "opam install --yes %s --switch=%s" deps_str cmp

let in_dir dir f =
  let pwd = Sys.getcwd () in
  let reset () =
    if pwd <> dir then Sys.chdir pwd in
  if pwd <> dir then Sys.chdir dir;
  try let r = f () in reset (); r
  with e -> reset (); raise e

let cmd_exists s =
  Sys.command ("which " ^ s ^ " > /dev/null") = 0

let read_command fmt =
  let open Unix in
  Printf.ksprintf (fun cmd ->
    let () = info "+ Executing: %s" cmd in
    let ic, oc, ec = open_process_full cmd (environment ()) in
    let buf1 = Buffer.create 64
    and buf2 = Buffer.create 64 in
    (try while true do Buffer.add_channel buf1 ic 1 done with End_of_file -> ());
    (try while true do Buffer.add_channel buf2 ec 1 done with End_of_file -> ());
    match close_process_full (ic,oc,ec) with
    | WEXITED 0   -> Buffer.contents buf1
    | WSIGNALED n -> error "process killed by signal %d" n
    | WSTOPPED n  -> error "process stopped by signal %d" n
    | WEXITED r   -> error "command terminated with exit code %d\nstderr: %s" r (Buffer.contents buf2)) fmt

let generated_by_mirari =
  let t = Unix.gettimeofday () in
  let months = [| "Jan"; "Feb"; "Mar"; "Apr"; "May"; "Jun";
                  "Jul"; "Aug"; "Sep"; "Oct"; "Nov"; "Dec" |] in
  let days = [| "Sun"; "Mon"; "Tue"; "Wed"; "Thu"; "Fri"; "Sat" |] in
  let time = Unix.gmtime t in
  let date =
    Printf.sprintf "%s, %d %s %d %02d:%02d:%02d GMT"
      days.(time.Unix.tm_wday) time.Unix.tm_mday
      months.(time.Unix.tm_mon) (time.Unix.tm_year+1900)
      time.Unix.tm_hour time.Unix.tm_min time.Unix.tm_sec in
  Printf.sprintf "Generated by Mirari (%s)." date

let ocaml_version () =
  let version =
    match cut_at Sys.ocaml_version '+' with
    | Some (version, _) -> version
    | None              -> Sys.ocaml_version in
  match split version '.' with
  | major :: minor :: _ ->
    begin
      try int_of_string major, int_of_string minor
      with _ -> 0, 0
    end
  | _ -> 0, 0

module StringSet = struct

  include Set.Make(String)

  let of_list l =
    let s = ref empty in
    List.iter (fun e -> s := add e !s) l;
    !s

end

module StringMap = Map.Make(String)

type mode = [
  | `Unix of [ `Direct | `Socket ]
  | `Xen
]

type document = {
  oc: out_channel;
  mutable modules: string StringMap.t;
}

let empty filename =
  let oc = open_out filename in
  append oc "(* %s *)" generated_by_mirari;
  newline oc;
  { oc; modules = StringMap.empty; }

module type CONFIGURABLE = sig
  type t
  val name: t -> string
  val packages: t -> mode -> string list
  val libraries: t -> mode -> string list
  val prepare: t -> mode -> unit
  val output: t -> mode -> document -> unit
end

module Headers = struct

  let output oc =
    append oc "(* %s *)" generated_by_mirari;
    newline oc

end

module IO_page = struct

  (** Memory allocation interface. *)

  type t = unit

  let name _ = "io_page"

  let packages _ = function
    | `Unix _ -> ["io-page-unix"]
    | `Xen    -> ["io-page-xen"]

  let libraries t mode =
    packages t mode

  let prepare _ _ = ()

  let output t mode d =
    let name = name t in
    if not (StringMap.mem name d.modules) then
      d.modules <- StringMap.add name "Io_page" d.modules

end

module Clock = struct

  (** Clock operations. *)

  type t = unit

  let name _ = "console"

  let packages _ _ =
    ["mirage-console"]

  let libraries _ _ =
    ["mirage-console"]

  let prepare _ _ = ()

  let output t mode d =
    let name = name t in
    if not (StringMap.mem name d.modules) then
      d.modules <- StringMap.add name "Clock" d.modules

end

module KV_RO = struct

  type t = {
    name   : string;
    dirname: string;
  }

  let name t = t.name

  let packages _ _ = [
    "mirage-types";
    "lwt";
    "io-page";
    "cstruct";
    "ocaml-crunch";
  ]

  let libraries _ mode = [
    "mirage-types";
    "lwt";
    "cstruct";
    match mode with
    | `Unix _ -> "io-page-unix"
    | `Xen    -> "io-page-xen"
  ]

  let prepare t _ =
    if not (cmd_exists "ocaml-crunch") then
      error "ocaml-crunch not found, stopping.";
    let file = Printf.sprintf "static_%s.ml" t.name in
    if Sys.file_exists t.dirname then (
      info "Creating %s." file;
      command "ocaml-crunch -o %s %s" file t.dirname
    ) else
      error "The directory %s does not exist." t.dirname

  let output t mode d =
    if not (StringMap.mem t.name d.modules) then (
      let m = "Static_" ^ t.name in
      d.modules <- StringMap.add t.name m d.modules;
      append d.oc "let %s =" t.name;
      append d.oc "  Static_%s.connect ()" t.name;
    )

end

module Console = struct

  type t = unit

  let name _ = "console"

  let packages _ _ =
    ["mirage-console"]

  let libraries _ _ =
    ["mirage-console"]

  let prepare _ _ = ()

  let output t mode d =
    let name = name t in
    if not (StringMap.mem name d.modules) then
      d.modules <- StringMap.add name "Console" d.modules

end

module Block = struct

  type t = {
    name     : string;
    filename : string;
    read_only: bool;
  }

  let name t = t.name

  let packages _ mode = [
    "mirage-block";
    match mode with
    | `Unix _ -> "mirage-block-unix"
    | `Xen    -> "mirage-block-xen"
  ]

  let libraries _ = function
    | `Unix _ -> ["mirage-block-unix"]
    | `Xen    -> ["mirage-block-xen"]

  let prepare t _ = ()

  let output t mode d =
    if not (StringMap.mem t.name d.modules) then (
      let m = "Mirage_block.Block" in
      d.modules <- StringMap.add t.name m d.modules;
      append d.oc "let %s =" t.name;
      append d.oc "  %s.connect %S" m t.filename;
    )

end

module FAT = struct

  type t = {
    name : string;
    block: Block.t;
  }

  let name t = t.name

  let packages t mode = [
    "ocaml-fat";
  ] @
    Block.packages t.block mode

  let libraries t mode = [
    "ocaml-fat";
  ] @
    Block.libraries t.block mode

  let prepare _ _ = ()

  let output t mode d =
    if not (StringMap.mem t.name d.modules) then (
      Block.output t.block mode d;
      let m = "Fat_" ^ t.name in
      d.modules <- StringMap.add t.name m d.modules;
      append d.oc "module %s = Fat.Fs.Make(%s)(Io_page)"
        m (StringMap.find t.block.Block.name d.modules);
      append d.oc "let %s =" t.name;
      append d.oc " %s >>= function" (Block.name t.block);
      append d.oc " | `Error e -> fail (%s.Block_error e)" m;
      append d.oc " | `Ok dev  -> %s.openfile dev" m
    )

end

(** {2 Network configuration} *)

module IP = struct

  (** IP settings. *)

  type ipv4 = {
    address: Ipaddr.V4.t;
    netmask: Ipaddr.V4.t;
    gateway: Ipaddr.V4.t list;
  }

  type conf =
    | DHCP
    | IPv4 of ipv4

  type t = {
    name: string;
    conf: conf;
  }

  let packages _ mode = [
    "mirage-net";
    match mode with
    | `Unix `Direct -> "mirage-net-unix-direct"
    | `Unix `Socket -> "mirage-net-unix-socket"
    | `Xen          -> "mirage-net-xen"
  ]

  let libraries _ mode = [
    "mirage-net";
  ]

  let name t = t.name

  let prepare _ _ = ()

  let output _ _ _ =
    ()

end

module HTTP = struct

  type t = {
    port   : int;
    address: Ipaddr.V4.t option;
    static : KV_RO.t option;
  }

  let name t = "http_" ^ string_of_int t.port

  let packages t mode = [
    "cohttp"
  ] @
    match t.static with
    | None   -> []
    | Some s -> KV_RO.packages s mode

  let libraries t mode = [
    "cohttp.mirage";
  ] @
    match t.static with
    | None   -> []
    | Some s -> KV_RO.libraries s mode

  let prepare _ _ = ()

  let output _ _ _ = ()

end

module Driver = struct

  type t =
    | IO_page of IO_page.t
    | Console of Console.t
    | Clock of Clock.t
    | KV_RO of KV_RO.t
    | Block of Block.t
    | FAT of FAT.t
    | IP of IP.t
    | HTTP of HTTP.t

  let name = function
    | IO_page x -> IO_page.name x
    | Console x -> Console.name x
    | Clock x   -> Clock.name x
    | KV_RO x   -> KV_RO.name x
    | Block x   -> Block.name x
    | FAT x     -> FAT.name x
    | IP x      -> IP.name x
    | HTTP x    ->  HTTP.name x

  let packages = function
    | IO_page x -> IO_page.packages x
    | Console x -> Console.packages x
    | Clock x   -> Clock.packages x
    | KV_RO x   -> KV_RO.packages x
    | Block x   -> Block.packages x
    | FAT x     -> FAT.packages x
    | IP x      -> IP.packages x
    | HTTP x    -> HTTP.packages x

  let libraries = function
    | IO_page x -> IO_page.libraries x
    | Console x -> Console.libraries x
    | Clock x   -> Clock.libraries x
    | KV_RO x   -> KV_RO.libraries x
    | Block x   -> Block.libraries x
    | FAT x     -> FAT.libraries x
    | IP x      -> IP.libraries x
    | HTTP x    -> HTTP.libraries x

  let prepare = function
    | IO_page x -> IO_page.prepare x
    | Console x -> Console.prepare x
    | Clock x   -> Clock.prepare x
    | KV_RO x   -> KV_RO.prepare x
    | Block x   -> Block.prepare x
    | FAT x     -> FAT.prepare x
    | IP x      -> IP.prepare x
    | HTTP x    -> HTTP.prepare x

  let output = function
    | IO_page x -> IO_page.output x
    | Console x -> Console.output x
    | Clock x   -> Clock.output x
    | KV_RO x   -> KV_RO.output x
    | Block x   -> Block.output x
    | FAT x     -> FAT.output x
    | IP x      -> IP.output x
    | HTTP x    -> HTTP.output x

end

module Job = struct

  type t = {
    name   : string;
    handler: string;
    params : Driver.t list;
  }

  let count = ref 0

  let create handler params =
    incr count;
    let name = "job" ^ string_of_int !count in
    { name; handler; params }

  let name t =
    t.name

  let fold fn { params } =
    let s = List.fold_left (fun set param ->
        let s = fn param in
        StringSet.union set (StringSet.of_list s)
      ) StringSet.empty params in
    StringSet.elements s

  let iter fn { params } =
    List.iter fn params

  let packages t mode =
    fold (fun d -> Driver.packages d mode) t

  let libraries t mode =
    fold (fun d -> Driver.libraries d mode) t

  let prepare t mode =
    iter (fun d -> Driver.prepare d mode) t

  let output t mode doc =
    iter (fun p -> Driver.output p mode doc) t;
    newline doc.oc;
    let modules = List.map (fun p ->
        let m = StringMap.find (Driver.name p) doc.modules in
        Printf.sprintf "(%s)" m
      ) t.params in
    let names = List.map Driver.name t.params in
    let m = String.capitalize t.name in
    append doc.oc "module %s = %s%s" m t.handler (String.concat "" modules);
    append doc.oc "let %s = %s.start %s" t.name m (String.concat " " names);
    newline doc.oc

  let all : t list ref =
    ref []

  let reset () =
    all := []

  let register j =
    all := List.map (fun (n,p) -> create n p) j @ !all

  let registered () =
    !all

end

type t = {
  name: string;
  root: string;
  jobs: Job.t list;
}

let name t = t.name

let fold fn { jobs } =
  let s = List.fold_left (fun set job ->
      let s = fn job in
      StringSet.union set (StringSet.of_list s)
    ) StringSet.empty jobs in
  StringSet.elements s

let iter fn { jobs } =
  List.iter fn jobs

let packages t mode =
  fold (fun j -> Job.packages j mode) t

let libraries t mode =
  fold (fun j -> Job.libraries j mode) t

let prepare_main t mode =
  iter (fun j -> Job.prepare j mode) t

let prepare_myocamlbuild_ml t mode =
  let minor, major = ocaml_version () in
  if minor < 4 || major < 1 then (
    (* Previous ocamlbuild versions weren't able to understand the
       --output-obj rules *)
    let file = Printf.sprintf "%s/myocamlbuild.ml" t.root in
    let oc = open_out file in
    append oc "(* %s *)" generated_by_mirari;
    newline oc;
    append oc
      "open Ocamlbuild_pack;;\n\
       open Ocamlbuild_plugin;;\n\
       open Ocaml_compiler;;\n\
       \n\
       let native_link_gen linker =\n\
      \  link_gen \"cmx\" \"cmxa\" !Options.ext_lib [!Options.ext_obj; \"cmi\"] linker;;\n\
       \n\
       let native_output_obj x = native_link_gen ocamlopt_link_prog\n\
      \  (fun tags -> tags++\"ocaml\"++\"link\"++\"native\"++\"output_obj\") x;;\n\
       \n\
       rule \"ocaml: cmx* & o* -> native.o\"\n\
      \  ~tags:[\"ocaml\"; \"native\"; \"output_obj\" ]\n\
      \  ~prod:\"%%.native.o\" ~deps:[\"%%.cmx\"; \"%%.o\"]\n\
      \  (native_output_obj \"%%.cmx\" \"%%.native.o\");;\n\
       \n\
       \n\
       let byte_link_gen = link_gen \"cmo\" \"cma\" \"cma\" [\"cmo\"; \"cmi\"];;\n\
       let byte_output_obj = byte_link_gen ocamlc_link_prog\n\
      \  (fun tags -> tags++\"ocaml\"++\"link\"++\"byte\"++\"output_obj\");;\n\
       \n\
       rule \"ocaml: cmo* -> byte.o\"\n\
      \  ~tags:[\"ocaml\"; \"byte\"; \"link\"; \"output_obj\" ]\n\
       ~prod:\"%%.byte.o\" ~dep:\"%%.cmo\"\n\
      \  (byte_output_obj \"%%.cmo\" \"%%.byte.o\");;";
    close_out oc
  )

let prepare_makefile t mode =
  let file = Printf.sprintf "%s/Makefile" t.root in
  let libraries =
    let l = libraries t mode in
    (* XXX: weird dependency error on OCaml < 4.01 *)
    let minor, major = ocaml_version () in
    let l =
      if minor < 4 || major < 1 then "lwt.syntax" :: l
      else l in
    match l with
    | [] -> ""
    | ls -> "-pkgs " ^ String.concat "," ls in
  let packages = String.concat " " (packages t mode) in
  let oc = open_out file in
  append oc "# %s" generated_by_mirari;
  newline oc;
  append oc "LIBS   = %s" libraries;
  append oc "PKGS   = %s" packages;
  append oc "SYNTAX = -tags \"syntax(camlp4o)\"\n\
             FLAGS  = -g -lflag -linkpkg\n\
             BUILD  = ocamlbuild -classic-display -use-ocamlfind $(LIBS) $(SYNTAX) $(FLAGS)\n\
             OPAM   = opam";
  newline oc;
  append oc "PHONY: all depends clean\n\
             all: build\n\
             \n\
             depends:\n\
            \    $(OPAM) install $(PKGS)\n\
             \n\
             _build/.stamp:\n\
            \    rm -rf _build\n\
            \    mkdir -p _build/lib\n\
            \    @touch $@\n\
             \n\
             main.native: _build/.stamp\n\
            \    $(BUILD) main.native\n\
             \n\
             main.native.o: _build/.stamp\n\
            \    $(BUILD) main.native.o";
  newline oc;
  begin match mode with
    | `Xen ->
      append oc "all: main.native.o";
      let path = read_command "ocamlfind printconf path" in
      let lib = strip path ^ "/mirage-xen" in
      append oc "    ld -d -nostdlib -m elf_x86_64 -T %s/mirage-x86_64.lds %s/x86_64.o \\\n\
                \      main.native.o %s/libocaml.a %s/libxen.a \\\n\
                \      %s/libxencaml.a %s/libdiet.a %s/libm.a %s/longjmp.o -o main.xen"
        lib lib lib lib lib lib lib lib;
      append oc "    ln -nfs _build/main.xen mir-%s.xen" t.name;
      append oc "    nm -n mir-%s.xen | grep -v '\\(compiled\\)\\|\\(\\.o$$\\)\\|\\( [aUw] \\\n\
                \      \\)\\|\\(\\.\\.ng$$\\)\\|\\(LASH[RL]DI\\)' > mir-%s.map" t.name t.name
    | `Unix _ ->
      append oc "all: main.native";
      append oc "    ln -nfs _build/main.native mir-%s" t.name;
  end;
  newline oc;
  append oc "clean:\n\
            \    ocamlbuild -clean";
  close_out oc

let prepare_opam t mode =
  info "Installing OPAM packages.";
  match packages t mode with
  | [] -> if not (cmd_exists "opam") then error "OPAM is not installed."
  | ps -> opam_install ps

let prepare t mode =
  prepare_main t mode;
  prepare_myocamlbuild_ml t mode;
  prepare_makefile t mode

let output t mode doc =
  iter (fun j -> Job.output j mode doc) t;
  newline doc.oc;
  let jobs = List.map Job.name t.jobs in
  append doc.oc "let () =";
  append doc.oc "  OS.Main.run (Lwt.join [%s])" (String.concat "; " jobs)

let configure t ~mode ~install =
  if install then prepare_opam t mode;
  prepare t mode;
  let main_ml = Filename.concat t.root "main.ml" in
  info "Generating %s" main_ml;
  let doc = empty main_ml in
  output t mode doc

(*
  (* Generate the Makefile *)
  Build.output ~mode t.build;
  (* Generate the XL config file if backend = Xen *)
  if mode = `xen then XL.output t.name t.config;
  (* install OPAM dependencies *)
  if not no_install then Build.prepare ~mode t.build;
  (* crunch *)
  call_crunch_scripts t

*)

(*

module XL = struct
  let output name kvs =
    info "+ creating %s" (name ^ ".xl");
    let oc = open_out (name ^ ".xl") in
    finally
      (fun () ->
         output_kv oc (["name", "\"" ^ name ^ "\"";
                        "kernel", "\"mir-" ^ name ^ ".xen\""] @
                         filter_map (subcommand ~prefix:"xl") kvs) "=")
      (fun () -> close_out oc);
end

let call_crunch_scripts t =
  List.iter FS.process t.fs

let run ~mode file =
  let file = scan_conf file in
  let t = create mode file in
  match mode with
  |`unix _ ->
    info "+ unix socket mode";
    Unix.execv ("mir-" ^ t.name) [||] (* Just run it! *)
  |`xen -> (* xen backend *)
    info "+ xen mode";
    Unix.execvp "xl" [|"xl"; "create"; "-c"; t.name ^ ".xl"|]
*)

(* Compile the configuration file and attempt to dynlink it.
 * It is responsible for registering an application via
 * [Mirari_config.register] in order to have an observable
 * side effect to this command. *)
let compile_and_dynlink file =
  let file = Dynlink.adapt_filename file in
  command "rm -f _build/%s.*" (Filename.chop_extension file);
  command "ocamlbuild -use-ocamlfind -pkg mirari %s" file;
  try Dynlink.loadfile ("_build/"^file)
  with Dynlink.Error err -> error "Error loading config: %s" (Dynlink.error_message err)

(* If a configuration file is specified, then use that.
 * If not, then scan the curdir for a `config.ml` file.
 * If there is more than one, then error out. *)
let scan_conf = function
  | Some f ->  info "Using specified config file %s" f; f
  | None   ->
    let files = Array.to_list (Sys.readdir ".") in
    match List.filter ((=) "config.ml") files with
    | [] -> error "No configuration file ending in .conf found.\n\
                   You'll need to create one to let Mirari know what do do."
    | [f] -> info "Using scanned config file %s" f; f
    | _   -> error "There is more than one config.ml in the current working directory.\n\
                    Please specify one explicitly on the command-line."

let load file =
  let file = scan_conf file in
  Job.reset ();
  compile_and_dynlink file;
  { name ="main";
    root = Filename.dirname file;
    jobs = Job.registered () }

let run _ = failwith "TODO"
