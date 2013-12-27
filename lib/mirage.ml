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

open Mirage_misc

module StringSet = struct

  include Set.Make(String)

  let of_list l =
    let s = ref empty in
    List.iter (fun e -> s := add e !s) l;
    !s

end

module Name = struct

  let names = Hashtbl.create 1024

  let create name =
    let n =
      try 1 + Hashtbl.find names name
      with Not_found -> 1 in
    Hashtbl.replace names name n;
    Printf.sprintf "%s%d" name n

end

let main_ml = ref None

let append_main fmt =
  match !main_ml with
  | None    -> failwith "main_ml"
  | Some oc -> append oc fmt

let newline_main () =
  match !main_ml with
  | None    -> failwith "main_ml"
  | Some oc -> newline oc

let set_main_ml file =
  let oc = open_out file in
  main_ml := Some oc

type mode = [
  | `Unix of [ `Direct | `Socket ]
  | `Xen
]

let mode =
  ref (`Unix `Direct)

let set_mode m =
  mode := m

let get_mode () =
  !mode

module type CONFIGURABLE = sig
  type t
  val name: t -> string
  val module_name: t -> string
  val packages: t -> string list
  val libraries: t -> string list
  val configure: t -> unit
  val clean: t -> unit
  val update_path: t -> string -> t
end

type _ typ =
  | Type: 'a -> 'a typ
  | Function: 'a typ * 'b typ -> ('a -> 'b) typ

let (@->) f t =
  Function (f, t)

type ('a, 'b) base = {
  typ: 'a typ;
  t: 'b;
  m: (module CONFIGURABLE with type t = 'b);
}

type 'a foreign = {
  name: string;
  typ: 'a typ;
  libraries: string list;
  packages: string list;
}

type _ impl =
  | Impl: ('a, 'b) base -> 'a impl (* base implementation *)
  | App: ('a, 'b) app -> 'b impl   (* functor application *)
  | Foreign: 'a foreign -> 'a impl (* foreign functor implementation *)

and ('a, 'b) app = {
  f: ('a -> 'b) impl;  (* functor *)
  x: 'a impl;          (* parameter *)
}

let rec string_of_impl: type a. a impl -> string = function
  | Impl { t; m = (module M) } -> Printf.sprintf "Impl (%s)" (M.module_name t)
  | Foreign { name } -> Printf.sprintf "Foreign (%s)" name
  | App { f; x } -> Printf.sprintf "App (%s, %s)" (string_of_impl f) (string_of_impl x)

type 'a folder = {
  f: 'b. 'a -> 'b impl -> 'a
}

let rec fold: type a. 'b folder -> a impl -> 'b -> 'b =
  fun fn t acc ->
    match t with
    | Impl _
    | Foreign _  -> fn.f acc t
    | App {f; x} -> fold fn f (fn.f acc x)

type iterator = {
  i: 'b. 'b impl -> unit
}

let rec iter: type a. iterator -> a impl -> unit =
  fun fn t ->
    match t with
    | Impl _
    | Foreign _  -> fn.i t
    | App {f; x} -> iter fn f; iter fn x

let driver_initialisation_error name =
  Printf.sprintf "fail (Mirage_types.V1.Driver_initialisation_error %S)" name

module Impl = struct

  exception Partially_evaluated

  let names = Hashtbl.create 31

  let modules = Hashtbl.create 31

  (* get the left-most module name (ie. the name of the functor). *)
  let rec functor_name: type a. a impl -> string = function
    | Impl { t; m = (module M) } -> M.module_name t
    | Foreign { name }           -> name
    | App { f }                  -> functor_name f

  (* return a unique variable name holding the state of the given
     module construction. *)
  let rec name: type a. a impl -> string = function
    | Impl { t; m = (module M) } -> M.name t
    | Foreign { name }           -> find_or_create names name (fun () -> Name.create "f")
    | App _ as t                 ->
      let name = module_name t in
      find_or_create names name (fun () -> Name.create "t")

  (* return a unique module name holding the implementation of the
     given module construction. *)
  and module_name: type a. a impl -> string = function
    | Impl { t; m = (module M) } -> M.module_name t
    | Foreign { name }           -> name
    | App { f; x }   ->
      let name = match module_names f @ [module_name x] with
        | []   -> assert false
        | [m]  -> m
        | h::t -> h ^ String.concat "" (List.map (Printf.sprintf "(%s)") t) in
      find_or_create modules name (fun () -> Name.create "M")

  and module_names: type a. a impl -> string list =
    function t ->
      let fn = {
        f = fun acc t -> module_name t :: acc
      } in
      fold fn t []

  let rec names: type a. a impl -> string list = function
    | Foreign _
    | Impl _ as t          -> [name t]
    | App {f=Foreign f; x} -> names x
    | App {f; x}           -> (names f) @ [name x]

  let configured = Hashtbl.create 31

  let rec configure: type a. a impl -> unit =
    fun t ->
      let name = name t in
      if not (Hashtbl.mem configured name) then (
        Hashtbl.add configured name true;
        match t with
        | Impl { t; m = (module M) } -> M.configure t
        | Foreign _                  -> ()
        | App {f; x} as  app         ->
          let name = module_name app in
          let body = cofind modules name in
          configure_app x;
          iter { i=configure } app;
          append_main "module %s = %s" name body;
          newline_main ();
      )

  and configure_app: type a. a impl -> unit = function
    | Impl _
    | Foreign _  -> ()
    | App _ as t ->
      let name = name t in
      configure t;
      begin match names t with
        | [n]   -> append_main "let %s = %s" name n
        | names ->
          append_main "let %s () =" name;
          List.iter (fun n ->
              append_main "  %s () >>= function" n;
              append_main "  | `Error e -> %s" (driver_initialisation_error n);
              append_main "  | `Ok %s ->" n;
            ) names;
          append_main "  return (`Ok (%s))" (String.concat ", " names)
      end;
      newline_main ()

  let rec packages: type a. a impl -> string list = function
    | Impl { t; m = (module M) } -> M.packages t
    | Foreign { packages }       -> packages
    | App {f; x}                 -> packages f @ packages x

  let rec libraries: type a. a impl -> string list = function
    | Impl { t; m = (module M) } -> M.libraries t
    | Foreign { libraries }      -> libraries
    | App {f; x}                 -> libraries f @ libraries x

  let rec clean: type a. a impl -> unit = function
    | Impl { t; m = (module M) } -> M.clean t
    | Foreign _                  -> ()
    | App {f; x}                 -> clean f; clean x

  let rec update_path: type a. a impl -> string -> a impl =
    fun t root -> match t with
      | Impl b     -> let module M = (val b.m) in Impl { b with t = M.update_path b.t root }
      | Foreign _  -> t
      | App {f; x} -> App { f = update_path f root; x = update_path x root }

end

let impl typ t m =
  Impl { typ; t; m }

let implementation typ t m =
  let typ = Type typ in
  Impl { typ; t; m }

let ($) f x =
  App { f; x }

let foreign name ?(libraries=[]) ?(packages=[]) typ =
  Foreign { name; typ; libraries; packages }

let rec typ: type a. a impl -> a typ = function
  | Impl { typ }
  | Foreign { typ } -> typ
  | App { f }       -> match typ f with Function (_, b) -> b | _ -> assert false

module Headers = struct

  let output () =
    append_main "(* %s *)" generated_by_mirage;
    newline_main ()

end

module Io_page = struct

  (** Memory allocation interface. *)

  type t = unit

  let name () =
    "io_page"

  let module_name () =
    "Io_page"

  let packages () = [
    match !mode with
    | `Unix _ -> "io-page-unix"
    | `Xen    -> "io-page-xen"
  ]

  let libraries () =
    packages ()

  let configure () = ()

  let clean () = ()

  let update_path () _ = ()

end

type io_page = IO_PAGE

let io_page = Type IO_PAGE

let defaut_io_page: io_page impl =
  impl io_page () (module Io_page)

module Clock = struct

  (** Clock operations. *)

  type t = unit

  let name () =
    "clock"

  let module_name () =
    "Clock"

  let packages () = [
    match !mode with
    | `Unix _ -> "mirage-clock-unix"
    | `Xen    -> "mirage-clock-xen"
  ]

  let libraries () = packages ()

  let configure () = ()

  let clean () = ()

  let update_path () _ = ()

end

type clock = CLOCK

let clock = Type CLOCK

let default_clock: clock impl =
  impl clock () (module Clock)

module Console = struct

  type t = string

  let name t =
    "console" ^ t

  let module_name _ =
    "Console"

  let packages _ = [
    match !mode with
    | `Unix _ -> "mirage-console-unix"
    | `Xen    -> "mirage-console-xen"
  ]

  let libraries t = packages t

  let configure t =
    let name = name t in
    append_main "let %s () =" name;
    append_main "  %s.connect %S" (module_name t) t;
    newline_main ()

  let clean _ =
    ()

  let update_path t _ =
    t

end

type console = CONSOLE

let console = Type CONSOLE

let default_console: console impl =
  impl console "0" (module Console)

let custom_console: string -> console impl =
  fun str ->
    impl console str (module Console)

module Crunch = struct

  type t = {
    name   : string;
    dirname: string;
  }

  let name t =
    t.name

  let module_name t =
    "Static_" ^ t.name

  let path ?name dirname =
    let name = match name with
      | None   -> Filename.basename dirname
      | Some n -> n in
    { name; dirname }

  let packages _ = [
    "mirage-types";
    "lwt";
    "cstruct";
    "crunch";
  ]

  let libraries _ = [
    "mirage-types";
    "lwt";
    "cstruct" ] @ [
      match !mode with
      | `Unix _ -> "io-page-unix"
      | `Xen    -> "io-page-xen"
    ]

  let ml t =
    Printf.sprintf "static_%s.ml" t.name

  let mli t =
    Printf.sprintf "static_%s.mli" t.name

  let configure t =
    if not (command_exists "ocaml-crunch") then
      error "ocaml-crunch not found, stopping.";
    let file = ml t in
    if Sys.file_exists t.dirname then (
      info "Generating %s/%s." (Sys.getcwd ()) file;
      command "ocaml-crunch -o %s %s" file t.dirname
    ) else
      error "The directory %s does not exist." t.dirname;
    append_main "let %s () =" t.name;
    append_main "  Static_%s.connect ()" t.name;
    newline_main ()

  let clean t =
    remove (ml t);
    remove (mli t)

  let update_path t root =
    { t with dirname = root / t.dirname }

end

module Direct_kv_ro = struct

  include Crunch

let module_name t =
    match !mode with
    | `Xen    -> Crunch.module_name t
    | `Unix _ -> "Kvro_fs_unix"

  let packages t =
    match !mode with
    | `Xen    -> Crunch.packages t
    | `Unix _ -> [
        "mirage-types";
        "lwt";
        "cstruct";
        "mirage-fs-unix";
      ]

  let libraries t =
    match !mode with
    | `Xen    -> Crunch.libraries t
    | `Unix _ -> [
        "mirage-types";
        "lwt";
        "cstruct";
        "io-page-unix";
        "mirage-fs-unix";
      ]

  let configure t =
    match !mode with
    | `Xen    -> Crunch.configure t
    | `Unix _ ->
      append_main "let %s () =" t.name;
      append_main "  Kvro_fs_unix.connect %S" t.dirname

end

type kv_ro = KV_RO

let kv_ro = Type KV_RO

let crunch: string -> kv_ro impl =
  function dirname ->
    let name = Name.create "crunch" in
    let t = Crunch.path ~name dirname in
    impl kv_ro t (module Crunch)

let direct_kv_ro: string -> kv_ro impl =
  function dirname ->
    let name = Name.create "direct_kv_ro" in
    let t = Direct_kv_ro.path ~name dirname in
    impl kv_ro t (module Direct_kv_ro)

module Block = struct

  type t = {
    name     : string;
    filename : string;
  }

  let name t =
    t.name

  let module_name _ =
    "Block"

  let packages _ = [
    match !mode with
    | `Unix _ -> "mirage-block-unix"
    | `Xen    -> "mirage-block-xen"
  ]

  let libraries _ = [
    match !mode with
    | `Unix _ -> "mirage-block-unix"
    | `Xen    -> "mirage-block-xen.front"
  ]

  let configure t =
    append_main "let %s () =" t.name;
    append_main "  %s.connect %S" (module_name t) t.filename;
    newline_main ()

  let clean t =
    ()

  let update_path t root =
    { t with filename = root / t.filename }

end

type block = BLOCK

let block = Type BLOCK

let block_of_file: string -> block impl =
  function filename ->
    let name = Name.create "block" in
    let t = { Block.name; filename } in
    impl block t (module Block)

module Fat = struct

  type t = {
    name : string;
    block: block impl;
  }

  let name t = t.name

  let module_name t =
    "Fat_" ^ t.name

  let packages t = [
    "fat-filesystem";
  ]
    @ Io_page.packages ()
    @ Block.packages t.block

  let libraries t = [
    "fat-filesystem";
  ]
    @ Io_page.libraries ()
    @ Block.libraries t.block

  let configure t =
    Impl.configure t.block;
    append_main "module %s = Fat.Fs.Make(%s)(Io_page)"
      (module_name t)
      (Impl.module_name t.block);
    newline_main ();
    append_main "let %s () =" (name t);
    append_main "  %s () >>= function" (Impl.name t.block);
    append_main "  | `Error _ -> %s" (driver_initialisation_error t.name);
    append_main "  | `Ok dev  -> %s.connect dev" (module_name t);
    newline_main ()

  let clean t =
    Impl.clean t.block

  let update_path t root =
     { t with block = Impl.update_path t.block root }

end

type fs = FS

let fs = Type FS

let fat: block impl -> fs impl =
  function block ->
    let name = Name.create "fat" in
    let t = { Fat.name; block } in
    impl fs t (module Fat)

let kv_ro_of_fs =
  let dummy_fat = fat (block_of_file "xx") in
  let libraries = Impl.libraries dummy_fat in
  let packages = Impl.packages dummy_fat in
  let fn = foreign "Fat.KV_RO.Make" ~libraries ~packages (fs @-> kv_ro) in
  function fs -> fn $ fs

module Network = struct

  type t = Tap0 | Custom of string

  let name t =
    "net_" ^ match t with
    | Tap0     -> "tap0"
    | Custom s -> s

  let module_name _ =
    "Netif"

  let packages t = [
    match !mode with
    | `Unix _ -> "mirage-net-unix"
    | `Xen    -> "mirage-net-xen"
  ]

  let libraries t =
    packages t

  let configure t =
    append_main "let %s () =" (name t);
    append_main "  %s.connect %S"
      (module_name t)
      (match t with Tap0 -> "tap0" | Custom s -> s);
    newline_main ()

  let clean _ =
    ()

  let update_path t _ =
    t

end

type network = NETWORK

let network = Type NETWORK

let tap0: network impl =
  impl network Network.Tap0 (module Network)

let custom_network: string -> network impl =
  function dev ->
    impl network (Network.Custom dev) (module Network)

type ipv4 = {
  address : Ipaddr.V4.t;
  netmask : Ipaddr.V4.t;
  gateway : Ipaddr.V4.t list;
}

module IP = struct

  (** IP settings. *)

  type ip_config =
    | DHCP
    | IPv4 of ipv4

  type t = {
    name    : string;
    config  : ip_config;
    networks: network impl list;
  }

  let name t =
    t.name

  let module_name _ =
    "Net.Manager"

  let packages _ = [
    match !mode with
    | `Unix _ -> "mirage-tcpip-unix"
    | `Xen    -> "mirage-tcpip-xen"
  ]

  let libraries t =
    packages t

  let configure t =
    List.iter Impl.configure t.networks;
    append_main "let %s () =" t.name;
    append_main "  let conf = %s in"
      (match t.config with
       | DHCP   -> "`DHCP"
       | IPv4 i ->
         append_main "  let i = Ipaddr.V4.of_string_exn in";
         Printf.sprintf "`IPv4 (i %S, i %S, [%s])"
           (Ipaddr.V4.to_string i.address)
           (Ipaddr.V4.to_string i.netmask)
           (String.concat "; "
              (List.map (Printf.sprintf "i %S")
                 (List.map Ipaddr.V4.to_string i.gateway))));
    List.iter (fun n ->
        let name = Impl.name n in
        append_main "  %s () >>= function" name;
        append_main "  | `Error _ -> %s" (driver_initialisation_error name);
        append_main "  | `Ok %s ->" name;
      ) t.networks;
    append_main "  return (`Ok (fun callback ->";
    append_main "        %s.create [%s] (fun t interface id ->"
      (module_name t)
      (String.concat "; " (List.map Impl.name t.networks));
    append_main "          %s.configure interface conf >>= fun () ->" (module_name t);
    append_main "          callback t)";
    append_main "    ))";
    newline_main ()

  let clean t =
    ()

  let update_path t root =
    { t with networks = List.map (fun n -> Impl.update_path n root) t.networks }

  let default_ip networks =
    let name = Name.create "default_ip" in
    let i s = Ipaddr.V4.of_string_exn s in
    let config = IPv4 {
        address = i "10.0.0.2";
        netmask = i "255.255.255.0";
        gateway = [i "10.0.0.1"];
      } in
    { name; config; networks }

  let dhcp networks =
    let name = Name.create "dhcp" in
    { name; config = DHCP; networks }

end

type ip = IP

let ip = Type IP

let ipv4: ipv4 -> network impl list -> ip impl =
  fun ipv4 networks ->
    let name = Name.create "ipv4" in
    let t = {
      IP.name; networks;
      config  = IP.IPv4 ipv4;
    } in
    impl ip t (module IP)

let default_ip: network impl list -> ip impl =
  fun networks ->
    impl ip (IP.default_ip networks) (module IP)

let dhcp: network impl list -> ip impl =
  fun networks ->
    impl ip (IP.dhcp networks) (module IP)

module HTTP = struct

  type t = {
    port   : int;
    address: Ipaddr.V4.t option;
    ip     : ip impl;
  }

  let name t =
    "http_" ^ string_of_int t.port

  let module_name _ =
    "HTTP.Server"

  let packages t = [
    match !mode with
    | `Unix _ -> "mirage-http-unix"
    | `Xen    -> "mirage-http-xen"
  ]

  let libraries t =
    packages t

  let configure t =
    Impl.configure t.ip;
    append_main "let %s () =" (name t);
    append_main "   %s () >>= function" (Impl.name t.ip);
    append_main "   | `Error _ -> %s" (driver_initialisation_error (Impl.name t.ip));
    append_main "   | `Ok ip   ->";
    append_main "   return (`Ok (fun server ->";
    append_main "     ip (fun t -> %s.listen t (%s, %d) server))"
      (module_name t)
      (match t.address with
       | None    -> "None"
       | Some ip -> Printf.sprintf "Some %S" (Ipaddr.V4.to_string ip))
      t.port;
    append_main "   )"

  let clean t =
    ()

  let update_path t root =
    { t with ip = Impl.update_path t.ip root }

end

type http = HTTP

let http = Type HTTP

let http_server: int -> ip impl -> http impl =
  fun port ip ->
    let t = { HTTP.port; ip; address = None } in
    impl http t (module HTTP)

type job = JOB

module Job = struct

  type t = {
    name: string;
    impl: job impl;
  }

  let create impl =
    let name = Name.create "job" in
    { name; impl }

  let name t =
    t.name

  let packages t =
    Impl.packages t.impl

  let libraries t =
    Impl.libraries t.impl

  let configure t =
    Impl.configure t.impl;
    newline_main ()

  let clean t =
    Impl.clean t.impl

  let update_path t root =
    { t with impl = Impl.update_path t.impl root }

end

let job: job typ = Type JOB

type t = {
  name: string;
  root: string;
  jobs: job impl list;
}

let t = ref None

let config_file = ref None

let reset () =
  config_file := None;
  t := None

let set_config_file f =
  config_file := Some f

let update_path t root =
  { t with jobs = List.map (fun j -> Impl.update_path j root) t.jobs }

let register name jobs =
  let root = match !config_file with
    | None   -> failwith "no config file"
    | Some f -> Filename.dirname f in
  t := Some { name; jobs; root }

let registered () =
  match !t with
  | None   -> { name = "empty"; jobs = []; root = Sys.getcwd () }
  | Some t -> t

let ps = ref StringSet.empty

let add_to_opam_packages p =
  ps := StringSet.union (StringSet.of_list p) !ps

let packages t =
  let m = match !mode with
    | `Unix _ -> "mirage-unix"
    | `Xen    -> "mirage-xen" in
  let ps = List.fold_left (fun set j ->
      let ps = StringSet.of_list (Impl.packages j) in
      StringSet.union ps set
    ) (StringSet.add m !ps) t.jobs in
  StringSet.elements ps

let ls = ref StringSet.empty

let add_to_ocamlfind_libraries l =
  ls := StringSet.union !ls (StringSet.of_list l)

let libraries t =
  let m = match !mode with
    | `Unix _ -> "mirage.types-unix"
    | `Xen    -> "mirage.types-xen" in
  let ls = List.fold_left (fun set j ->
      let ls = StringSet.of_list (Impl.libraries j) in
      StringSet.union ls set
    ) (StringSet.add m !ls) t.jobs in
  StringSet.elements ls

let configure_myocamlbuild_ml t =
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

let configure_main_xl t =
  let file = t.root / t.name ^ ".xl" in
  let oc = open_out file in
  append oc "# %s" generated_by_mirage;
  newline oc;
  append oc "name = '%s'" t.name;
  append oc "kernel = '%s/mir-%s.xen'" t.root t.name;
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

let configure_makefile t =
  let file = t.root / "Makefile" in
  let libraries =
    match "lwt.syntax" :: libraries t with
    | [] -> ""
    | ls -> "-pkgs " ^ String.concat "," ls in
  let packages = String.concat " " (packages t) in
  let oc = open_out file in
  append oc "# %s" generated_by_mirage;
  newline oc;
  append oc "LIBS   = %s" libraries;
  append oc "PKGS   = %s" packages;
  append oc "SYNTAX = -tags \"syntax(camlp4o),annot,bin_annot,strict_sequence,principal\"\n";
  begin match !mode with
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
  begin match !mode with
    | `Xen ->
      append oc "build: main.native.o";
      let path = read_command "ocamlfind printconf path" in
      let lib = strip path ^ "/mirage-xen" in
      append oc "\tld -d -nostdlib -m elf_x86_64 -T %s/mirage-x86_64.lds %s/x86_64.o \\\n\
                 \t  _build/main.native.o %s/libocaml.a %s/libxen.a \\\n\
                 \t  %s/libxencaml.a %s/libdiet.a %s/libm.a %s/longjmp.o -o mir-%s.xen"
        lib lib lib lib lib lib lib lib t.name;
    | `Unix _ ->
      append oc "build: main.native";
      append oc "\tln -nfs _build/main.native mir-%s" t.name;
  end;
  newline oc;
  append oc "run: build";
  begin match !mode with
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

let configure_opam t =
  info "Installing OPAM packages.";
  match packages t with
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

let configure_job j =
  let name = Impl.name j in
  let module_name = Impl.module_name j in
  let param_names = Impl.names j in
  append_main "let %s () =" name;
  List.iter (fun p ->
      append_main "  %s () >>= function" p;
      append_main "  | `Error e -> %s" (driver_initialisation_error p);
      append_main "  | `Ok %s ->" p;
    ) param_names;
  append_main "  %s.start %s" module_name (String.concat " " param_names);
  newline_main ()

let configure_main t =
  info "Generating main.ml";
  set_main_ml (t.root / "main.ml");
  append_main "(* %s *)" generated_by_mirage;
  newline_main ();
  append_main "open Lwt";
  newline_main ();
  List.iter (fun j -> Impl.configure j) t.jobs;
  List.iter configure_job t.jobs;
  let names = List.map (fun j -> Printf.sprintf "%s ()" (Impl.name j)) t.jobs in
  append_main "let () =";
  append_main "  OS.Main.run (join [%s])" (String.concat "; " names)

let clean_main t =
  List.iter Impl.clean t.jobs;
  remove (t.root / "main.ml")

let configure t =
  info "CONFIGURE: %s" (blue_s (t.root / "config.ml"));
  info "%d job%s [%s]"
    (List.length t.jobs)
    (if List.length t.jobs = 1 then "" else "s")
    (String.concat ", " (List.map Impl.functor_name t.jobs));
  in_dir t.root (fun () ->
      if !manage_opam then configure_opam t;
      configure_myocamlbuild_ml t;
      configure_makefile t;
      configure_main_xl t;
      configure_main t
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
      command "rm -rf log %s/main.native.o %s/main.native %s/mir-%s %s/*~"
        t.root t.root t.root t.name t.root;
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
  reset ();
  let file = scan_conf file in
  let root = realpath (Filename.dirname file) in
  let file = root / Filename.basename file in
  set_config_file file;
  compile_and_dynlink file;
  let t = registered () in
  set_section t.name;
  update_path t root
