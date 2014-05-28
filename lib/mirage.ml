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
  | `Unix
  | `Xen
]

let mode = ref `Unix

let set_mode m =
  mode := m

let get_mode () =
  !mode

type _ typ =
  | Type: 'a -> 'a typ
  | Function: 'a typ * 'b typ -> ('a -> 'b) typ

let (@->) f t =
  Function (f, t)

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


module TODO (N: sig val name: string end) = struct

  let todo str =
    failwith (Printf.sprintf "TODO: %s.%s" N.name str)

  let name _ =
    todo "name"

  let module_name _ =
    todo "module_name"

  let packages _ =
    todo "packages"

  let libraries _ =
    todo "libraries"

  let configure _ =
    todo "configure"

  let clean _ =
    todo "clean"

  let update_path _ =
    todo "update_path"

end

type ('a, 'b) base = {
  typ: 'a typ;
  t: 'b;
  m: (module CONFIGURABLE with type t = 'b);
}

type 'a foreign = {
  name: string;
  ty: 'a typ;
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
  fn: 'b. 'a -> 'b impl -> 'a
}

let rec fold: type a. 'b folder -> a impl -> 'b -> 'b =
  fun fn t acc ->
    match t with
    | Impl _
    | Foreign _  -> fn.fn acc t
    | App {f; x} -> fold fn f (fn.fn acc x)

type iterator = {
  i: 'b. 'b impl -> unit
}

let rec iter: type a. iterator -> a impl -> unit =
  fun fn t ->
    match t with
    | Impl _
    | Foreign _  -> fn.i t
    | App {f; x} -> iter fn f; iter fn x; fn.i x

let driver_initialisation_error name =
  Printf.sprintf "fail (Failure %S)" name

module Name = struct

  let ids = Hashtbl.create 1024

  let names = Hashtbl.create 1024

  let create name =
    let n =
      try 1 + Hashtbl.find ids name
      with Not_found -> 1 in
    Hashtbl.replace ids name n;
    Printf.sprintf "%s%d" name n

  let of_key key ~base =
    find_or_create names key (fun () -> create base)

end

module Impl = struct

  (* get the left-most module name (ie. the name of the functor). *)
  let rec functor_name: type a. a impl -> string = function
    | Impl { t; m = (module M) } -> M.module_name t
    | Foreign { name }           -> name
    | App { f }                  -> functor_name f

  (* return a unique variable name holding the state of the given
     module construction. *)
  let rec name: type a. a impl -> string = function
    | Impl { t; m = (module M) } -> M.name t
    | Foreign { name }           -> Name.of_key ("f" ^ name) ~base:"f"
    | App _ as t                 -> Name.of_key (module_name t) ~base:"t"

  (* return a unique module name holding the implementation of the
     given module construction. *)
  and module_name: type a. a impl -> string = function
    | Impl { t; m = (module M) } -> M.module_name t
    | Foreign { name }           -> name
    | App { f; x }   ->
      let name = match module_names f @ [module_name x] with
        | []   -> assert false
        | [m]  -> m
        | h::t -> h ^ String.concat "" (List.map (Printf.sprintf "(%s)") t)
      in
      Name.of_key name ~base:"M"

  and module_names: type a. a impl -> string list =
    function t ->
      let fn = {
        fn = fun acc t -> module_name t :: acc
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
          configure_app f;
          configure_app x;
          iter { i=configure } app;
          let name = module_name app in
          let body = cofind Name.names name in
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
      | Impl b     ->
        let module M = (val b.m) in Impl { b with t = M.update_path b.t root }
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

let foreign name ?(libraries=[]) ?(packages=[]) ty =
  Foreign { name; ty; libraries; packages }

let rec typ: type a. a impl -> a typ = function
  | Impl { typ } -> typ
  | Foreign { ty } -> ty
  | App { f }       -> match typ f with Function (_, b) -> b | _ -> assert false

module Io_page = struct

  (** Memory allocation interface. *)

  type t = unit

  let name () =
    "io_page"

  let module_name () =
    "Io_page"

  let packages () =
    [ "io-page" ]

  let libraries () =
    packages ()

  let configure () = ()

  let clean () = ()

  let update_path () _ = ()

end

type io_page = IO_PAGE

let io_page = Type IO_PAGE

let default_io_page: io_page impl =
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
    | `Unix -> "mirage-clock-unix"
    | `Xen  -> "mirage-clock-xen"
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
    Name.of_key ("console" ^ t) ~base:"console"

  let module_name t =
    "Console"

  let packages _ = [
    match !mode with
    | `Unix -> "mirage-console-unix"
    | `Xen  -> "mirage-console-xen"
  ]

  let libraries t = packages t

  let configure t =
    append_main "let %s () =" (name t);
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

  type t = string

  let name t =
    Name.of_key ("static" ^ t) ~base:"static"

  let module_name t =
    String.capitalize (name t)

  let packages _ = [
    "mirage-types";
    "lwt";
    "cstruct";
    "crunch";
  ]

  let libraries _ = [
    "mirage-types";
    "lwt";
    "cstruct" ] @ (
      match !mode with
      | `Unix -> [ "io-page.unix" ]
      | `Xen  -> []
    ) @ [ "io-page" ]

  let ml t =
    Printf.sprintf "%s.ml" (name t)

  let mli t =
    Printf.sprintf "%s.mli" (name t)

  let configure t =
    if not (command_exists "ocaml-crunch") then
      error "ocaml-crunch not found, stopping.";
    let file = ml t in
    if Sys.file_exists t then (
      info "%s %s" (blue_s "Generating:") (Sys.getcwd () / file);
      command "ocaml-crunch -o %s %s" file t
    ) else
      error "The directory %s does not exist." t;
    append_main "let %s () =" (name t);
    append_main "  %s.connect ()" (module_name t);
    newline_main ()

  let clean t =
    remove (ml t);
    remove (mli t)

  let update_path t root =
    if Sys.file_exists (root / t) then
      root / t
    else
      t

end

type kv_ro = KV_RO

let kv_ro = Type KV_RO

let crunch dirname =
  impl kv_ro dirname (module Crunch)

module Direct_kv_ro = struct

  include Crunch

  let module_name t =
    match !mode with
    | `Xen  -> Crunch.module_name t
    | `Unix -> "Kvro_fs_unix"

  let packages t =
    match !mode with
    | `Xen  -> Crunch.packages t
    | `Unix -> [
        "mirage-types";
        "lwt";
        "cstruct";
        "mirage-fs-unix";
      ]

  let libraries t =
    match !mode with
    | `Xen  -> Crunch.libraries t
    | `Unix -> [
        "mirage-types";
        "lwt";
        "cstruct";
        "io-page.unix"; "io-page";
        "mirage-fs-unix";
      ]

  let configure t =
    match !mode with
    | `Xen  -> Crunch.configure t
    | `Unix ->
      append_main "let %s () =" (name t);
      append_main "  Kvro_fs_unix.connect %S" t

end

let direct_kv_ro dirname =
  impl kv_ro dirname (module Direct_kv_ro)

module Block = struct

  type t = string

  let name t =
    Name.of_key ("block" ^ t) ~base:"block"

  let module_name _ =
    "Block"

  let packages _ = [
    match !mode with
    | `Unix -> "mirage-block-unix"
    | `Xen  -> "mirage-block-xen"
  ]

  let libraries _ = [
    match !mode with
    | `Unix -> "mirage-block-unix"
    | `Xen  -> "mirage-block-xen.front"
  ]

  let configure t =
    append_main "let %s () =" (name t);
    append_main "  %s.connect %S" (module_name t) t;
    newline_main ()

  let clean t =
    ()

  let update_path t root =
    if Sys.file_exists (root / t) then
      root / t
    else
      t

end

type block = BLOCK

let block = Type BLOCK

let block_of_file filename =
  impl block filename (module Block)

module Fat = struct

  type t = block impl

  let name t =
    Name.of_key ("fat" ^ (Impl.name t)) ~base:"fat"

  let module_name t =
    String.capitalize (name t)

  let packages t = [
    "fat-filesystem";
  ]
    @ Io_page.packages ()
    @ Block.packages t

  let libraries t = [
    "fat-filesystem";
  ]
    @ Io_page.libraries ()
    @ Block.libraries t

  let configure t =
    Impl.configure t;
    append_main "module %s = Fat.Fs.Make(%s)(Io_page)"
      (module_name t)
      (Impl.module_name t);
    newline_main ();
    let name = name t in
    append_main "let %s () =" name;
    append_main "  %s () >>= function" (Impl.name t);
    append_main "  | `Error _ -> %s" (driver_initialisation_error name);
    append_main "  | `Ok dev  -> %s.connect dev" (module_name t);
    newline_main ()

  let clean t =
    Impl.clean t

  let update_path t root =
    Impl.update_path t root

end

type fs = FS

let fs = Type FS

let fat block =
    impl fs block (module Fat)

(* This would deserve to be in its own lib. *)
let kv_ro_of_fs x =
  let dummy_fat = fat (block_of_file "xx") in
  let libraries = Impl.libraries dummy_fat in
  let packages = Impl.packages dummy_fat in
  let fn = foreign "Fat.KV_RO.Make" ~libraries ~packages (fs @-> kv_ro) in
  fn $ x

module Fat_of_files = struct

  type t = {
    dir   : string option;
    regexp: string;
  }

  let name t =
    Name.of_key
      ("fat" ^ (match t.dir with None -> "." | Some d -> d) ^ ":" ^ t.regexp)
      ~base:"fat"

  let module_name t =
    String.capitalize (name t)

  let block_file t =
    name t ^ ".img"

  let block t =
    block_of_file (block_file t)

  let packages t =
    Fat.packages (block t)

  let libraries t =
    Fat.libraries (block t)

  let configure t =
    let fat = fat (block t) in
    Impl.configure fat;
    append_main "module %s = %s" (module_name t) (Impl.module_name fat);
    append_main "let %s = %s" (name t) (Impl.name fat);
    newline_main ();
    let file = Printf.sprintf "make-%s-image.sh" (name t) in
    let oc = open_out file in
    append oc "#!/bin/sh";
    append oc "";
    append oc "echo This uses the 'fat' command-line tool to build a simple FAT";
    append oc "echo filesystem image.";
    append oc "";
    append oc "FAT=$(which fat)";
    append oc "if [ ! -x \"${FAT}\" ]; then";
    append oc "  echo I couldn\\'t find the 'fat' command-line tool.";
    append oc "  echo Try running 'opam install fat-filesystem'";
    append oc "  exit 1";
    append oc "fi";
    append oc "";
    append oc "IMG=$(pwd)/%s" (block_file t);
    append oc "rm -f ${IMG}";
    (match t.dir with None -> () | Some d -> append oc "cd %s/" d);
    append oc "SIZE=$(du -s . | cut -f 1)";
    append oc "${FAT} create ${IMG} ${SIZE}KiB";
    append oc "${FAT} add ${IMG} %s" t.regexp;
    append oc "echo Created '%s'" (block_file t);

    close_out oc;
    Unix.chmod file 0o755;
    command "./make-%s-image.sh" (name t)

  let clean t =
    command "rm -f make-%s-image.sh %s" (name t) (block_file t);
    Impl.clean (block t)

  let update_path t root =
    match t.dir with
    | None   -> t
    | Some d -> { t with dir = Some (root / d) }

end

let fat_of_files: ?dir:string -> ?regexp:string -> unit -> fs impl =
  fun ?dir ?regexp () ->
    let regexp = match regexp with
      | None   -> "*"
      | Some r -> r in
    impl fs { Fat_of_files.dir; regexp } (module Fat_of_files)

type network_config = Tap0 | Custom of string

module Network = struct

  type t = network_config

  let name t =
    "net_" ^ match t with
    | Tap0     -> "tap0"
    | Custom s -> s

  let module_name _ =
    "Netif"

  let packages t =
    match !mode with
    | `Unix -> ["mirage-net-unix"]
    | `Xen  -> ["mirage-net-xen"]

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

let tap0 =
  impl network Tap0 (module Network)

let netif dev =
  impl network (Custom dev) (module Network)

module Ethif = struct

  type t = network impl

  let name t =
    Name.of_key ("ethif" ^ Impl.name t) ~base:"ethif"

  let module_name t =
    String.capitalize (name t)

  let packages t =
    Impl.packages t @ ["tcpip"]

  let libraries t =
    Impl.libraries t @
    match !mode with
    | `Unix -> [ "tcpip.ethif-unix" ]
    | `Xen  -> [ "tcpip.ethif" ]

  let configure t =
    let name = name t in
    Impl.configure t;
    append_main "module %s = Ethif.Make(%s)" (module_name t) (Impl.module_name t);
    newline_main ();
    append_main "let %s () =" name;
    append_main "   %s () >>= function" (Impl.name t);
    append_main "   | `Error _ -> %s" (driver_initialisation_error name);
    append_main "   | `Ok eth  -> %s.connect eth" (module_name t);
    newline_main ()

  let clean t =
    Impl.clean t

  let update_path t root =
    Impl.update_path t root

end

type ethernet = ETHERNET

let ethernet = Type ETHERNET

let etif network =
  impl ethernet network (module Ethif)

type ipv4_config = {
  address: Ipaddr.V4.t;
  netmask: Ipaddr.V4.t;
  gateways: Ipaddr.V4.t list;
}

let meta_ipv4_config t =
  Printf.sprintf "(Ipaddr.V4.of_string_exn %S, Ipaddr.V4.of_string_exn %S, [%s])"
    (Ipaddr.V4.to_string t.address)
    (Ipaddr.V4.to_string t.netmask)
    (String.concat "; "
       (List.map (Printf.sprintf "Ipaddr.V4.of_string_exn %S")
          (List.map Ipaddr.V4.to_string t.gateways)))

module IPV4 = struct

  type t = ethernet impl * ipv4_config
  (* XXX: should the type if ipv4.id be ipv4.t ?
     N.connect ethif |> N.set_ip up *)

  let name (e, i) =
    let key = "ipv4" ^ Impl.name e ^ meta_ipv4_config i in
    Name.of_key key ~base:"ipv4"

  let module_name t =
    String.capitalize (name t)

  let packages (t, _) =
    Impl.packages t @ ["tcpip"]

  let libraries (t, _) =
    Impl.libraries t @
    match !mode with
    | `Unix -> [ "tcpip.ipv4-unix" ]
    | `Xen  -> [ "tcpip.ipv4" ]

  let configure (eth, ip as t) =
    let name = name t in
    let mname = module_name t in
    Impl.configure eth;
    append_main "module %s = Ipv4.Make(%s)" (module_name t) (Impl.module_name eth);
    newline_main ();
    append_main "let %s () =" name;
    append_main "   %s () >>= function" (Impl.name eth);
    append_main "   | `Error _ -> %s" (driver_initialisation_error name);
    append_main "   | `Ok eth  ->";
    append_main "   %s.connect eth >>= function" mname;
    append_main "   | `Error _ -> %s" (driver_initialisation_error "IPV4");
    append_main "   | `Ok ip   ->";
    append_main "   let i = Ipaddr.V4.of_string_exn in";
    append_main "   %s.set_ip ip (i %S) >>= fun () ->"
      mname (Ipaddr.V4.to_string ip.address);
    append_main "   %s.set_netmask ip (i %S) >>= fun () ->"
      mname (Ipaddr.V4.to_string ip.netmask);
    append_main "   %s.set_gateways ip [%s] >>= fun () ->"
      mname
      (String.concat "; "
         (List.map
            (fun n -> Printf.sprintf "(i %S)" (Ipaddr.V4.to_string n))
            ip.gateways));
    append_main "   return (`Ok ip)";
    newline_main ()

  let clean (eth, _) =
    Impl.clean eth

  let update_path (eth, ip) root =
    (Impl.update_path eth root, ip)

end

type ipv4 = IPV4

let ipv4 = Type IPV4

let create_ipv4 net ip =
  let eth = etif net in
  impl ipv4 (eth, ip) (module IPV4)

let default_ipv4_conf =
  let i = Ipaddr.V4.of_string_exn in
  {
    address  = i "10.0.0.2";
    netmask  = i "255.255.255.0";
    gateways = [i "10.0.0.1"];
  }

let default_ipv4 net =
  create_ipv4 net default_ipv4_conf

module UDPV4_direct = struct

  type t = ipv4 impl

  let name t =
    Name.of_key ("udpv4" ^ Impl.name t) ~base:"udpv4"

  let module_name t =
    String.capitalize (name t)

  let packages t =
    Impl.packages t @ [ "tcpip" ]

  let libraries t =
    Impl.libraries t @ [ "tcpip.udpv4" ]

  let configure t =
    let name = name t in
    Impl.configure t;
    append_main "module %s = Udpv4.Make(%s)" (module_name t) (Impl.module_name t);
    newline_main ();
    append_main "let %s () =" name;
    append_main "   %s () >>= function" (Impl.name t);
    append_main "   | `Error _ -> %s" (driver_initialisation_error name);
    append_main "   | `Ok ip   -> %s.connect ip" (module_name t);
    newline_main ()

  let clean t =
    Impl.clean t

  let update_path t root =
    Impl.update_path t root

end

module UDPV4_socket = struct

  type t = Ipaddr.V4.t option

  let name _ = "udpv4_socket"

  let module_name _ = "Udpv4_socket"

  let packages t = [ "tcpip" ]

  let libraries t =
    match !mode with
    | `Unix -> [ "tcpip.udpv4-socket" ]
    | `Xen  -> failwith "No socket implementation available for Xen"

  let configure t =
    append_main "let %s () =" (name t);
    let ip = match t with
      | None    -> "None"
      | Some ip ->
        Printf.sprintf "Some (Ipaddr.V4.of_string_exn %s)" (Ipaddr.V4.to_string ip)
    in
    append_main " %s.connect %S" (module_name t) ip;
    newline_main ()

  let clean t =
    ()

  let update_path t root =
    t

end

type udpv4 = UDPV4

let udpv4 = Type UDPV4

let direct_udpv4 ip =
  impl udpv4 ip (module UDPV4_direct)

let socket_udpv4 ip =
  impl udpv4 ip (module UDPV4_socket)

module TCPV4_direct = struct

  type t = ipv4 impl

  let name t =
    Name.of_key ("tcpv4" ^ Impl.name t) ~base:"tcpv4"

  let module_name t =
    String.capitalize (name t)

  let packages t =
    Impl.packages t @ [ "tcpip" ]

  let libraries t =
    Impl.libraries t @ [ "tcpip.tcpv4" ]

  let configure t =
    let name = name t in
    Impl.configure t;
    append_main "module %s = Tcpv4.Flow.Make(%s)(OS.Time)(Clock)(Random)"
      (module_name t) (Impl.module_name t);
    newline_main ();
    append_main "let %s () =" name;
    append_main "   %s () >>= function" (Impl.name t);
    append_main "   | `Error _ -> %s" (driver_initialisation_error name);
    append_main "   | `Ok ip   -> %s.connect ip" (module_name t);
    newline_main ()

  let clean t =
    Impl.clean t

  let update_path t root =
    Impl.update_path t root

end

module TCPV4_socket = struct

  type t = Ipaddr.V4.t option

  let name _ = "tcpv4_socket"

  let module_name _ = "Tcpv4_socket"

  let packages t = [ "tcpip" ]

  let libraries t =
    match !mode with
    | `Unix -> [ "tcpip.tcpv4-socket" ]
    | `Xen  -> failwith "No socket implementation available for Xen"

  let configure t =
    append_main "let %s () =" (name t);
    let ip = match t with
      | None    -> "None"
      | Some ip ->
        Printf.sprintf "Some (Ipaddr.V4.of_string_exn %s)" (Ipaddr.V4.to_string ip)
    in
    append_main "  %s.connect %S" (module_name t) ip;
    newline_main ()

  let clean t =
    ()

  let update_path t root =
    t

end

type tcpv4 = TCPV4

let tcpv4 = Type TCPV4

let direct_tcpv4 ip =
  impl tcpv4 ip (module TCPV4_direct)

let socket_tcpv4 ip =
  impl tcpv4 ip (module TCPV4_socket)

module STACKV4_direct = struct

  type t = console impl * network impl * [`DHCP | `IPV4 of ipv4_config]

  let name (c, n, m) =
    let key = "stackv4" ^ Impl.name c ^ Impl.name n ^
              match m with
              | `DHCP   -> "dhcp"
              | `IPV4 i -> meta_ipv4_config i in
    Name.of_key key ~base:"stackv4"

  let module_name t =
    String.capitalize (name t)

  let packages (c, n, _) =
    Impl.packages c @ Impl.packages n @ Clock.packages () @ [ "tcpip" ]

  let libraries (c, n, _) =
    Impl.libraries c @ Impl.libraries n @ Clock.libraries () @
    [ "tcpip.stack-direct" ]

  let configure (c, n, m as t) =
    let name = name t in
    Impl.configure c;
    Impl.configure n;
    append_main "module %s = struct" (module_name t);
    append_main "  module E = Ethif.Make(%s)" (Impl.module_name n);
    append_main "  module I = Ipv4.Make(E)";
    append_main "  module U = Udpv4.Make(I)";
    append_main "  module T = Tcpv4.Flow.Make(I)(OS.Time)(Clock)(Random)";
    append_main "  module S = Tcpip_stack_direct.Make(%s)(OS.Time)(Random)(%s)(E)(I)(U)(T)"
      (Impl.module_name c) (Impl.module_name n);

    append_main "  include S";
    append_main "end";
    newline_main ();
    append_main "let %s () =" name;
    append_main "  %s () >>= function" (Impl.name c);
    append_main "  | `Error _    -> %s" (driver_initialisation_error (Impl.name c));
    append_main "  | `Ok console ->";
    append_main "  %s () >>= function" (Impl.name n);
    append_main "  | `Error _      -> %s" (driver_initialisation_error (Impl.name n));
    append_main "  | `Ok interface ->";
    append_main "  let config = {";
    append_main "    V1_LWT.name = %S;" name;
    append_main "    console; interface;";
    begin match m with
      | `DHCP   -> append_main "    mode = `DHCP;"
      | `IPV4 i -> append_main "    mode = `IPv4 %s;" (meta_ipv4_config i);
    end;
    append_main "  } in";
    append_main "  %s.connect config" (module_name t);
    newline_main ()

  let clean (c, e, _) =
    Impl.clean c;
    Impl.clean e

  let update_path (c, e, m) root =
    Impl.update_path c root,
    Impl.update_path e root,
    m

end

module STACKV4_socket = struct

  type t = console impl * Ipaddr.V4.t list

  let meta_ips ips =
    String.concat "; "
      (List.map (fun x ->
           Printf.sprintf "Ipaddr.V4.of_string_exn %S" (Ipaddr.V4.to_string x)
         ) ips)

  let name (c, ips) = let key = "stackv4" ^ Impl.name c ^ meta_ips ips in
    Name.of_key key ~base:"stackv4"

  let module_name t =
    String.capitalize (name t)

  let packages (c, _) =
    Impl.packages c @ [ "tcpip" ]

  let libraries (c, _) =
    Impl.libraries c @ [ "tcpip.stack-socket" ]

  let configure (c, ips as t) =
    let name = name t in
    Impl.configure c;
    append_main "module %s = Tcpip_stack_socket.Make(%s)"
      (module_name t) (Impl.module_name c);
    newline_main ();
    append_main "let %s () =" name;
    append_main "  %s () >>= function" (Impl.name c);
    append_main "  | `Error _    -> %s" (driver_initialisation_error (Impl.name c));
    append_main "  | `Ok console ->";
    append_main "  let config = {";
    append_main "    V1_LWT.name = %S;" name;
    append_main "    console; interface = [%s];" (meta_ips ips);
    append_main "    mode = ();";
    append_main "  } in";
    append_main "  %s.connect config" (module_name t);
    newline_main ()

  let clean (c, _) =
    Impl.clean c

  let update_path (c, ips) root =
    (Impl.update_path c root, ips)

end


type stackv4 = STACK4

let stackv4 = Type STACK4

let direct_stackv4_with_dhcp console network =
  impl stackv4 (console, network, `DHCP) (module STACKV4_direct)

let direct_stackv4_with_default_ipv4 console network =
  impl stackv4 (console, network, `IPV4 default_ipv4_conf) (module STACKV4_direct)

let direct_stackv4_with_static_ipv4 console network ipv4 =
  impl stackv4 (console, network, `IPV4 ipv4) (module STACKV4_direct)

let socket_stackv4 console ips =
  impl stackv4 (console, ips) (module STACKV4_socket)


module Channel_over_TCPV4 = struct

  type t = tcpv4 impl

  let name t =
    let key = "channel" ^ Impl.name t in
    Name.of_key key ~base:"channel"

  let module_name t =
    String.capitalize (name t)

  let packages _ =
    [ "mirage-tcpip" ]

  let libraries _ =
    [ "tcpip.channel" ]

  let configure t =
    Impl.configure t;
    append_main "module %s = Channel.Make(%s)" (module_name t) (Impl.module_name t);
    newline_main ();
    append_main "let %s () =" (name t);
    append_main "  %s () >>= function" (Impl.name t);
    append_main "  | `Error _    -> %s" (driver_initialisation_error (Impl.name t));
    append_main "  | `Ok console ->";
    append_main "  let flow = %s.create config in" (module_name t);
    append_main "  return (`Ok flow)";
    newline_main ()

  let clean t =
    Impl.clean t

  let update_path t root =
    Impl.update_path t root

end

type channel = CHANNEL

let channel = Type CHANNEL

let channel_over_tcpv4 flow =
  impl channel flow (module Channel_over_TCPV4)


module HTTP = struct

  type t =
    [ `Channel of channel impl
    | `Stack of int * stackv4 impl ]

  let name t =
    let key = "http" ^ match t with
      | `Channel c    -> Impl.name c
      | `Stack (_, s) -> Impl.name s in
    Name.of_key key ~base:"http"

  let module_name_core t =
    String.capitalize (name t)

  let module_name t =
    module_name_core t ^ ".Server"

  let packages t =
    [ "mirage-http" ] @
    match t with
    | `Channel c    -> Impl.packages c
    | `Stack (_, s) -> Impl.packages s

  let libraries t =
    [ "mirage-http" ] @
    match t with
    | `Channel c    -> Impl.libraries c
    | `Stack (_, s) -> Impl.libraries s

  let configure t =
    begin match t with
      | `Channel c ->
        Impl.configure c;
        append_main "module %s = HTTP.Make(%s)" (module_name_core t) (Impl.module_name c)
      | `Stack (_, s) ->
        Impl.configure s;
        append_main "module %s_channel = Channel.Make(%s.TCPV4)"
          (module_name_core t) (Impl.module_name s);
        append_main "module %s = HTTP.Make(%s_channel)" (module_name_core t) (module_name_core t)
    end;
    newline_main ();
    let subname = match t with
      | `Channel c   -> Impl.name c
      | `Stack (_,s) -> Impl.name s in
    append_main "let %s () =" (name t);
    append_main "  %s () >>= function" subname;
    append_main "  | `Error _  -> %s" (driver_initialisation_error subname);
    append_main "  | `Ok stack ->";
    begin match t with
      | `Channel c   -> failwith "TODO"
      | `Stack (p,s) ->
        append_main "  let listen spec =";
        append_main "    %s.listen_tcpv4 ~port:%d stack (fun flow ->" (Impl.module_name s) p;
        append_main "      let chan = %s_channel.create flow in" (module_name_core t);
        append_main "      %s.Server_core.callback spec chan chan" (module_name_core t);
        append_main "    );";
        append_main "    %s.listen stack in" (Impl.module_name s);
        append_main "  return (`Ok listen)";
    end;
    newline_main ()

  let clean = function
    | `Channel c    -> Impl.clean c
    | `Stack (_, s) -> Impl.clean s

  let update_path t root =
    match t with
    | `Channel c    -> `Channel (Impl.update_path c root)
    | `Stack (p, s) -> `Stack (p, Impl.update_path s root)

end

type http = HTTP

let http = Type HTTP

let http_server_of_channel chan =
  impl http (`Channel chan) (module HTTP)

let http_server port stack =
  impl http (`Stack (port, stack)) (module HTTP)

type job = JOB

let job = Type JOB

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

  let module_name t =
    "Job_" ^ t.name

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
    | `Unix -> "mirage-unix"
    | `Xen  -> "mirage-xen" in
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
    | `Unix -> "mirage-types.lwt"
    | `Xen  -> "mirage-types.lwt" in
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
    | `Xen  ->
      append oc "FLAGS  = -cflag -g -lflags -g,-linkpkg,-dontlink,unix\n"
    | `Unix ->
      append oc "FLAGS  = -cflag -g -lflags -g,-linkpkg\n"
  end;
  append oc "BUILD  = ocamlbuild -classic-display -use-ocamlfind $(LIBS) $(SYNTAX) $(FLAGS)\n\
             OPAM   = opam\n\n\
             export OPAMVERBOSE=1\n\
             export OPAMYES=1";
  newline oc;
  append oc ".PHONY: all depend clean build main.native\n\
             all: build\n\
             \n\
             depend:\n\
             \t$(OPAM) install $(PKGS) --verbose\n\
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
      append oc "\tld -d -static -nostdlib --start-group \\\n\
                 \t  $(shell pkg-config --static --libs openlibm libminios) \\\n\
                 \t  _build/main.native.o %s/libocaml.a \\\n\
                 \t  %s/libxencaml.a --end-group -o mir-%s.xen"
        lib lib t.name;
    | `Unix ->
      append oc "build: main.native";
      append oc "\tln -nfs _build/main.native mir-%s" t.name;
  end;
  newline oc;
  append oc "run: build";
  begin match !mode with
    | `Xen ->
      append oc "\t@echo %s.xl has been created. Edit it to add VIFs or VBDs" t.name;
      append oc "\t@echo Then do something similar to: xl create -c %s.xl\n" t.name
    | `Unix ->
      append oc "\t$(SUDO) ./mir-%s\n" t.name
  end;
  append oc "clean:\n\
             \tocamlbuild -clean";
  close_out oc

let clean_makefile t =
  remove (t.root / "Makefile")

let configure_job j =
  let name = Impl.name j in
  let module_name = Impl.module_name j in
  let param_names = Impl.names j in
  append_main "let %s () =" name;
  List.iter (fun p ->
      append_main "  %s () >>= function" p;
      append_main "  | `Error e -> %s" (driver_initialisation_error p);
      append_main "  | `Ok %s ->" p;
    ) (dedup param_names);
  append_main "  %s.start %s" module_name (String.concat " " param_names);
  newline_main ()

let configure_main t =
  info "%s main.ml" (blue_s "Generating:");
  set_main_ml (t.root / "main.ml");
  append_main "(* %s *)" generated_by_mirage;
  newline_main ();
  append_main "open Lwt";
  newline_main ();
  append_main "let _ = Printexc.record_backtrace true";
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
  info "%s %s" (blue_s "Using configuration:") (t.root / "config.ml");
  info "%d job%s [%s]"
    (List.length t.jobs)
    (if List.length t.jobs = 1 then "" else "s")
    (String.concat ", " (List.map Impl.functor_name t.jobs));
  in_dir t.root (fun () ->
      configure_myocamlbuild_ml t;
      configure_makefile t;
      configure_main_xl t;
      configure_main t
    );
  info "%s" (blue_s "Now run 'make depend' to install the package dependencies for this unikernel.")

let make () =
  match uname_s () with
  | Some ("FreeBSD" | "OpenBSD" | "NetBSD" | "DragonFly") -> "gmake"
  | _ -> "make"

let build t =
  info "Build: %s" (blue_s (t.root / "config.ml"));
  in_dir t.root (fun () ->
      command "%s build" (make ())
    )

let run t =
  info "Run: %s" (blue_s (t.root / "config.ml"));
  in_dir t.root (fun () ->
      command "%s run" (make ())
    )

let clean t =
  info "Clean: %s" (blue_s (t.root / "config.ml"));
  in_dir t.root (fun () ->
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
  info "%s %s" (blue_s "Processing:") file;
  let root = Filename.dirname file in
  let file = Filename.basename file in
  let file = Dynlink.adapt_filename file in
  command "rm -rf %s/_build/%s.*" root (Filename.chop_extension file);
  command "cd %s && ocamlbuild -use-ocamlfind -tags annot,bin_annot -pkg mirage %s" root file;
  try Dynlink.loadfile (String.concat "/" [root; "_build"; file])
  with Dynlink.Error err -> error "Error loading config: %s" (Dynlink.error_message err)

(* If a configuration file is specified, then use that.
 * If not, then scan the curdir for a `config.ml` file.
 * If there is more than one, then error out. *)
let scan_conf = function
  | Some f ->
    info "%s %s" (blue_s "Using specified config file:") f;
    if not (Sys.file_exists f) then error "%s does not exist, stopping." f;
    realpath f
  | None   ->
    let files = Array.to_list (Sys.readdir ".") in
    match List.filter ((=) "config.ml") files with
    | [] -> error "No configuration file config.ml found.\n\
                   You'll need to create one to let Mirage know what to do."
    | [f] ->
      info "%s %s" (blue_s "Using scanned config file:") f;
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
