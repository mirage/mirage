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
  | `MacOSX
]

let string_of_mode =
  function
  | `Unix -> "Unix"
  | `Xen -> "Xen"
  | `MacOSX -> "MacOS X"

let mode : mode ref = ref `Unix

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
    | Foreign _            -> []
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

  let packages () = [
    "io-page"
  ]

  let libraries () =
    match !mode with
    | `Xen  -> ["io-page"]
    | `Unix | `MacOSX -> ["io-page"; "io-page.unix"]

  let configure () = ()

  let clean () = ()

  let update_path () _ = ()

end

type io_page = IO_PAGE

let io_page = Type IO_PAGE

let default_io_page: io_page impl =
  impl io_page () (module Io_page)

module Time = struct

  (** OS Timer. *)

  type t = unit

  let name () =
    "time"

  let module_name () =
    "OS.Time"

  let packages () = []

  let libraries () = []

  let configure () =
    append_main "let time () = return (`Ok ())";
    newline_main ()

  let clean () = ()

  let update_path () _ = ()

end

type time = TIME

let time = Type TIME

let default_time: time impl =
  impl time () (module Time)

module Clock = struct

  (** Clock operations. *)

  type t = unit

  let name () =
    "clock"

  let module_name () =
    "Clock"

  let packages () = [
    match !mode with
    | `Unix | `MacOSX -> "mirage-clock-unix"
    | `Xen  -> "mirage-clock-xen"
  ]

  let libraries () = packages ()

  let configure () =
    append_main "let clock () = return (`Ok ())";
    newline_main ()

  let clean () = ()

  let update_path () _ = ()

end

type clock = CLOCK

let clock = Type CLOCK

let default_clock: clock impl =
  impl clock () (module Clock)

module Random = struct

  type t = unit

  let name () =
    "random"

  let module_name () =
    "Random"

  let packages () = []

  let libraries () = []

  let configure () =
    append_main "let random () = return (`Ok ())";
    newline_main ()

  let clean () = ()

  let update_path () _ = ()

end

type random = RANDOM

let random = Type RANDOM

let default_random: random impl =
  impl random () (module Random)

module Console = struct

  type t = string

  let name t =
    Name.of_key ("console" ^ t) ~base:"console"

  let module_name t =
    "Console"

  let construction () =
    match !mode with
    | `Unix | `MacOSX -> "Console_unix"
    | `Xen  -> "Console_xen"

  let packages _ =
    match !mode with
    | `Unix | `MacOSX -> ["mirage-console"; "mirage-unix"]
    | `Xen  -> ["mirage-console"; "xenstore"; "mirage-xen"; "xen-gnt"; "xen-evtchn"]

  let libraries _ =
    match !mode with
    | `Unix | `MacOSX -> ["mirage-console.unix"]
    | `Xen -> ["mirage-console.xen"]

  let configure t =
    append_main "module %s = %s" (module_name t) (construction ());
    newline_main ();
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
  ] @ Io_page.packages ()

  let libraries _ = [
    "mirage-types";
    "lwt";
    "cstruct";
  ] @ Io_page.libraries ()

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
    | `Unix | `MacOSX -> "Kvro_fs_unix"

  let packages t =
    match !mode with
    | `Xen  -> Crunch.packages t
    | `Unix | `MacOSX -> "mirage-fs-unix" :: Crunch.packages t

  let libraries t =
    match !mode with
    | `Xen  -> Crunch.libraries t
    | `Unix | `MacOSX -> "mirage-fs-unix" :: Crunch.libraries t

  let configure t =
    match !mode with
    | `Xen  -> Crunch.configure t
    | `Unix | `MacOSX ->
      append_main "let %s () =" (name t);
      append_main "  Kvro_fs_unix.connect %S" t

end

let direct_kv_ro dirname =
  impl kv_ro dirname (module Direct_kv_ro)

module Block = struct

  type t = {
    filename: string;
    number: int;
  }

  let name t =
    Name.of_key ("block" ^ t.filename) ~base:"block"

  let module_name _ =
    "Block"

  let connect_name t =
    match !mode with
    | `Unix | `MacOSX -> t.filename (* open the file directly *)
    | `Xen ->
      (* We need the xenstore id *)
      (* Taken from https://github.com/mirage/mirage-block-xen/blob/a64d152586c7ebc1d23c5adaa4ddd440b45a3a83/lib/device_number.ml#L64 *)
      (if t.number < 16
       then (202 lsl 8) lor (t.number lsl 4)
       else (1 lsl 28)  lor (t.number lsl 8)) |> string_of_int

  let packages _ = [
    match !mode with
    | `Unix | `MacOSX -> "mirage-block-unix"
    | `Xen  -> "mirage-block-xen"
  ]

  let libraries _ = [
    match !mode with
    | `Unix | `MacOSX -> "mirage-block-unix"
    | `Xen  -> "mirage-block-xen.front"
  ]

  let configure t =
    append_main "let %s () =" (name t);
    append_main "  %s.connect %S" (module_name t) (connect_name t);
    newline_main ()

  let clean t =
    ()

  let update_path t root =
    if Sys.file_exists (root / t.filename) then
      { t with filename = root / t.filename }
    else
      t

end

type block = BLOCK

let block = Type BLOCK

let all_blocks = Hashtbl.create 7

let dummy_filename = "xx"

let block_of_file =
  let next_number = ref 0 in
  fun filename ->
    let b =
      if Hashtbl.mem all_blocks filename
      then Hashtbl.find all_blocks filename
      else begin
        let number =
          if filename = dummy_filename then
            !next_number
          else
            let number = !next_number in
            incr next_number;
            number
        in
        let b = { Block.filename; number } in
        Hashtbl.add all_blocks filename b;
        b
      end in
    impl block b (module Block)

let dummy_block = block_of_file dummy_filename

module Archive = struct

  type t = {
    block  : block impl;
  }

  let name t =
    let key = "archive" ^ Impl.name t.block in
    Name.of_key key ~base:"archive"

  let module_name t =
    String.capitalize (name t)

  let packages t =
    "tar-format"
    :: Impl.packages t.block

  let libraries t =
    "tar.mirage"
    :: Impl.libraries t.block

  let configure t =
    Impl.configure t.block;
    append_main "module %s = Tar_mirage.Make_KV_RO(%s)"
      (module_name t)
      (Impl.module_name t.block);
    newline_main ();
    let name = name t in
    append_main "let %s () =" name;
    append_main "  %s () >>= function" (Impl.name t.block);
    append_main "  | `Error _ -> %s" (driver_initialisation_error name);
    append_main "  | `Ok dev  -> %s.connect dev" (module_name t);
    newline_main ()

  let clean t =
    Impl.clean t.block

  let update_path t root =
    { block  = Impl.update_path t.block root;
    }

end

let archive block : kv_ro impl =
  let t = { Archive.block } in
  impl kv_ro t (module Archive)

module Archive_of_files = struct

  type t = {
    dir   : string;
  }

  let name t =
    Name.of_key
      ("archive" ^ t.dir)
      ~base:"archive"

  let module_name t =
    String.capitalize (name t)

  let block_file t =
    name t ^ ".img"

  let block t =
    block_of_file (block_file t)

  let packages t =
    Impl.packages (archive (block t))

  let libraries t =
    Impl.libraries (archive (block t))

  let configure t =
    let archive = archive (block t) in
    Impl.configure archive;
    if not (command_exists "tar") then
      error "tar not found, stopping.";
    let file = block_file t in
    info "%s %s" (blue_s "Generating:") (Sys.getcwd () / file);
    command "tar -C %s -cvf %s ." t.dir (block_file t);
    append_main "module %s = %s" (module_name t) (Impl.module_name archive);
    append_main "let %s = %s" (name t) (Impl.name archive);
    newline_main ()

  let clean t =
    command "rm -f %s" (block_file t);
    Impl.clean (block t)

  let update_path t root =
    { dir = root / t.dir }

end

let archive_of_files: ?dir:string -> unit -> kv_ro impl =
  fun ?(dir=".") () ->
    impl kv_ro { Archive_of_files.dir } (module Archive_of_files)

module Fat = struct

  type t = {
    io_page: io_page impl;
    block  : block impl;
  }

  let name t =
    let key = "fat" ^ Impl.name t.io_page ^ Impl.name t.block in
    Name.of_key key ~base:"fat"

  let module_name t =
    String.capitalize (name t)

  let packages t =
    "fat-filesystem"
    :: Impl.packages t.io_page
    @  Impl.packages t.block

  let libraries t =
    "fat-filesystem"
    :: Impl.libraries t.io_page
    @  Impl.libraries t.block

  let configure t =
    Impl.configure t.io_page;
    Impl.configure t.block;
    append_main "module %s = Fat.Fs.Make(%s)(%s)"
      (module_name t)
      (Impl.module_name t.block)
      (Impl.module_name t.io_page);
    newline_main ();
    let name = name t in
    append_main "let %s () =" name;
    append_main "  %s () >>= function" (Impl.name t.block);
    append_main "  | `Error _ -> %s" (driver_initialisation_error name);
    append_main "  | `Ok dev  -> %s.connect dev" (module_name t);
    newline_main ()

  let clean t =
    Impl.clean t.block;
    Impl.clean t.io_page

  let update_path t root =
    { io_page = Impl.update_path t.io_page root;
      block  = Impl.update_path t.block root;
    }

end

type fs = FS

let fs = Type FS

let fat ?(io_page=default_io_page) block: fs impl =
  let t = { Fat.block; io_page } in
  impl fs t (module Fat)

(* This would deserve to be in its own lib. *)
let kv_ro_of_fs x: kv_ro impl =
  let dummy_fat = fat dummy_block in
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
    Impl.packages (fat (block t))

  let libraries t =
    Impl.libraries (fat (block t))

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
    | `MacOSX -> ["mirage-net-macosx"]
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
    | `Unix | `MacOSX -> [ "tcpip.ethif-unix" ]
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

module Arpv4 = struct
  type t = {
    ethernet: ethernet impl;
    clock: clock impl;
    time: time impl;
  }

  let name t =
    Name.of_key ("arpv4" ^ Impl.name t.ethernet) ~base:"arpv4"

  let module_name t =
    String.capitalize (name t)

  let packages t =
    "tcpip" :: Impl.packages t.time @ Impl.packages t.clock @ Impl.packages t.ethernet

  let libraries t =
    let arp_library =
      match !mode with
      | `Unix | `MacOSX -> "tcpip.arpv4-unix"
      | `Xen  -> "tcpip.arpv4"
    in
    arp_library ::
    Impl.libraries t.ethernet @
    Impl.libraries t.clock @
    Impl.libraries t.ethernet

  let configure t =
    let name = name t in
    let mname = module_name t in
    append_main "module %s = Arpv4.Make(%s)(%s)(%s)" mname
      (Impl.module_name t.ethernet)
      (Impl.module_name t.clock)
      (Impl.module_name t.time);
    newline_main ();
    append_main "let %s () =" name;
    append_main "   %s () >>= function" (Impl.name t.ethernet);
    append_main "   | `Error _ -> %s" (driver_initialisation_error name);
    append_main "   | `Ok eth  ->";
    append_main "   %s.connect eth >>= function" mname;
    append_main "   | `Error _ -> %s" (driver_initialisation_error "ARP");
    append_main "   | `Ok arp   -> arp"

  let clean t =
    Impl.clean t.ethernet

  let update_path t root =
    { t with ethernet = Impl.update_path t.ethernet root }

end

type arpv4 = Arpv4
let arpv4 = Type Arpv4

let arp ?(clock = default_clock) ?(time = default_time) (eth : ethernet impl) = impl arpv4
    { Arpv4.ethernet = eth;
      clock;
      time
    } (module Arpv4)


type ('ipaddr, 'prefix) ip_config = {
  address: 'ipaddr;
  netmask: 'prefix;
  gateways: 'ipaddr list;
}

type ipv4_config = (Ipaddr.V4.t, Ipaddr.V4.t) ip_config

let meta_ipv4_config t =
  Printf.sprintf "(Ipaddr.V4.of_string_exn %S, Ipaddr.V4.of_string_exn %S, [%s])"
    (Ipaddr.V4.to_string t.address)
    (Ipaddr.V4.to_string t.netmask)
    (String.concat "; "
       (List.map (Printf.sprintf "Ipaddr.V4.of_string_exn %S")
          (List.map Ipaddr.V4.to_string t.gateways)))

module IPV4 = struct

  type t = {
    arpv4 : arpv4 impl;
    config  : ipv4_config;
  }
  (* XXX: should the type if ipv4.id be ipv4.t ?
     N.connect ethif |> N.set_ip up *)

  let name t =
    let key = "ipv4" ^ Impl.name t.arpv4 ^ meta_ipv4_config t.config in
    Name.of_key key ~base:"ipv4"

  let module_name t =
    String.capitalize (name t)

  let packages t =
    "tcpip" :: Impl.packages t.arpv4

  let libraries t  =
    (match !mode with
     | `Unix | `MacOSX -> [ "tcpip.ipv4-unix" ]
     | `Xen  -> [ "tcpip.ipv4" ])
    @ Impl.libraries t.arpv4

  let configure t =
    let name = name t in
    let mname = module_name t in
    Impl.configure t.arpv4;
    append_main "module %s = Ipv4.Make(%s)"
      (module_name t) (Impl.module_name t.arpv4);
    newline_main ();
    append_main "let %s () =" name;
    append_main "   %s () >>= function" (Impl.name t.arpv4);
    append_main "   | `Error _ -> %s" (driver_initialisation_error name);
    append_main "   | `Ok arp ->";
    append_main "   %s.connect arp >>= function" mname;
    append_main "   | `Error _ -> %s" (driver_initialisation_error "IPV4");
    append_main "   | `Ok ip   ->";
    append_main "   let i = Ipaddr.V4.of_string_exn in";
    append_main "   %s.set_ip ip (i %S) >>= fun () ->"
      mname (Ipaddr.V4.to_string t.config.address);
    append_main "   %s.set_ip_netmask ip (i %S) >>= fun () ->"
      mname (Ipaddr.V4.to_string t.config.netmask);
    append_main "   %s.set_ip_gateways ip [%s] >>= fun () ->"
      mname
      (String.concat "; "
         (List.map
            (fun n -> Printf.sprintf "(i %S)" (Ipaddr.V4.to_string n))
            t.config.gateways));
    append_main "   return (`Ok ip)";
    newline_main ()

  let clean t =
    Impl.clean t.arpv4

  let update_path t root =
    { t with arpv4 = Impl.update_path t.arpv4 root }

end

type ipv6_config = (Ipaddr.V6.t, Ipaddr.V6.Prefix.t list) ip_config

let meta_ipv6_config t =
  Printf.sprintf "(Ipaddr.V6.of_string_exn %S, [%s], [%s])"
    (Ipaddr.V6.to_string t.address)
    (String.concat "; "
       (List.map (Printf.sprintf "Ipaddr.V6.Prefix.of_string_exn %S")
          (List.map Ipaddr.V6.Prefix.to_string t.netmask)))
    (String.concat "; "
       (List.map (Printf.sprintf "Ipaddr.V6.of_string_exn %S")
          (List.map Ipaddr.V6.to_string t.gateways)))

module IPV6 = struct

  type t = {
    time    : time impl;
    clock   : clock impl;
    ethernet: ethernet impl;
    config  : ipv6_config;
  }
  (* XXX: should the type if ipv4.id be ipv4.t ?
     N.connect ethif |> N.set_ip up *)

  let name t =
    let key = "ipv6" ^ Impl.name t.time ^ Impl.name t.clock ^ Impl.name t.ethernet ^ meta_ipv6_config t.config in
    Name.of_key key ~base:"ipv6"

  let module_name t =
    String.capitalize (name t)

  let packages t =
    "tcpip" :: Impl.packages t.time @ Impl.packages t.clock @ Impl.packages t.ethernet

  let libraries t  =
    (match !mode with
     | `Unix | `MacOSX -> [ "tcpip.ipv6-unix" ]
     | `Xen  -> [ "tcpip.ipv6" ])
    @ Impl.libraries t.time @ Impl.libraries t.clock @ Impl.libraries t.ethernet

  let configure t =
    let name = name t in
    let mname = module_name t in
    Impl.configure t.ethernet;
    append_main "module %s = Ipv6.Make(%s)(%s)(%s)"
      (module_name t) (Impl.module_name t.ethernet) (Impl.module_name t.time) (Impl.module_name t.clock);
    newline_main ();
    append_main "let %s () =" name;
    append_main "   %s () >>= function" (Impl.name t.ethernet);
    append_main "   | `Error _ -> %s" (driver_initialisation_error name);
    append_main "   | `Ok eth  ->";
    append_main "   %s.connect eth >>= function" mname;
    append_main "   | `Error _ -> %s" (driver_initialisation_error name);
    append_main "   | `Ok ip   ->";
    append_main "   let i = Ipaddr.V6.of_string_exn in";
    append_main "   %s.set_ip ip (i %S) >>= fun () ->"
      mname (Ipaddr.V6.to_string t.config.address);
    List.iter begin fun netmask ->
      append_main "   %s.set_ip_netmask ip (i %S) >>= fun () ->"
        mname (Ipaddr.V6.Prefix.to_string netmask)
    end t.config.netmask;
    append_main "   %s.set_ip_gateways ip [%s] >>= fun () ->"
      mname
      (String.concat "; "
         (List.map
            (fun n -> Printf.sprintf "(i %S)" (Ipaddr.V6.to_string n))
            t.config.gateways));
    append_main "   return (`Ok ip)";
    newline_main ()

  let clean t =
    Impl.clean t.time;
    Impl.clean t.clock;
    Impl.clean t.ethernet

  let update_path t root =
    { t with
      time = Impl.update_path t.time root;
      clock = Impl.update_path t.clock root;
      ethernet = Impl.update_path t.ethernet root }

end

type v4
type v6

type 'a ip = IP

let ip = Type IP

type ipv4 = v4 ip
type ipv6 = v6 ip

let ipv4 : ipv4 typ = ip
let ipv6 : ipv6 typ = ip

let create_ipv4 ?(clock = default_clock) ?(time = default_time) net config =
  let etif = etif net in
  let arp = arp ~clock ~time etif in
  let t = {
    IPV4.arpv4 = arp;
    config } in
  impl ipv4 t (module IPV4)

let default_ipv4_conf =
  let i = Ipaddr.V4.of_string_exn in
  {
    address  = i "10.0.0.2";
    netmask  = i "255.255.255.0";
    gateways = [i "10.0.0.1"];
  }

let default_ipv4 net =
  create_ipv4 net default_ipv4_conf

let create_ipv6
    ?(time = default_time)
    ?(clock = default_clock)
    net config =
  let etif = etif net in
  let t = {
    IPV6.ethernet = etif;
    time; clock;
    config
  } in
  impl ipv6 t (module IPV6)

module UDP_direct (V : sig type t end) = struct

  type t = V.t ip impl

  let name t =
    Name.of_key ("udp" ^ Impl.name t) ~base:"udp"

  let module_name t =
    String.capitalize (name t)

  let packages t =
    Impl.packages t @ [ "tcpip" ]

  let libraries t =
    Impl.libraries t @ [ "tcpip.udp" ]

  let configure t =
    let name = name t in
    Impl.configure t;
    append_main "module %s = Udp.Make(%s)" (module_name t) (Impl.module_name t);
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
    | `Unix | `MacOSX -> [ "tcpip.udpv4-socket" ]
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

type 'a udp = UDP

type udpv4 = v4 udp
type udpv6 = v6 udp

let udp = Type UDP
let udpv4 : udpv4 typ = udp
let udpv6 : udpv6 typ = udp

let direct_udp (type v) (ip : v ip impl) =
  impl udp ip (module UDP_direct (struct type t = v end))

let socket_udpv4 ip =
  impl udpv4 ip (module UDPV4_socket)

module TCP_direct (V : sig type t end) = struct

  type t = {
    clock : clock impl;
    time  : time impl;
    ip    : V.t ip impl;
    random: random impl;
  }

  let name t =
    let key = "tcp"
              ^ Impl.name t.clock
              ^ Impl.name t.time
              ^ Impl.name t.ip in
    Name.of_key key ~base:"tcp"

  let module_name t =
    String.capitalize (name t)

  let packages t =
    "tcpip"
    :: Impl.packages t.clock
    @  Impl.packages t.time
    @  Impl.packages t.ip
    @  Impl.packages t.random

  let libraries t =
    "tcpip.tcp"
    :: Impl.libraries t.clock
    @  Impl.libraries t.time
    @  Impl.libraries t.ip
    @  Impl.libraries t.random

  let configure t =
    let name = name t in
    Impl.configure t.clock;
    Impl.configure t.time;
    Impl.configure t.ip;
    Impl.configure t.random;
    append_main "module %s = Tcp.Flow.Make(%s)(%s)(%s)(%s)"
      (module_name t)
      (Impl.module_name t.ip)
      (Impl.module_name t.time)
      (Impl.module_name t.clock)
      (Impl.module_name t.random);
    newline_main ();
    append_main "let %s () =" name;
    append_main "   %s () >>= function" (Impl.name t.ip);
    append_main "   | `Error _ -> %s" (driver_initialisation_error (Impl.name t.ip));
    append_main "   | `Ok ip   -> %s.connect ip" (module_name t);
    newline_main ()

  let clean t =
    Impl.clean t.clock;
    Impl.clean t.time;
    Impl.clean t.ip;
    Impl.clean t.random

  let update_path t root =
    { clock  = Impl.update_path t.clock root;
      ip     = Impl.update_path t.ip root;
      time   = Impl.update_path t.time root;
      random = Impl.update_path t.random root;
    }

end

module TCPV4_socket = struct

  type t = Ipaddr.V4.t option

  let name _ = "tcpv4_socket"

  let module_name _ = "Tcpv4_socket"

  let packages t = [ "tcpip" ]

  let libraries t =
    match !mode with
    | `Unix | `MacOSX -> [ "tcpip.tcpv4-socket" ]
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

type 'a tcp = TCP

type tcpv4 = v4 tcp
type tcpv6 = v6 tcp

let tcp = Type TCP
let tcpv4 : tcpv4 typ = tcp
let tcpv6 : tcpv6 typ = tcp

let direct_tcp (type v)
    ?(clock=default_clock) ?(random=default_random) ?(time=default_time) (ip : v ip impl) =
  let module TCP_direct = TCP_direct (struct type t = v end) in
  let t = { TCP_direct.clock; random; time; ip } in
  impl tcp t (module TCP_direct)

let socket_tcpv4 ip =
  impl tcpv4 ip (module TCPV4_socket)

module STACKV4_direct = struct

  type t = {
    clock  : clock impl;
    time   : time impl;
    console: console impl;
    network: network impl;
    random : random impl;
    config : [`DHCP | `IPV4 of ipv4_config];
  }

  let name t =
    let key = "stackv4"
              ^ Impl.name t.clock
              ^ Impl.name t.time
              ^ Impl.name t.console
              ^ Impl.name t.network
              ^ Impl.name t.random
              ^ match t.config with
              | `DHCP   -> "dhcp"
              | `IPV4 i -> meta_ipv4_config i in
    Name.of_key key ~base:"stackv4"

  let module_name t =
    String.capitalize (name t)

  let packages t =
    "tcpip"
    :: Impl.packages t.clock
    @  Impl.packages t.time
    @  Impl.packages t.console
    @  Impl.packages t.network
    @  Impl.packages t.random

  let libraries t =
    "tcpip.stack-direct"
    :: "mirage.runtime"
    :: Impl.libraries t.clock
    @  Impl.libraries t.time
    @  Impl.libraries t.console
    @  Impl.libraries t.network
    @  Impl.libraries t.random

  let configure t =
    let name = name t in
    Impl.configure t.clock;
    Impl.configure t.time;
    Impl.configure t.console;
    Impl.configure t.network;
    Impl.configure t.random;
    let ethif_name = module_name t ^ "_E" in
    let arpv4_name = module_name t ^ "_A" in
    let ipv4_name = module_name t ^ "_I" in
    let udpv4_name = module_name t ^ "_U" in
    let tcpv4_name = module_name t ^ "_T" in
    append_main "module %s = Ethif.Make(%s)" ethif_name (Impl.module_name t.network);
    append_main "module %s = Arpv4.Make(%s)(%s)(%s)" arpv4_name ethif_name
      (Impl.module_name t.clock) (Impl.module_name t.time);
    append_main "module %s = Ipv4.Make(%s)(%s)" ipv4_name ethif_name arpv4_name;
    append_main "module %s = Udp.Make (%s)" udpv4_name ipv4_name;
    append_main "module %s = Tcp.Flow.Make(%s)(%s)(%s)(%s)"
      tcpv4_name ipv4_name (Impl.module_name t.time)
      (Impl.module_name t.clock) (Impl.module_name t.random);
    append_main "module %s = Tcpip_stack_direct.Make(%s)(%s)(%s)(%s)(%s)(%s)(%s)(%s)(%s)"
      (module_name t)
      (Impl.module_name t.console)
      (Impl.module_name t.time)
      (Impl.module_name t.random)
      (Impl.module_name t.network)
      ethif_name arpv4_name ipv4_name udpv4_name tcpv4_name;
    newline_main ();
    append_main "let %s () =" name;
    append_main "  %s () >>= function" (Impl.name t.console);
    append_main "  | `Error _    -> %s"
      (driver_initialisation_error (Impl.name t.console));
    append_main "  | `Ok console ->";
    append_main "  %s () >>= function" (Impl.name t.network);
    append_main "  | `Error e      ->";
    let net_init_error_msg_fn = "Mirage_runtime.string_of_network_init_error" in
    append_main "    fail (Failure (%s %S e))"
      net_init_error_msg_fn (Impl.name t.network);
    append_main "  | `Ok interface ->";
    append_main "  let config = {";
    append_main "    V1_LWT.name = %S;" name;
    append_main "    console; interface;";
    begin match t.config with
      | `DHCP   -> append_main "    mode = `DHCP;"
      | `IPV4 i -> append_main "    mode = `IPv4 %s;" (meta_ipv4_config i);
    end;
    append_main "  } in";
    append_main "  %s.connect interface >>= function" ethif_name;
    append_main "  | `Error _ -> %s" (driver_initialisation_error ethif_name);
    append_main "  | `Ok ethif ->";
    append_main "  %s.connect ethif >>= function" arpv4_name;
    append_main "  | `Error _ -> %s" (driver_initialisation_error arpv4_name);
    append_main "  | `Ok arpv4 ->";
    append_main "  %s.connect ethif arpv4 >>= function" ipv4_name;
    append_main "  | `Error _ -> %s" (driver_initialisation_error ipv4_name);
    append_main "  | `Ok ipv4 ->";
    append_main "  %s.connect ipv4 >>= function" udpv4_name;
    append_main "  | `Error _ -> %s" (driver_initialisation_error udpv4_name);
    append_main "  | `Ok udpv4 ->";
    append_main "  %s.connect ipv4 >>= function" tcpv4_name;
    append_main "  | `Error _ -> %s" (driver_initialisation_error tcpv4_name);
    append_main "  | `Ok tcpv4 ->";
    append_main "  %s.connect config ethif arpv4 ipv4 udpv4 tcpv4" (module_name t);
    newline_main ()

  let clean t =
    Impl.clean t.clock;
    Impl.clean t.time;
    Impl.clean t.console;
    Impl.clean t.network;
    Impl.clean t.random

  let update_path t root =
    { t with
      clock   = Impl.update_path t.clock root;
      time    = Impl.update_path t.time root;
      console = Impl.update_path t.console root;
      network = Impl.update_path t.network root;
      random  = Impl.update_path t.random root;
    }

end

module STACKV4_socket = struct

  type t = {
    console: console impl;
    ipv4s  : Ipaddr.V4.t list;
  }

  let meta_ips ips =
    String.concat "; "
      (List.map (fun x ->
           Printf.sprintf "Ipaddr.V4.of_string_exn %S" (Ipaddr.V4.to_string x)
         ) ips)

  let name t =
    let key = "stackv4" ^ Impl.name t.console ^ meta_ips t.ipv4s in
    Name.of_key key ~base:"stackv4"

  let module_name t =
    String.capitalize (name t)

  let packages t =
    "tcpip" :: Impl.packages t.console

  let libraries t =
    "tcpip.stack-socket" :: Impl.libraries t.console

  let configure t =
    let name = name t in
    Impl.configure t.console;
    append_main "module %s = Tcpip_stack_socket.Make(%s)"
      (module_name t) (Impl.module_name t.console);
    newline_main ();
    append_main "let %s () =" name;
    append_main "  %s () >>= function" (Impl.name t.console);
    append_main "  | `Error _    -> %s"
      (driver_initialisation_error (Impl.name t.console));
    append_main "  | `Ok console ->";
    append_main "  let config = {";
    append_main "    V1_LWT.name = %S;" name;
    append_main "    console; interface = [%s];" (meta_ips t.ipv4s);
    append_main "    mode = ();";
    append_main "  } in";
    append_main "  Udpv4_socket.connect None >>= function";
    append_main "  | `Error _ -> %s" (driver_initialisation_error "Udpv4_socket");
    append_main "  | `Ok udpv4 ->";
    append_main "  Tcpv4_socket.connect None >>= function";
    append_main "  | `Error _ -> %s" (driver_initialisation_error "Tcpv4_socket");
    append_main "  | `Ok tcpv4 ->";
    append_main "  %s.connect config udpv4 tcpv4" (module_name t);
    newline_main ()

  let clean t =
    Impl.clean t.console

  let update_path t root =
    { t with console = Impl.update_path t.console root }

end

type stackv4 = STACKV4

let stackv4 = Type STACKV4

let direct_stackv4_with_dhcp
    ?(clock=default_clock)
    ?(random=default_random)
    ?(time=default_time)
    console network =
  let t = {
    STACKV4_direct.console; network; time; clock; random;
    config = `DHCP } in
  impl stackv4 t (module STACKV4_direct)

let direct_stackv4_with_default_ipv4
    ?(clock=default_clock)
    ?(random=default_random)
    ?(time=default_time)
    console network =
  let t = {
    STACKV4_direct.console; network; clock; time; random;
    config = `IPV4 default_ipv4_conf;
  } in
  impl stackv4 t (module STACKV4_direct)

let direct_stackv4_with_static_ipv4
    ?(clock=default_clock)
    ?(random=default_random)
    ?(time=default_time)
    console network ipv4 =
  let t = {
    STACKV4_direct.console; network; clock; time; random;
    config = `IPV4 ipv4;
  } in
  impl stackv4 t (module STACKV4_direct)

let socket_stackv4 console ipv4s =
  impl stackv4 { STACKV4_socket.console; ipv4s } (module STACKV4_socket)

module Conduit = struct

  type t = {
    stackv4: stackv4 impl option;
    tls    : bool;
  }

  let name t =
    let key =
      "conduit" ^
      (match t.stackv4 with None -> "" | Some t -> Impl.name t) ^
      (match t.tls with false -> "" | true -> "tls")
    in
    Name.of_key key ~base:"conduit"

  let module_name t = String.capitalize (name t)

  let packages t =
    "mirage-conduit" :: (
      match t.stackv4 with
      | None   -> []
      | Some s -> Impl.packages s
    ) @ (
      match t.tls with
      | false -> []
      | true  -> ["tls"]
    )

  let libraries t =
    "conduit.mirage" :: (
      match t.stackv4 with
      | None   -> []
      | Some s -> Impl.libraries s
    ) @ (
      match t.tls with
      | false -> []
      | true  -> ["tls"]
    )

  let configure t =
    begin match t.stackv4 with
      | None   -> ()
      | Some s -> Impl.configure s
    end;
    append_main "module %s = Conduit_mirage" (module_name t);
    newline_main ();
    append_main "let %s () = Lwt.return Conduit_mirage.empty" (name t);
    begin match t.stackv4 with
      | None   -> ()
      | Some s ->
        append_main "let %s () =" (name t);
        append_main "  %s () >>= fun t ->" (name t);
        append_main "  %s () >>= function" (Impl.name s);
        append_main "  | `Error e -> %s" (driver_initialisation_error "stack");
        append_main "  | `Ok s    ->";
        append_main "    let tcp = Conduit_mirage.stackv4 (module %s) in"
          (Impl.module_name s);
        append_main "    Conduit_mirage.with_tcp t tcp s"
    end;
    begin match t.tls with
      | false -> ()
      | true  ->
        append_main "let %s () =" (name t);
        append_main "  %s () >>= fun t ->" (name t);
        append_main "  Conduit_mirage.with_tls t"
    end;
    append_main "let %s () = %s () >>= fun t -> Lwt.return (`Ok t)"
      (name t) (name t);
    newline_main ()

  let clean t =
    match t.stackv4 with
    | None   -> ()
    | Some s -> Impl.clean s

  let update_path t root =
    match t.stackv4 with
    | None   -> t
    | Some s -> { t with stackv4 = Some (Impl.update_path s root) }

end

type conduit = Conduit

let conduit = Type Conduit

let conduit_direct ?(tls=false) s =
  impl conduit { Conduit.stackv4 = Some s; tls } (module Conduit)

module Resolver_unix = struct
  type t = unit

  let name t =
    let key = "resolver_unix" in
    Name.of_key key ~base:"resolver"

  let module_name t =
    String.capitalize (name t)

  let packages t =
    match !mode with
    |`Unix | `MacOSX -> [ "mirage-conduit" ]
    |`Xen -> failwith "Resolver_unix not supported on Xen"

  let libraries t =
    [ "conduit.mirage"; "conduit.lwt-unix" ]

  let configure t =
    append_main "module %s = Resolver_lwt" (module_name t);
    append_main "let %s () =" (name t);
    append_main "  return (`Ok Resolver_lwt_unix.system)";
    newline_main ()

  let clean t = ()

  let update_path t root = t

end

module Resolver_direct = struct
  type t =
    [ `DNS of stackv4 impl * Ipaddr.V4.t option * int option ]

  let name t =
    let key = "resolver" ^ match t with
     | `DNS (s,_,_) -> Impl.name s in
    Name.of_key key ~base:"resolver"

  let module_name_core t =
    String.capitalize (name t)

  let module_name t =
    (module_name_core t) ^ "_res"

  let packages t =
    [ "dns"; "tcpip" ] @
    match t with
    | `DNS (s,_,_) -> Impl.packages s

  let libraries t =
    [ "dns.mirage" ] @
    match t with
    | `DNS (s,_,_) -> Impl.libraries s

  let configure t =
    begin match t with
      | `DNS (s,_,_) ->
        Impl.configure s;
        append_main "module %s = Resolver_lwt" (module_name t);
        append_main "module %s_dns = Dns_resolver_mirage.Make(OS.Time)(%s)"
          (module_name_core t) (Impl.module_name s);
        append_main "module %s = Resolver_mirage.Make(%s_dns)"
          (module_name_core t) (module_name_core t);
    end;
    newline_main ();
    append_main "let %s () =" (name t);
    let subname = match t with
      | `DNS (s,_,_) -> Impl.name s in
    append_main "  %s () >>= function" subname;
    append_main "  | `Error _  -> %s" (driver_initialisation_error subname);
    append_main "  | `Ok %s ->" subname;
    let res_ns = match t with
     | `DNS (_,None,_) -> "None"
     | `DNS (_,Some ns,_) ->
         Printf.sprintf "Ipaddr.V4.of_string %S" (Ipaddr.V4.to_string ns) in
    append_main "  let ns = %s in" res_ns;
    let res_ns_port = match t with
     | `DNS (_,_,None) -> "None"
     | `DNS (_,_,Some ns_port) -> Printf.sprintf "Some %d" ns_port in
    append_main "  let ns_port = %s in" res_ns_port;
    append_main "  let res = %s.init ?ns ?ns_port ~stack:%s () in" (module_name_core t) subname;
    append_main "  return (`Ok res)";
    newline_main ()

  let clean = function
    | `DNS (s,_,_) -> Impl.clean s

  let update_path t root =
    match t with
    | `DNS (s,a,b) -> `DNS (Impl.update_path s root, a, b)

end

type resolver = Resolver

let resolver = Type Resolver

let resolver_dns ?ns ?ns_port stack =
  impl resolver (`DNS (stack, ns, ns_port)) (module Resolver_direct)

let resolver_unix_system =
  impl resolver () (module Resolver_unix)

module HTTP = struct

  type t = { conduit: conduit impl }

  let name { conduit } =
    let key = "http" ^ Impl.name conduit in
    Name.of_key key ~base:"http"

  let module_name t =
    String.capitalize (name t)

  let packages { conduit }=
    [ "mirage-http" ] @
    Impl.packages conduit

  let libraries { conduit } =
    [ "mirage-http" ] @
    Impl.libraries conduit

  let configure t =
    Impl.configure t.conduit;
    append_main "module %s = Cohttp_mirage.Server(%s.Flow)"
      (module_name t) (Impl.module_name t.conduit);
    newline_main ();
    append_main "let %s () =" (name t);
    append_main "  %s () >>= function" (Impl.name t.conduit);
    append_main "  | `Error _ -> assert false";
    append_main "  | `Ok t ->";
    append_main "    let listen s f =";
    append_main "      %s.listen t s (%s.listen f)"
      (Impl.module_name t.conduit) (module_name t);
    append_main "    in";
    append_main "    return (`Ok listen)";
    newline_main ()

  let clean { conduit } = Impl.clean conduit

  let update_path { conduit } root =
    { conduit =  Impl.update_path conduit root }

end

type http = HTTP

let http = Type HTTP

let http_server conduit = impl http { HTTP.conduit } (module HTTP)

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

module Tracing = struct
  type t = {
    size : int;
  }

  let unix_trace_file = "trace.ctf"

  let packages _ = StringSet.singleton "mirage-profile"

  let libraries _ =
    match !mode with
    | `Unix | `MacOSX -> StringSet.singleton "mirage-profile.unix"
    | `Xen  -> StringSet.singleton "mirage-profile.xen"

  let configure t =
    if Sys.command "ocamlfind query lwt.tracing 2>/dev/null" <> 0 then (
      flush stdout;
      error "lwt.tracing module not found. Hint:\n\
             opam pin add lwt 'https://github.com/mirage/lwt.git#tracing'"
    );

    append_main "let () = ";
    begin match !mode with
    | `Unix | `MacOSX ->
        append_main "  let buffer = MProf_unix.mmap_buffer ~size:%d %S in" t.size unix_trace_file;
        append_main "  let trace_config = MProf.Trace.Control.make buffer MProf_unix.timestamper in";
        append_main "  MProf.Trace.Control.start trace_config";
    | `Xen  ->
        append_main "  let trace_pages = MProf_xen.make_shared_buffer ~size:%d in" t.size;
        append_main "  let buffer = trace_pages |> Io_page.to_cstruct |> Cstruct.to_bigarray in";
        append_main "  let trace_config = MProf.Trace.Control.make buffer MProf_xen.timestamper in";
        append_main "  MProf.Trace.Control.start trace_config;";
        append_main "  MProf_xen.share_with (module Gnt.Gntshr) (module OS.Xs) ~domid:0 trace_pages";
        append_main "  |> OS.Main.run";
    end;
    newline_main ()
end

type tracing = Tracing.t

let mprof_trace ~size () =
  { Tracing.size }

module Nocrypto_entropy = struct

  (* XXX
   * Nocrypto needs `mirage-entropy-xen` if compiled for xen.
   * This is currently handled by always installing this library, regardless of
   * usage of Nocrypto.
   * As `libraries` is run after opam setup, it will correctly detect Nocrypto
   * usage and inject appropriate deps for linkage, if needed.
   * The `packages` function, unconditional installation of
   * `mirage-entropy-xen`, and this comment, should be cleared once we have
   * conditional dependencies support in opam.
   * See https://github.com/mirage/mirage/pull/394 for discussion.
   *)

  module SS = StringSet

  let remembering r f =
    match !r with
    | Some x -> x
    | None   -> let x = f () in r := Some x ; x

  let linkage_ = ref None

  let linkage () =
    match !linkage_ with
    | None   -> failwith "Nocrypto_entropy: `linkage` queried before `libraries`"
    | Some x -> x

  let packages () =
    match !mode with
    | `Xen -> SS.singleton "mirage-entropy-xen"
    | _    -> SS.empty

  let libraries libs =
    remembering linkage_ @@ fun () ->
      let needed =
        OCamlfind.query ~recursive:true (SS.elements libs)
          |> List.exists ((=) "nocrypto") in
      match !mode with
      | `Xen              when needed -> SS.singleton "nocrypto.xen"
      | (`Unix | `MacOSX) when needed -> SS.singleton "nocrypto.lwt"
      | _                             -> SS.empty

  let configure () =
    SS.elements (linkage ()) |> List.iter (fun lib ->
      if not (OCamlfind.installed lib) then
        error "%s module not found. Hint: reinstall nocrypto." lib
      )

  let preamble () =
    match (!mode, not (SS.is_empty @@ linkage ())) with
    | (`Xen             , true) -> "Nocrypto_entropy_xen.initialize ()"
    | ((`Unix | `MacOSX), true) -> "Nocrypto_entropy_lwt.initialize ()"
    | _                         -> "return_unit"
end

type t = {
  name: string;
  root: string;
  jobs: job impl list;
  tracing: tracing option;
}

let t = ref None

let config_file = ref None

let reset () =
  config_file := None;
  t := None

let set_config_file f =
  config_file := Some f

let get_config_file () =
  match !config_file with
  | None -> Sys.getcwd () / "config.ml"
  | Some f -> f

let update_path t root =
  { t with jobs = List.map (fun j -> Impl.update_path j root) t.jobs }

let register ?tracing name jobs =
  let root = match !config_file with
    | None   -> failwith "no config file"
    | Some f -> Filename.dirname f in
  t := Some { name; jobs; root; tracing }

let registered () =
  match !t with
  | None   -> { name = "empty"; jobs = []; root = Sys.getcwd (); tracing = None }
  | Some t -> t

let ps = ref StringSet.empty

let add_to_opam_packages p =
  ps := StringSet.union (StringSet.of_list p) !ps

let packages t =
  let m = match !mode with
    | `Unix | `MacOSX -> "mirage-unix"
    | `Xen  -> "mirage-xen" in
  let ps = StringSet.add m !ps in
  let ps = match t.tracing with
    | None -> ps
    | Some tracing -> StringSet.union (Tracing.packages tracing) ps in
  let ps = List.fold_left (fun set j ->
      let ps = StringSet.of_list (Impl.packages j) in
      StringSet.union ps set
    ) ps t.jobs in
  let ps = StringSet.union ps (Nocrypto_entropy.packages ()) in
  StringSet.elements ps

let ls = ref StringSet.empty

let add_to_ocamlfind_libraries l =
  ls := StringSet.union !ls (StringSet.of_list l)

let libraries t =
  let m = match !mode with
    | `Unix | `MacOSX -> "mirage-types.lwt"
    | `Xen  -> "mirage-types.lwt" in
  let ls = StringSet.add m !ls in
  let ls = match t.tracing with
    | None -> ls
    | Some tracing -> StringSet.union (Tracing.libraries tracing) ls in
  let ls = List.fold_left (fun set j ->
      let ls = StringSet.of_list (Impl.libraries j) in
      StringSet.union ls set
    ) ls t.jobs in
  let ls = StringSet.union ls (Nocrypto_entropy.libraries ls) in
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

let configure_main_libvirt_xml t =
  let file = t.root / t.name ^ "_libvirt.xml" in
  let oc = open_out file in
  append oc "<!-- %s -->" generated_by_mirage;
  append oc "<domain type='xen'>";
  append oc "    <name>%s</name>" t.name;
  append oc "    <memory unit='KiB'>262144</memory>";
  append oc "    <currentMemory unit='KiB'>262144</currentMemory>";
  append oc "    <vcpu placement='static'>1</vcpu>";
  append oc "    <os>";
  append oc "        <type arch='armv7l' machine='xenpv'>linux</type>";
  append oc "        <kernel>%s/mir-%s.xen</kernel>" t.root t.name;
  append oc "        <cmdline> </cmdline>"; (* the libxl driver currently needs an empty cmdline to be able to start the domain on arm - due to this? http://lists.xen.org/archives/html/xen-devel/2014-02/msg02375.html *)
  append oc "    </os>";
  append oc "    <clock offset='utc' adjustment='reset'/>";
  append oc "    <on_crash>preserve</on_crash>";
  append oc "    <!-- ";
  append oc "    You must define network and block interfaces manually.";
  append oc "    See http://libvirt.org/drvxen.html for information about converting .xl-files to libvirt xml automatically.";
  append oc "    -->";
  append oc "    <devices>";
  append oc "        <!--";
  append oc "        The disk configuration is defined here:";
  append oc "        http://libvirt.org/formatstorage.html.";
  append oc "        An example would look like:";
  append oc"         <disk type='block' device='disk'>";
  append oc "            <driver name='phy'/>";
  append oc "            <source dev='/dev/loop0'/>";
  append oc "            <target dev='' bus='xen'/>";
  append oc "        </disk>";
  append oc "        -->";
  append oc "        <!-- ";
  append oc "        The network configuration is defined here:";
  append oc "        http://libvirt.org/formatnetwork.html";
  append oc "        An example would look like:";
  append oc "        <interface type='bridge'>";
  append oc "            <mac address='c0:ff:ee:c0:ff:ee'/>";
  append oc "            <source bridge='br0'/>";
  append oc "        </interface>";
  append oc "        -->";
  append oc "        <console type='pty'>";
  append oc "            <target type='xen' port='0'/>";
  append oc "        </console>";
  append oc "    </devices>";
  append oc "</domain>";
  close_out oc

let clean_main_libvirt_xml t =
  remove (t.root / t.name ^ "_libvirt.xml")

let configure_main_xl t =
  let file = t.root / t.name ^ ".xl" in
  let oc = open_out file in
  append oc "# %s" generated_by_mirage;
  newline oc;
  append oc "name = '%s'" t.name;
  append oc "kernel = '%s/mir-%s.xen'" t.root t.name;
  append oc "builder = 'linux'";
  append oc "memory = 256";
  append oc "on_crash = 'preserve'";
  newline oc;
  let blocks = List.map (fun b ->
    (* We need the Linux version of the block number (this is a strange historical
       artifact) Taken from https://github.com/mirage/mirage-block-xen/blob/a64d152586c7ebc1d23c5adaa4ddd440b45a3a83/lib/device_number.ml#L128 *)
      let rec string_of_int26 x =
        let (/) = Pervasives.(/) in
        let high, low = x / 26 - 1, x mod 26 + 1 in
        let high' = if high = -1 then "" else string_of_int26 high in
        let low' = String.make 1 (char_of_int (low + (int_of_char 'a') - 1)) in
        high' ^ low' in
    let vdev = Printf.sprintf "xvd%s" (string_of_int26 b.Block.number) in
    let path = Filename.concat t.root b.Block.filename in
    Printf.sprintf "'format=raw, vdev=%s, access=rw, target=%s'" vdev path
  ) (Hashtbl.fold (fun _ v acc -> v :: acc) all_blocks []) in
  append oc "disk = [ %s ]" (String.concat ", " blocks);
  newline oc;
  append oc "# The network configuration is defined here:";
  append oc "# http://xenbits.xen.org/docs/4.3-testing/misc/xl-network-configuration.html";
  append oc "# An example would look like:";
  append oc "# vif = [ 'mac=c0:ff:ee:c0:ff:ee,bridge=br0' ]";
  close_out oc

let clean_main_xl t =
  remove (t.root / t.name ^ ".xl")

let configure_main_xe t =
  let file = t.root / t.name ^ ".xe" in
  let oc = open_out file in
  append oc "#!/bin/sh";
  append oc "# %s" generated_by_mirage;
  newline oc;
  append oc "set -e";
  newline oc;
  append oc "# Dependency: xe";
  append oc "command -v xe >/dev/null 2>&1 || { echo >&2 \"I require xe but it's not installed.  Aborting.\"; exit 1; }";
  append oc "# Dependency: xe-unikernel-upload";
  append oc "command -v xe-unikernel-upload >/dev/null 2>&1 || { echo >&2 \"I require xe-unikernel-upload but it's not installed.  Aborting.\"; exit 1; }";
  append oc "# Dependency: a $HOME/.xe";
  append oc "if [ ! -e $HOME/.xe ]; then";
  append oc "  echo Please create a config file for xe in $HOME/.xe which contains:";
  append oc "  echo server='<IP or DNS name of the host running xapi>'";
  append oc "  echo username=root";
  append oc "  echo password=password";
  append oc "  exit 1";
  append oc "fi";
  newline oc;
  append oc "echo Uploading VDI containing unikernel";
  append oc "VDI=$(xe-unikernel-upload --path %s/mir-%s.xen)" t.root t.name;
  append oc "echo VDI=$VDI";
  append oc "echo Creating VM metadata";
  append oc "VM=$(xe vm-create name-label=%s)" t.name;
  append oc "echo VM=$VM";
  append oc "xe vm-param-set uuid=$VM PV-bootloader=pygrub";
  append oc "echo Adding network interface connected to xenbr0";
  append oc "ETH0=$(xe network-list bridge=xenbr0 params=uuid --minimal)";
  append oc "VIF=$(xe vif-create vm-uuid=$VM network-uuid=$ETH0 device=0)";
  append oc "echo Atting block device and making it bootable";
  append oc "VBD=$(xe vbd-create vm-uuid=$VM vdi-uuid=$VDI device=0)";
  append oc "xe vbd-param-set uuid=$VBD bootable=true";
  append oc "xe vbd-param-set uuid=$VBD other-config:owner=true";
  List.iter (fun b ->
    append oc "echo Uploading data VDI %s" b.Block.filename;
    append oc "echo VDI=$VDI";
    append oc "SIZE=$(stat --format '%%s' %s/%s)" t.root b.Block.filename;
    append oc "POOL=$(xe pool-list params=uuid --minimal)";
    append oc "SR=$(xe pool-list uuid=$POOL params=default-SR --minimal)";
    append oc "VDI=$(xe vdi-create type=user name-label='%s' virtual-size=$SIZE sr-uuid=$SR)" b.Block.filename;
    append oc "xe vdi-import uuid=$VDI filename=%s/%s" t.root b.Block.filename;
    append oc "VBD=$(xe vbd-create vm-uuid=$VM vdi-uuid=$VDI device=%d)" b.Block.number;
    append oc "xe vbd-param-set uuid=$VBD other-config:owner=true";
  ) (Hashtbl.fold (fun _ v acc -> v :: acc) all_blocks []);
  append oc "echo Starting VM";
  append oc "xe vm-start vm=%s" t.name;
  close_out oc;
  Unix.chmod file 0o755

let clean_main_xe t =
  remove (t.root / t.name ^ ".xe")

(* Implement something similar to the @name/file extended names of findlib. *)
let rec expand_name ~lib param =
  match cut_at param '@' with
  | None -> param
  | Some (prefix, name) -> match cut_at name '/' with
    | None              -> prefix ^ lib / name
    | Some (name, rest) -> prefix ^ lib / name / expand_name ~lib rest

(* Get the linker flags for any extra C objects we depend on.
 * This is needed when building a Xen image as we do the link manually. *)
let get_extra_ld_flags ~filter pkgs =
  let lib = strip (read_command "opam config var lib") in
  let output = read_command
    "ocamlfind query -r -format '%%d\t%%(xen_linkopts)' -predicates native %s"
    (String.concat " " pkgs) in
  split output '\n'
  |> List.fold_left (fun acc line ->
    match cut_at line '\t' with
    | None -> acc
    | Some (dir, ldflags) ->
      let ldflags = split ldflags ' ' in
      let ldflags = List.map (expand_name ~lib) ldflags in
      let ldflags = String.concat " " ldflags in
      Printf.sprintf "-L%s %s" dir ldflags :: acc
  ) []

let configure_makefile t =
  let file = t.root / "Makefile" in
  let pkgs = "lwt.syntax" :: libraries t in
  let libraries_str =
    match pkgs with
    | [] -> ""
    | ls -> "-pkgs " ^ String.concat "," ls in
  let packages = String.concat " " (packages t) in
  let oc = open_out file in
  append oc "# %s" generated_by_mirage;
  newline oc;
  append oc "LIBS   = %s" libraries_str;
  append oc "PKGS   = %s" packages;
  begin match !mode with
    | `Xen  ->
      append oc "SYNTAX = -tags \"syntax(camlp4o),annot,bin_annot,strict_sequence,principal\"\n";
      append oc "SYNTAX += -tag-line \"<static*.*>: -syntax(camlp4o)\"\n";
      append oc "FLAGS  = -cflag -g -lflags -g,-linkpkg,-dontlink,unix\n";
      append oc "XENLIB = $(shell ocamlfind query mirage-xen)\n"
    | `Unix ->
      append oc "SYNTAX = -tags \"syntax(camlp4o),annot,bin_annot,strict_sequence,principal\"\n";
      append oc "SYNTAX += -tag-line \"<static*.*>: -syntax(camlp4o)\"\n";
      append oc "FLAGS  = -cflag -g -lflags -g,-linkpkg\n"
    | `MacOSX ->
      append oc "SYNTAX = -tags \"syntax(camlp4o),annot,bin_annot,strict_sequence,principal,thread\"\n";
      append oc "SYNTAX += -tag-line \"<static*.*>: -syntax(camlp4o)\"\n";
      append oc "FLAGS  = -cflag -g -lflags -g,-linkpkg\n"
  end;
  append oc "BUILD  = ocamlbuild -use-ocamlfind $(LIBS) $(SYNTAX) $(FLAGS)\n\
             OPAM   = opam\n\n\
             export PKG_CONFIG_PATH=$(shell opam config var prefix)/lib/pkgconfig\n\n\
             export OPAMVERBOSE=1\n\
             export OPAMYES=1";
  newline oc;
  append oc ".PHONY: all depend clean build main.native\n\
             all:: build\n\
             \n\
             depend::\n\
             \t$(OPAM) install $(PKGS) --verbose\n\
             \n\
             main.native:\n\
             \t$(BUILD) main.native\n\
             \n\
             main.native.o:\n\
             \t$(BUILD) main.native.o";
  newline oc;

  (* On ARM, we must convert the ELF image to an ARM boot executable zImage,
   * while on x86 we leave it as it is. *)
  let generate_image =
    let need_zImage =
      match uname_m () with
      | Some machine -> String.length machine > 2 && String.sub machine 0 3 = "arm"
      | None -> failwith "uname -m failed; can't determine target machine type!" in
    if need_zImage then (
      Printf.sprintf "\t  -o mir-%s.elf\n\
                      \tobjcopy -O binary mir-%s.elf mir-%s.xen"
                      t.name t.name t.name
    ) else (
      Printf.sprintf "\t  -o mir-%s.xen" t.name
    ) in

  begin match !mode with
    | `Xen ->
      let filter = function
        | "unix" | "bigarray" |"shared_memory_ring_stubs" -> false    (* Provided by mirage-xen instead. *)
        | _ -> true in
      let extra_c_archives =
        get_extra_ld_flags ~filter pkgs
        |> String.concat " \\\n\t  " in

      append oc "build:: main.native.o";
      let pkg_config_deps = "mirage-xen" in
      append oc "\tpkg-config --print-errors --exists %s" pkg_config_deps;
      append oc "\tld -d -static -nostdlib \\\n\
                 \t  _build/main.native.o \\\n\
                 \t  %s \\\n\
                 \t  $$(pkg-config --static --libs %s) \\\n\
                 \t  $(shell gcc -print-libgcc-file-name) \\\n\
                 %s"
        extra_c_archives pkg_config_deps generate_image;
    | `Unix | `MacOSX ->
      append oc "build: main.native";
      append oc "\tln -nfs _build/main.native mir-%s" t.name;
  end;
  newline oc;
  append oc "clean::\n\
             \tocamlbuild -clean";
  newline oc;
  append oc "-include Makefile.user";
  close_out oc

let clean_makefile t =
  remove (t.root / "Makefile")

let no_opam_version_check_ = ref false
let no_opam_version_check b = no_opam_version_check_ := b

let no_depext_ = ref false
let no_depext b = no_depext_ := b

let configure_opam t =
  info "Installing OPAM packages.";
  match packages t with
  | [] -> ()
  | ps ->
    if command_exists "opam" then
      if !no_opam_version_check_ then ()
      else (
        let opam_version = read_command "opam --version" in
        let version_error () =
          error "Your version of OPAM (%s) is not recent enough. \
                 Please update to (at least) 1.2: https://opam.ocaml.org/doc/Install.html \
                 You can pass the `--no-opam-version-check` flag to force its use." opam_version
        in
        match split opam_version '.' with
        | major::minor::_ ->
          let major = try int_of_string major with Failure _ -> 0 in
          let minor = try int_of_string minor with Failure _ -> 0 in
          if (major, minor) >= (1, 2) then (
            if !no_depext_ then ()
            else (
              if command_exists "opam-depext" then
                info "opam depext is installed."
              else
                opam "install" ["depext"];
              opam ~yes:false "depext" ps;
            );
            opam "install" ps
          ) else version_error ()
        | _ -> version_error ()
      )
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

let manage_opam_packages_ = ref true
let manage_opam_packages b = manage_opam_packages_ := b

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
  begin match t.tracing with
  | None -> ()
  | Some tracing -> Tracing.configure tracing end;
  Nocrypto_entropy.configure ();
  List.iter (fun j -> Impl.configure j) t.jobs;
  List.iter configure_job t.jobs;
  let names = List.map (fun j -> Printf.sprintf "%s ()" (Impl.name j)) t.jobs in
  append_main "let () =";
  append_main "  OS.Main.run (%s >>= fun () -> join [%s])"
              (Nocrypto_entropy.preamble ())
              (String.concat "; " names)

let clean_main t =
  List.iter Impl.clean t.jobs;
  remove (t.root / "main.ml")

let configure t =
  info "%s %s" (blue_s "Using configuration:") (get_config_file ());
  info "%s %s" (blue_s "Configuring for target:") (string_of_mode !mode);
  info "%d job%s [%s]"
    (List.length t.jobs)
    (if List.length t.jobs = 1 then "" else "s")
    (String.concat ", " (List.map Impl.functor_name t.jobs));
  in_dir t.root (fun () ->
      if !manage_opam_packages_ then configure_opam t;
      configure_myocamlbuild_ml t;
      configure_makefile t;
      configure_main_xl t;
      configure_main_xe t;
      configure_main_libvirt_xml t;
      configure_main t
    )

let make () =
  match uname_s () with
  | Some ("FreeBSD" | "OpenBSD" | "NetBSD" | "DragonFly") -> "gmake"
  | _ -> "make"

let build t =
  info "Build: %s" (blue_s (get_config_file ()));
  in_dir t.root (fun () ->
      command "%s build" (make ())
    )

let clean t =
  info "Clean: %s" (blue_s (get_config_file ()));
  in_dir t.root (fun () ->
      if !manage_opam_packages_ then clean_opam t;
      clean_myocamlbuild_ml t;
      clean_makefile t;
      clean_main_xl t;
      clean_main_xe t;
      clean_main_libvirt_xml t;
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
                    Please specify one explictly on the command-line."

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
