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

open MirageMisc

module StringSet = struct

  include Set.Make(String)

  let of_list l =
    let s = ref empty in
    List.iter (fun e -> s := add e !s) l;
    !s

end

module StringMap = Map.Make(String)

module Name = struct

  let names = Hashtbl.create 1024

  let create name =
    let n =
      try 1 + Hashtbl.find names name
      with Not_found -> 1 in
    Hashtbl.replace names name n;
    Printf.sprintf "%s%d" name n

end


type mode = [
  | `Unix of [ `Direct | `Socket ]
  | `Xen
]

type main_ml = {
  filename: string;
  oc: out_channel;
  mutable modules: string StringMap.t;
}

let main_ml_ref = ref None

let main_ml () = match !main_ml_ref with
  | None   -> failwith "No main.ml!"
  | Some m -> m

module type CONFIGURABLE = sig
  type t
  val name: t -> string
  val packages: t -> mode -> string list
  val libraries: t -> mode -> string list
  val configure: t -> mode -> unit
  val clean: t -> unit
end

module Headers = struct

  let output oc =
    append oc "(* %s *)" generated_by_mirage;
    newline oc

end

let driver_initialisation_error name =
  Printf.sprintf "fail (Mirage_types.V1.Driver_initialisation_error %S)" name

type _ device = D: 'a * (module CONFIGURABLE with type t = 'a) -> 'b device

module Device = struct

  let configure (D (t, (module M))) mode =
    M.configure t mode

  let name (D (t, (module M))) =
    M.name t

end

module Io_page = struct

  (** Memory allocation interface. *)

  type t = unit

  let name _ = "io_page"

  let packages _ = function
    | `Unix _ -> ["io-page-unix"]
    | `Xen    -> ["io-page-xen"]

  let libraries t mode =
    packages t mode

  let configure t mode =
    let name = name t in
    let d = main_ml () in
    if not (StringMap.mem name d.modules) then
      d.modules <- StringMap.add name "Io_page" d.modules

  let clean t =
    ()

end

type io_page = IO_PAGE

let io_page: io_page device = D ((), (module Io_page))

module Clock = struct

  (** Clock operations. *)

  type t = unit

  let name _ = "clock"

  let packages _ mode =
    match mode with
    | `Unix _ -> ["mirage-clock-unix"]
    | `Xen -> ["mirage-clock-xen"]

  let libraries _ mode =
    match mode with
    | `Unix _ -> ["mirage-clock-unix"]
    | `Xen -> ["mirage-clock-xen"]

  let configure t mode =
    let name = name t in
    let d = main_ml () in
    if not (StringMap.mem name d.modules) then (
      d.modules <- StringMap.add name "Clock" d.modules;
      append d.oc "let %s = return_unit" name;
    )

  let clean t =
    ()

end

type clock = CLOCK

let clock: clock device = D ((), (module Clock))

module Console = struct

  type t = unit

  let name _ = "console"

  let packages _ mode =
    match mode with
    | `Unix _ -> ["mirage-console-unix"]
    | `Xen -> ["mirage-console-xen"]

  let libraries _ mode =
    match mode with
    | `Unix _ -> ["mirage-console-unix"]
    | `Xen -> ["mirage-console-xen"]

  let configure t mode =
    let name = name t in
    let d = main_ml () in
    if not (StringMap.mem name d.modules) then (
      d.modules <- StringMap.add name "Console" d.modules;
      append d.oc "let %s = Console.connect \"\"" name;
      newline d.oc
    )

  let clean t =
    ()

end

type console = CONSOLE

let console: console device = D((), (module Console))

module Crunch = struct

  type t = {
    name   : string;
    dirname: string;
  }

  let name t = t.name

  let path ?name dirname =
    let name = match name with
      | None   -> Filename.basename dirname
      | Some n -> n in
    { name; dirname }

  let packages _ _ = [
    "mirage-types";
    "lwt";
    "cstruct";
    match mode with
    | `Unix _ -> "mirage-fs-unix"
    | `Xen    -> "crunch";
  ]

  let libraries _ mode = [
    "mirage-types";
    "lwt";
    "cstruct" ] @
    match mode with
    | `Unix _ -> ["io-page-unix"; "mirage-fs-unix"]
    | `Xen    -> ["io-page-xen" ]

  let ml t =
    Printf.sprintf "static_%s.ml" t.name

  let mli t =
    Printf.sprintf "static_%s.mli" t.name

  let configure t mode =
    let d = main_ml () in
    match mode with
    | `Xen -> (* Build a crunch filesystem *)
      if not (StringMap.mem t.name d.modules) then (

        if not (command_exists "ocaml-crunch") then
          error "ocaml-crunch not found, stopping.";
        let file = ml t in
        if Sys.file_exists t.dirname then (
          info "Generating %s/%s." (Sys.getcwd ()) file;
          command "ocaml-crunch -o %s %s" file t.dirname
        ) else
          error "The directory %s does not exist." t.dirname;

        let m = "Static_" ^ t.name in
        d.modules <- StringMap.add t.name m d.modules;
        append d.oc "let %s =" t.name;
        append d.oc "  Static_%s.connect ()" t.name;
        newline d.oc;
      )
    | `Unix _ ->
        d.modules <- StringMap.add t.name "Kvro_fs_unix" d.modules;
        append d.oc "let %s = " t.name;
        append d.oc "  Kvro_fs_unix.connect \"%s\"" t.dirname

  let clean t =
    remove (ml t);
    remove (mli t)

end

type kv_ro = KV_RO

let crunch: string -> kv_ro device = function dirname ->
  let name = Name.create "crunch" in
  let t = Crunch.path ~name dirname in
  D(t, (module Crunch))

module Block = struct

  type t = {
    name     : string;
    filename : string;
  }

  let name t = t.name

  let packages _ mode = [
    match mode with
    | `Unix _ -> "mirage-block-unix"
    | `Xen    -> "mirage-block-xen"
  ]

  let libraries _ = function
    | `Unix _ -> ["mirage-block-unix"]
    | `Xen    -> ["mirage-block-xen.front"]

  let configure t mode =
    let d = main_ml () in
    if not (StringMap.mem t.name d.modules) then (
      let m = "Block" in
      d.modules <- StringMap.add t.name m d.modules;
      append d.oc "let %s =" t.name;
      append d.oc "  %s.connect %S" m t.filename;
      newline d.oc
    )

  let clean t =
    ()

end

type block = BLOCK

let block: string -> block device =
  function filename ->
    let name = Name.create "block" in
    let t = { Block.name; filename } in
    D (t, (module Block))

module Fat = struct

  type t = {
    name : string;
    block: block device;
  }

  let name t = t.name

  let packages t mode = [
    "fat-filesystem";
  ]
    @ Io_page.packages () mode
    @ Block.packages t.block mode

  let libraries t mode = [
    "fat-filesystem";
  ]
    @ Io_page.libraries () mode
    @ Block.libraries t.block mode

  let configure t mode =
    let d = main_ml () in
    if not (StringMap.mem t.name d.modules) then (
      Device.configure t.block mode;
      let m = "Fat_" ^ t.name in
      d.modules <- StringMap.add t.name m d.modules;
      append d.oc "module %s = Fat.Fs.Make(%s)(Io_page)"
        m (StringMap.find (Device.name t.block) d.modules);
      newline d.oc;
      append d.oc "let %s =" t.name;
      append d.oc " %s >>= function" (Device.name t.block);
      append d.oc " | `Error _ -> %s" (driver_initialisation_error t.name);
      append d.oc " | `Ok dev  -> %s.connect dev" m
    )

  let clean t =
    Block.clean t.block

end

type fs = FS

let fat: block device -> fs device =
  function block ->
    let name = Name.create "fat" in
    let t = { Fat.name; block } in
    D (t, (module Fat))

module Fat_KV_RO = struct

  include Fat

  let configure t mode =
    let d = main_ml () in
    if not (StringMap.mem t.name d.modules) then (
      Device.configure t.block mode;
      let m = "Fat_" ^ t.name in
      d.modules <- StringMap.add t.name m d.modules;
      append d.oc "module %s__FS = Fat.Fs.Make(%s)(Io_page)"
        m (StringMap.find (Device.name t.block) d.modules);
      append d.oc "module %s = Fat.KV_RO.Make(%s__FS)"
        m m;
      newline d.oc;
      append d.oc "let %s =" t.name;
      append d.oc " %s >>= function" (Device.name t.block);
      append d.oc " | `Error _ -> %s" (driver_initialisation_error t.name);
      append d.oc " | `Ok dev  -> %s.connect dev" m
    )
end

let fat_kv_ro: block device -> kv_ro device =
  function block ->
    let name = Name.create "fat" in
    let t = { Fat_KV_RO.name; block } in
    D (t, (module Fat_KV_RO))

module Network = struct

  type t = Tap0 | Custom of string

  let name t =
    "net_" ^ match t with
    | Tap0     -> "tap0"
    | Custom s -> s

  let packages t = function
    | `Unix _ -> [ "mirage-net-unix" ]
    | `Xen    -> [ "mirage-net-xen" ]

  let libraries t mode =
    packages t mode

  let configure t mode =
    let d = main_ml () in
    let n = name t in
    if not (StringMap.mem n d.modules) then (
      let m = "Netif" in
      d.modules <- StringMap.add n m d.modules;
      newline d.oc;
      append d.oc "let %s =" n;
      append d.oc "  Netif.connect %S" (match t with Tap0 -> "tap0" | Custom s -> s);
      newline d.oc;
    )

  let clean _ =
    ()

end

type network = NETWORK

let tap0: network device =
  D (Network.Tap0, (module Network))

let network: string -> network device =
  function dev ->
    D (Network.Custom dev, (module Network))

module IP = struct

  (** IP settings. *)

  type ipv4 = {
    address : Ipaddr.V4.t;
    netmask : Ipaddr.V4.t;
    gateway : Ipaddr.V4.t list;
  }

  type config =
    | DHCP
    | IPv4 of ipv4

  type t = {
    name    : string;
    config  : config;
    networks: network device list;
  }

  let packages _ = function
    | `Unix `Direct -> ["mirage-tcpip-unix"]
    | `Unix `Socket -> ["mirage-tcpip-unix"]
    | `Xen          -> []

  let libraries t mode =
    packages t mode

  let name t = t.name

  let configure t mode =
    let d = main_ml () in
    List.iter (fun n -> Device.configure n mode) t.networks;
    if not (StringMap.mem t.name d.modules) then (
      let m = "Net.Manager" in
      d.modules <- StringMap.add t.name m d.modules;
      append d.oc "let %s =" t.name;
      append d.oc "  let conf = %s in"
        (match t.config with
         | DHCP   -> "`DHCP"
         | IPv4 i ->
           append d.oc "  let i = Ipaddr.V4.of_string_exn in";
           Printf.sprintf "`IPv4 (i %S, i %S, [%s])"
             (Ipaddr.V4.to_string i.address)
             (Ipaddr.V4.to_string i.netmask)
             (String.concat "; "
                (List.map (Printf.sprintf "i %S")
                   (List.map Ipaddr.V4.to_string i.gateway))));
      List.iter (fun n ->
          let name = Device.name n in
          append d.oc "  %s >>= function" name;
          append d.oc "  | `Error _ -> %s" (driver_initialisation_error name);
          append d.oc "  | `Ok %s ->" name;
        ) t.networks;
      append d.oc "  return (`Ok (fun callback ->";
      append d.oc "        Net.Manager.create [%s] (fun t interface id ->"
        (String.concat "; " (List.map Device.name t.networks));
      append d.oc "          Net.Manager.configure interface conf >>= fun () ->";
      append d.oc "          callback t)";
      append d.oc "    ))";
      newline d.oc
    )

  let clean t =
    ()

  let local network =
    let i s = Ipaddr.V4.of_string_exn s in
    let config = IPv4 {
        address = i "10.0.0.2";
        netmask = i "255.255.255.0";
        gateway = [i "10.0.0.1"];
      } in
    {
      name = "local_ip";
      config;
      networks = [network]
    }

end

module HTTP = struct

  type t = {
    port   : int;
    address: Ipaddr.V4.t option;
    ip: ip device;
  }

  let name t =
    "http_" ^ string_of_int t.port

  let packages t = function
    | `Unix _ -> ["mirage-http-unix"]
    | `Xen    -> ["mirage-http-xen"]

  let libraries t = function
    | `Unix _ -> ["mirage-http-unix"]
    | `Xen    -> ["mirage-http-xen"]

  let configure t mode =
    let d = main_ml () in
    let name = name t in
    if not (StringMap.mem name d.modules) then (
      let m = "HTTP.Server" in
      d.modules <- StringMap.add name m d.modules;
      Device.configure t.ip mode;
      append d.oc "let %s =" name;
      append d.oc "   %s >>= function" (IP.name t.ip);
      append d.oc "   | `Error _ -> %s" (driver_initialisation_error (IP.name t.ip));
      append d.oc "   | `Ok ip   ->";
      append d.oc "   return (`Ok (fun server ->";
      append d.oc "     ip (fun t -> %s.listen t (%s, %d) server))"
        m
        (match t.address with
         | None    -> "None"
         | Some ip -> Printf.sprintf "Some %S" (Ipaddr.V4.to_string ip))
        t.port;
      append d.oc "   )"
    )

  let clean t =
    ()

end

module Driver = struct

  type t =
    | Io_page of Io_page.t
    | Console of Console.t
    | Clock of Clock.t
    | Network of Network.t
    | Crunch of Crunch.t
    | Block of Block.t
    | Fat of Fat.t
    | IP of IP.t
    | HTTP of HTTP.t
    | Fat_KV_RO of Fat.t

  let name = function
    | Io_page x -> Io_page.name x
    | Console x -> Console.name x
    | Clock x   -> Clock.name x
    | Network x -> Network.name x
    | Crunch x   -> Crunch.name x
    | Block x   -> Block.name x
    | Fat x     -> Fat.name x
    | IP x      -> IP.name x
    | HTTP x    ->  HTTP.name x
    | Fat_KV_RO x -> Fat_KV_RO.name x

  let packages = function
    | Io_page x -> Io_page.packages x
    | Console x -> Console.packages x
    | Clock x   -> Clock.packages x
    | Network x -> Network.packages x
    | Crunch x   -> Crunch.packages x
    | Block x   -> Block.packages x
    | Fat x     -> Fat.packages x
    | IP x      -> IP.packages x
    | HTTP x    -> HTTP.packages x
    | Fat_KV_RO x -> Fat_KV_RO.packages x

  let libraries = function
    | Io_page x -> Io_page.libraries x
    | Console x -> Console.libraries x
    | Clock x   -> Clock.libraries x
    | Network x -> Network.libraries x
    | Crunch x   -> Crunch.libraries x
    | Block x   -> Block.libraries x
    | Fat x     -> Fat.libraries x
    | IP x      -> IP.libraries x
    | HTTP x    -> HTTP.libraries x
    | Fat_KV_RO x -> Fat_KV_RO.libraries x

  let configure = function
    | Io_page x -> Io_page.configure x
    | Console x -> Console.configure x
    | Clock x   -> Clock.configure x
    | Network x -> Network.configure x
    | Crunch x   -> Crunch.configure x
    | Block x   -> Block.configure x
    | Fat x     -> Fat.configure x
    | IP x      -> IP.configure x
    | HTTP x    -> HTTP.configure x
    | Fat_KV_RO x -> Fat_KV_RO.configure x

  let clean = function
    | Io_page x -> Io_page.clean x
    | Console x -> Console.clean x
    | Clock x   -> Clock.clean x
    | Network x -> Network.clean x
    | Crunch x   -> Crunch.clean x
    | Block x   -> Block.clean x
    | Fat x     -> Fat.clean x
    | IP x      -> IP.clean x
    | HTTP x    -> HTTP.clean x
    | Fat_KV_RO x -> Fat_KV_RO.clean x

  let rec map_path fn = function
    | Crunch x -> Crunch { x with Crunch.dirname = fn x.Crunch.dirname }
    | Block x -> Block { x with Block.filename = fn x.Block.filename }
    | Fat x   ->
      begin match map_path fn (Block x.Fat.block) with
        | Block block -> Fat { x with Fat.block }
        | _ -> assert false
      end
    | x       -> x


  let update_path t root =
    let fn path =
      realpath (Filename.concat root path) in
    map_path fn t

  let io_page = Io_page ()

  let console = Console ()

  let clock = Clock ()

  let tap0 = Network Network.Tap0

  let local_ip network =
    IP (IP.local network)

  let crunch ?name path =
    Crunch (Crunch.path ?name path)

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

  let configure t mode d =
    iter (fun p -> Driver.configure p mode d) t;
    newline d.oc;
    let modules = List.map (fun p ->
        let m = StringMap.find (Driver.name p) d.modules in
        Printf.sprintf "(%s)" m
      ) t.params in
    let names = List.map Driver.name t.params in
    let m = String.capitalize t.name in
    append d.oc "module %s = %s%s" m t.handler (String.concat "" modules);
    newline d.oc;
    append d.oc "let %s =" t.name;
    List.iter (fun name ->
        append d.oc "  %s >>= function" name;
        append d.oc "  | `Error _ -> %s" (driver_initialisation_error name);
        append d.oc "  | `Ok %s   ->" name;
      ) names;
    append d.oc "  %s.start %s" m (String.concat " " names);
    newline d.oc

  let clean t =
    iter Driver.clean t

  let all : t list ref =
    ref []

  let reset () =
    all := []

  let register j =
    all := List.map (fun (n,p) -> create n p) j @ !all

  let registered () =
    !all

  let update_path t root =
    let params = List.map (fun t -> Driver.update_path t root) t.params in
    { t with params }

end

type t = {
  name: string;
  root: string;
  jobs: Job.t list;
}

let name t = t.name

let main_ml t =
  let filename = t.root / "main.ml" in
  let oc = open_out filename in
  append oc "(* %s *)" generated_by_mirage;
  newline oc;
  append oc "open Lwt";
  newline oc;
  { filename; oc; modules = StringMap.empty; }

let fold fn { jobs } init =
  let s = List.fold_left (fun set job ->
      let s = fn job in
      StringSet.union set (StringSet.of_list s)
    ) init jobs in
  StringSet.elements s

let ps = ref StringSet.empty

let add_to_opam_packages p =
  ps := StringSet.union (StringSet.of_list p) !ps

let packages t mode =
  let m = match mode with
    | `Unix _ -> "mirage-unix"
    | `Xen    -> "mirage-xen" in
  fold
    (fun j -> Job.packages j mode)
    t
    (StringSet.add m !ps)

let ls = ref StringSet.empty

let add_to_ocamlfind_libraries l =
  ls := StringSet.union !ls (StringSet.of_list l)

let libraries t mode =
  let m = match mode with
    | `Unix _ -> "mirage.types-unix"
    | `Xen    -> "mirage.types-xen" in
  fold
    (fun j -> Job.libraries j mode)
    t
    (StringSet.add m !ls)

let configure_myocamlbuild_ml t mode d =
  let minor, major = ocaml_version () in
  if minor < 4 || major < 1 then (
    (* Previous ocamlbuild versions weren't able to understand the
       --output-obj rules *)
    let file = t.root / "myocamlbuild.ml" in
    let oc = open_out file in
    append oc "(* %s *)" generated_by_mirage;
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

let clean_myocamlbuild_ml t =
  remove (t.root / "myocamlbuild.ml")

let configure_main_xl t mode d =
  let file = t.root / t.name ^ ".xl" in
  let oc = open_out file in
  append oc "# %s" generated_by_mirage;
  newline oc;
  append oc "name = '%s'" t.name;
  append oc "kernel = '%s'" (t.root / "mir-main.xen");
  append oc "builder = 'linux'";
  append oc "memory = 256";
  newline oc;
  append oc "# You must define the network and block interfaces manually.";
  newline oc;
  append oc "# The disk configuration is defined here:";
  append oc "# http://xenbits.xen.org/docs/4.3-testing/misc/xl-disk-configuration.txt";
  append oc "# An example would look like:";
  append oc "# disk = [ '/dev/loop0,,xvda' ]";
  newline oc;
  append oc "# The network configuration is defined here:";
  append oc "# http://xenbits.xen.org/docs/4.3-testing/misc/xl-network-configuration.html";
  append oc "# An example would look like:";
  append oc "# vif = [ 'mac=c0:ff:ee:c0:ff:ee,bridge=br0' ]";
  close_out oc

let clean_main_xl t =
  remove (t.root / t.name ^ ".xl")

let configure_makefile t mode d =
  let file = t.root / "Makefile" in
  let libraries =
    match "lwt.syntax" :: libraries t mode with
    | [] -> ""
    | ls -> "-pkgs " ^ String.concat "," ls in
  let packages = String.concat " " (packages t mode) in
  let oc = open_out file in
  append oc "# %s" generated_by_mirage;
  newline oc;
  append oc "LIBS   = %s" libraries;
  append oc "PKGS   = %s" packages;
  append oc "SYNTAX = -tags \"syntax(camlp4o),annot,bin_annot,strict_sequence,principal\"\n";
  begin match mode with
    | `Xen ->
      append oc "FLAGS  = -cflag -g -lflags -g,-linkpkg,-dontlink,unix\n"
    | `Unix _ ->
      append oc "FLAGS  = -cflag -g -lflags -g,-linkpkg\n"
  end;
  append oc "BUILD  = ocamlbuild -classic-display -use-ocamlfind $(LIBS) $(SYNTAX) $(FLAGS)\n\
             OPAM   = opam";
  newline oc;
  append oc ".PHONY: all prepare clean build main.native\n\
             all: build\n\
             \n\
             prepare:\n\
             \t$(OPAM) install $(PKGS)\n\
             \n\
             main.native:\n\
             \t$(BUILD) main.native\n\
             \n\
             main.native.o:\n\
             \t$(BUILD) main.native.o";
  newline oc;
  begin match mode with
    | `Xen ->
      append oc "build: main.native.o";
      let path = read_command "ocamlfind printconf path" in
      let lib = strip path ^ "/mirage-xen" in
      append oc "\tld -d -nostdlib -m elf_x86_64 -T %s/mirage-x86_64.lds %s/x86_64.o \\\n\
                 \t  _build/main.native.o %s/libocaml.a %s/libxen.a \\\n\
                 \t  %s/libxencaml.a %s/libdiet.a %s/libm.a %s/longjmp.o -o mir-main.xen"
        lib lib lib lib lib lib lib lib;
    | `Unix _ ->
      append oc "build: main.native";
      append oc "\tln -nfs _build/main.native mir-%s" t.name;
  end;
  newline oc;
  append oc "run: build";
  begin match mode with
    | `Xen ->
      append oc "\t@echo %s.xl has been created. Edit it to add VIFs or VBDs" t.name;
      append oc "\t@echo Then do something similar to: xl create -c %s.xl" t.name
    | `Unix _ ->
      append oc "\t$(SUDO) ./mir-%s" t.name
  end;
  append oc "clean:\n\
             \tocamlbuild -clean";
  close_out oc

let clean_makefile t =
  remove (t.root / "Makefile")

let configure_opam t mode d =
  info "Installing OPAM packages.";
  match packages t mode with
  | [] -> ()
  | ps ->
    if command_exists "opam" then opam "install" ps
    else error "OPAM is not installed."

let clean_opam t =
  ()
(* This is a bit too agressive, disabling for now on.
   let (++) = StringSet.union in
   let set mode = StringSet.of_list (packages t mode) in
   let packages =
    set (`Unix `Socket) ++ set (`Unix `Direct) ++ set `Xen in
   match StringSet.elements packages with
   | [] -> ()
   | ps ->
    if cmd_exists "opam" then opam "remove" ps
    else error "OPAM is not installed."
*)

let manage_opam = ref true

let manage_opam_packages b =
  manage_opam := b

let configure_main t mode d =
  info "Generating %s" d.filename;
  List.iter (fun j -> Job.configure j mode d) t.jobs;
  newline d.oc;
  let jobs = List.map Job.name t.jobs in
  append d.oc "let () =";
  append d.oc "  OS.Main.run (join [%s])" (String.concat "; " jobs)

let clean_main t =
  List.iter Job.clean t.jobs;
  remove (t.root / "main.ml")


(* XXX
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

*)

let configure t mode d =
  info "CONFIGURE: %s" (blue_s (t.root / "config.ml"));
  info "%d job%s [%s]"
    (List.length t.jobs)
    (if List.length t.jobs = 1 then "" else "s")
    (String.concat ", " (List.map Job.name t.jobs));
  in_dir t.root (fun () ->
      if !manage_opam then configure_opam t mode d;
      configure_myocamlbuild_ml t mode d;
      configure_makefile t mode d;
      configure_main_xl t mode d;
      configure_main t mode d
    )

let make () =
  match uname_s () with
  | Some ("FreeBSD" | "OpenBSD" | "NetBSD" | "DragonFly") -> "gmake"
  | _ -> "make"

let build t =
  info "BUILD: %s" (blue_s (t.root / "config.ml"));
  in_dir t.root (fun () ->
      command "%s build" (make ())
    )

let run t =
  info "RUN: %s" (blue_s (t.root / "config.ml"));
  in_dir t.root (fun () ->
      command "%s run" (make ())
    )

let clean t =
  info "CLEAN: %s" (blue_s (t.root / "config.ml"));
  in_dir t.root (fun () ->
      if !manage_opam then clean_opam t;
      clean_myocamlbuild_ml t;
      clean_makefile t;
      clean_main_xl t;
      clean_main t;
      command "rm -rf %s/_build" t.root;
      command "rm -rf %s/main.native.o %s/main.native %s/mir-main %s/*~"
        t.root t.root t.root t.root;
    )

(* Compile the configuration file and attempt to dynlink it.
 * It is responsible for registering an application via
 * [Mirage_config.register] in order to have an observable
 * side effect to this command. *)
let compile_and_dynlink file =
  info "%s" (blue_s (Printf.sprintf "Compiling and dynlinkg %s" file));
  let root = Filename.dirname file in
  let file = Filename.basename file in
  let file = Dynlink.adapt_filename file in
  command "rm -rf %s/_build/%s.*" root (Filename.chop_extension file);
  command "cd %s && ocamlbuild -use-ocamlfind -pkg mirage %s" root file;
  try Dynlink.loadfile (String.concat "/" [root; "_build"; file])
  with Dynlink.Error err -> error "Error loading config: %s" (Dynlink.error_message err)

(* If a configuration file is specified, then use that.
 * If not, then scan the curdir for a `config.ml` file.
 * If there is more than one, then error out. *)
let scan_conf = function
  | Some f ->
    info "Using the specified config file: %s" (yellow_s f);
    if not (Sys.file_exists f) then error "%s does not exist, stopping." f;
    realpath f
  | None   ->
    let files = Array.to_list (Sys.readdir ".") in
    match List.filter ((=) "config.ml") files with
    | [] -> error "No configuration file ending in .conf found.\n\
                   You'll need to create one to let Mirage know what do do."
    | [f] ->
      info "Using the scanned config file: %s" (yellow_s f);
      realpath f
    | _   -> error "There is more than one config.ml in the current working directory.\n\
                    Please specify one explicitly on the command-line."

let load file =
  let file = scan_conf file in
  let root = realpath (Filename.dirname file) in
  Job.reset ();
  compile_and_dynlink (root / Filename.basename file);
  let jobs =
    let jobs = Job.registered () in
    List.map (fun j -> Job.update_path j root) jobs in
  { name ="main"; root; jobs }
