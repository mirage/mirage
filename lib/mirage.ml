(*
 * _Co_pyright (c) 2013 Thomas Gazagnaire <thomas@gazagnaire.org>
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

open Functoria_misc
open Cmdliner

include Functoria
module Name = Name

type mode = [
  | `Unix
  | `Xen
  | `MacOSX
]

let mode_conv : mode Arg.converter = Arg.enum [ "unix", `Unix; "macosx", `MacOSX; "xen", `Xen ]

let string_of_mode md = Format.asprintf "%a" (snd mode_conv) md

let target =
  let doc = "Target platform to compile the unikernel for.  Valid values are: $(i,xen), $(i,unix), $(i,macosx)." in
  let desc = Key.Desc.create
      ~serializer:(snd mode_conv)
      ~description:"target"
      ~converter:mode_conv
  in
  let doc = Key.Doc.(create
        ~docs:"MIRAGE PARAMETERS"
        ~docv:"TARGET" ~doc ["t";"target"]
    ) in
  Key.(create_raw ~doc ~stage:`Configure ~default:`Unix "target" desc)


let get_mode =
  let x = Key.value target in
  fun () -> Key.eval x


type io_page = IO_PAGE
let io_page = typ IO_PAGE

class io_page_conf = object
  inherit dummy_conf
  method ty = io_page
  method name = "io_page"
  method module_name = "Io_page"
  method! libraries =
    match get_mode () with
    | `Xen  -> ["io-page"]
    | `Unix | `MacOSX -> ["io-page"; "io-page.unix"]
  method! packages = [ "io-page" ]
end

let default_io_page = impl (new io_page_conf)


(* module Time = struct *)

(*   (\** OS Timer. *\) *)

(*   type t = unit *)

(*   let name () = *)
(*     "time" *)

(*   let module_name () = *)
(*     "OS.Time" *)

(*   let packages () = [] *)

(*   let libraries () = [] *)

(*   let configure () = *)
(*     append_main "let time () = return (`Ok ())"; *)
(*     newline_main () *)

(*   let clean () = () *)

(*   let update_path () _ = () *)

(* end *)

(* type time = TIME *)

(* let time = Type TIME *)

(* let default_time: time impl = *)
(*   impl time () (module Time) *)

(* module Clock = struct *)

(*   (\** Clock operations. *\) *)

(*   type t = unit *)

(*   let name () = *)
(*     "clock" *)

(*   let module_name () = *)
(*     "Clock" *)

(*   let packages () = [ *)
(*     match get_mode () with *)
(*     | `Unix | `MacOSX -> "mirage-clock-unix" *)
(*     | `Xen  -> "mirage-clock-xen" *)
(*   ] *)

(*   let libraries () = packages () *)

(*   let configure () = *)
(*     append_main "let clock () = return (`Ok ())"; *)
(*     newline_main () *)

(*   let clean () = () *)

(*   let update_path () _ = () *)

(* end *)

(* type clock = CLOCK *)

(* let clock = Type CLOCK *)

(* let default_clock: clock impl = *)
(*   impl clock () (module Clock) *)

(* module Random = struct *)

(*   type t = unit *)

(*   let name () = *)
(*     "random" *)

(*   let module_name () = *)
(*     "Random" *)

(*   let packages () = [] *)

(*   let libraries () = [] *)

(*   let configure () = *)
(*     append_main "let random () = return (`Ok ())"; *)
(*     newline_main () *)

(*   let clean () = () *)

(*   let update_path () _ = () *)

(* end *)

(* type random = RANDOM *)

(* let random = Type RANDOM *)

(* let default_random: random impl = *)
(*   impl random () (module Random) *)


type console = CONSOLE
let console = typ CONSOLE

class console_conf name = object (self)
  inherit dummy_conf

  val console_name = name
  method ty = console

  method name =
    Name.of_key ("console" ^ name) ~base:"console"

  method module_name =
    match get_mode () with
    | `Unix | `MacOSX -> "Console_unix"
    | `Xen  -> "Console_xen"

  method packages =
    match get_mode () with
    | `Unix | `MacOSX -> ["mirage-console"; "mirage-unix"]
    | `Xen  -> ["mirage-console"; "xenstore"; "mirage-xen"; "xen-gnt"; "xen-evtchn"]

  method libraries =
    match get_mode () with
    | `Unix | `MacOSX -> ["mirage-console.unix"]
    | `Xen -> ["mirage-console.xen"]

  method connect modname args =
    Some (Printf.sprintf "%s.connect %S" modname console_name)

end

let custom_console str : console impl =
  impl (new console_conf str)

let default_console = custom_console "0"


(* module Crunch = struct *)

(*   type t = string *)

(*   let name t = *)
(*     Name.of_key ("static" ^ t) ~base:"static" *)

(*   let module_name t = *)
(*     String.capitalize (name t) *)

(*   let packages _ = [ *)
(*     "mirage-types"; *)
(*     "lwt"; *)
(*     "cstruct"; *)
(*     "crunch"; *)
(*   ] @ Io_page.packages () *)

(*   let libraries _ = [ *)
(*     "mirage-types"; *)
(*     "lwt"; *)
(*     "cstruct"; *)
(*   ] @ Io_page.libraries () *)

(*   let ml t = *)
(*     Printf.sprintf "%s.ml" (name t) *)

(*   let mli t = *)
(*     Printf.sprintf "%s.mli" (name t) *)

(*   let configure t = *)
(*     if not (command_exists "ocaml-crunch") then *)
(*       error "ocaml-crunch not found, stopping."; *)
(*     let file = ml t in *)
(*     if Sys.file_exists t then ( *)
(*       info "%s %s" (blue_s "Generating:") (Sys.getcwd () / file); *)
(*       command "ocaml-crunch -o %s %s" file t *)
(*     ) else *)
(*       error "The directory %s does not exist." t; *)
(*     append_main "let %s () =" (name t); *)
(*     append_main "  %s.connect ()" (module_name t); *)
(*     newline_main () *)

(*   let clean t = *)
(*     remove (ml t); *)
(*     remove (mli t) *)

(*   let update_path t root = *)
(*     if Sys.file_exists (root / t) then *)
(*       root / t *)
(*     else *)
(*       t *)

(* end *)

(* type kv_ro = KV_RO *)

(* let kv_ro = Type KV_RO *)

(* let crunch dirname = *)
(*   impl kv_ro dirname (module Crunch) *)

(* module Direct_kv_ro = struct *)

(*   include Crunch *)

(*   let module_name t = *)
(*     match get_mode () with *)
(*     | `Xen  -> Crunch.module_name t *)
(*     | `Unix | `MacOSX -> "Kvro_fs_unix" *)

(*   let packages t = *)
(*     match get_mode () with *)
(*     | `Xen  -> Crunch.packages t *)
(*     | `Unix | `MacOSX -> "mirage-fs-unix" :: Crunch.packages t *)

(*   let libraries t = *)
(*     match get_mode () with *)
(*     | `Xen  -> Crunch.libraries t *)
(*     | `Unix | `MacOSX -> "mirage-fs-unix" :: Crunch.libraries t *)

(*   let configure t = *)
(*     match get_mode () with *)
(*     | `Xen  -> Crunch.configure t *)
(*     | `Unix | `MacOSX -> *)
(*       append_main "let %s () =" (name t); *)
(*       append_main "  Kvro_fs_unix.connect %S" t *)

(* end *)

(* let direct_kv_ro dirname = *)
(*   impl kv_ro dirname (module Direct_kv_ro) *)


type block = BLOCK
let block = typ BLOCK

type block_t = {
  filename: string;
  number: int;
}

class block_conf b_ = object (self)
  inherit dummy_conf
  val b = b_
  method ty = block
  method name = "block" ^ b.filename
  method module_name = "Block"
  method! packages =
    match get_mode () with
    | `Unix | `MacOSX -> ["mirage-block-unix"]
    | `Xen  -> ["mirage-block-xen"]
  method! libraries =
    match get_mode () with
    | `Unix | `MacOSX -> ["mirage-block-unix"]
    | `Xen  -> ["mirage-block-xen.front"]


  method private connect_name =
    match get_mode () with
    | `Unix | `MacOSX -> b.filename (* open the file directly *)
    | `Xen ->
      (* We need the xenstore id *)
      (* Taken from https://github.com/mirage/mirage-block-xen/blob/a64d152586c7ebc1d23c5adaa4ddd440b45a3a83/lib/device_number.ml#L64 *)
      (if b. number < 16
       then (202 lsl 8) lor (b.number lsl 4)
       else (1 lsl 28)  lor (b.number lsl 8)) |> string_of_int

  method! connect s _ =
    Some (Printf.sprintf "%s.connect %S" s self#connect_name)

  method! update_path root =
    if Sys.file_exists (root / b.filename) then
      {< b = { b with filename = root / b.filename } >}
    else
      {< >}
end

let all_blocks = Hashtbl.create 7

let block_of_file =
  (* NB: reserve number 0 for the boot disk *)
  let next_number = ref 1 in
  fun filename ->
    let b =
      if Hashtbl.mem all_blocks filename
      then Hashtbl.find all_blocks filename
      else begin
        let number = !next_number in
        incr next_number;
        let b = { filename; number } in
        Hashtbl.add all_blocks filename b;
        b
      end in
    impl (new block_conf b)


(* module Archive = struct *)

(*   type t = { *)
(*     block  : block impl; *)
(*   } *)

(*   let name t = *)
(*     let key = "archive" ^ Impl.name t.block in *)
(*     Name.of_key key ~base:"archive" *)

(*   let module_name t = *)
(*     String.capitalize (name t) *)

(*   let packages t = *)
(*     "tar-format" *)
(*     :: Impl.packages t.block *)

(*   let libraries t = *)
(*     "tar.mirage" *)
(*     :: Impl.libraries t.block *)

(*   let configure t = *)
(*     Impl.configure t.block; *)
(*     append_main "module %s = Tar_mirage.Make_KV_RO(%s)" *)
(*       (module_name t) *)
(*       (Impl.module_name t.block); *)
(*     newline_main (); *)
(*     let name = name t in *)
(*     append_main "let %s () =" name; *)
(*     append_main "  %s () >>= function" (Impl.name t.block); *)
(*     append_main "  | `Error _ -> %s" (driver_initialisation_error name); *)
(*     append_main "  | `Ok dev  -> %s.connect dev" (module_name t); *)
(*     newline_main () *)

(*   let clean t = *)
(*     Impl.clean t.block *)

(*   let update_path t root = *)
(*     { block  = Impl.update_path t.block root; *)
(*     } *)

(* end *)

(* let archive block : kv_ro impl = *)
(*   let t = { Archive.block } in *)
(*   impl kv_ro t (module Archive) *)

(* module Archive_of_files = struct *)

(*   type t = { *)
(*     dir   : string; *)
(*   } *)

(*   let name t = *)
(*     Name.of_key *)
(*       ("archive" ^ t.dir) *)
(*       ~base:"archive" *)

(*   let module_name t = *)
(*     String.capitalize (name t) *)

(*   let block_file t = *)
(*     name t ^ ".img" *)

(*   let block t = *)
(*     block_of_file (block_file t) *)

(*   let packages t = *)
(*     Impl.packages (archive (block t)) *)

(*   let libraries t = *)
(*     Impl.libraries (archive (block t)) *)

(*   let configure t = *)
(*     let archive = archive (block t) in *)
(*     Impl.configure archive; *)
(*     if not (command_exists "tar") then *)
(*       error "tar not found, stopping."; *)
(*     let file = block_file t in *)
(*     info "%s %s" (blue_s "Generating:") (Sys.getcwd () / file); *)
(*     command "tar -C %s -cvf %s ." t.dir (block_file t); *)
(*     append_main "module %s = %s" (module_name t) (Impl.module_name archive); *)
(*     append_main "let %s = %s" (name t) (Impl.name archive); *)
(*     newline_main () *)

(*   let clean t = *)
(*     command "rm -f %s" (block_file t); *)
(*     Impl.clean (block t) *)

(*   let update_path t root = *)
(*     { dir = root / t.dir } *)

(* end *)

(* let archive_of_files: ?dir:string -> unit -> kv_ro impl = *)
(*   fun ?(dir=".") () -> *)
(*     impl kv_ro { Archive_of_files.dir } (module Archive_of_files) *)


type fs = FS
let fs = typ FS

class virtual fat_common = object

  inherit dummy_conf
  method ty = (io_page @-> block @-> fs)
  method! packages = [ "fat-filesystem" ]
  method! libraries = [ "fat-filesystem" ]

  method module_name = "Fat.Fs.Make"

  method! connect modname l = match l with
    | [ block_name ; _io_page_name ] ->
      Some (Printf.sprintf "%s.connect %S" modname block_name)
    | _ -> assert false
end

class fat_conf = object
  inherit fat_common

  method name = "fat"

end
let fat_impl = impl (new fat_conf)

let fat ?(io_page=default_io_page) block =
  fat_impl $ io_page $ block


(* (\* This would deserve to be in its own lib. *\) *)
(* let kv_ro_of_fs x: kv_ro impl = *)
(*   let dummy_fat = fat (block_of_file "xx") in *)
(*   let libraries = Impl.libraries dummy_fat in *)
(*   let packages = Impl.packages dummy_fat in *)
(*   let fn = foreign "Fat.KV_RO.Make" ~libraries ~packages (fs @-> kv_ro) in *)
(*   fn $ x *)

(* class fat_of_files_conf ?dir ?regexp () = *)
(*   let regexp = match regexp with *)
(*     | None   -> "*" *)
(*     | Some r -> r *)
(*   in object (self) *)

(*     inherit fat_common *)

(*     val t = { dir ; regexp } *)
(*     method t = t *)

(*     method name = *)
(*       "fat" ^ (match t.dir with None -> "." | Some d -> d) ^ ":" ^ t.regexp *)

(*     method private block_file = self#name ^ ".img" *)

(*     method! configure = *)
(*       let file = Printf.sprintf "make-%s-image.sh" self#name in *)
(*       let oc = open_out file in *)
(*       let fmt = Format.formatter_of_out_channel oc in *)
(*       Codegen.append fmt "#!/bin/sh"; *)
(*       Codegen.append fmt ""; *)
(*       Codegen.append fmt "echo This uses the 'fat' command-line tool to build a simple FAT"; *)
(*       Codegen.append fmt "echo filesystem image."; *)
(*       Codegen.append fmt ""; *)
(*       Codegen.append fmt "FAT=$(which fat)"; *)
(*       Codegen.append fmt "if [ ! -x \"${FAT}\" ]; then"; *)
(*       Codegen.append fmt "  echo I couldn\\'t find the 'fat' command-line tool."; *)
(*       Codegen.append fmt "  echo Try running 'opam install fat-filesystem'"; *)
(*       Codegen.append fmt "  exit 1"; *)
(*       Codegen.append fmt "fi"; *)
(*       Codegen.append fmt ""; *)
(*       Codegen.append fmt "IMG=$(pwd)/%s" self#block_file; *)
(*       Codegen.append fmt "rm -f ${IMG}"; *)
(*       (match t.dir with None -> () | Some d -> Codegen.append fmt "cd %s/" d); *)
(*       Codegen.append fmt "SIZE=$(du -s . | cut -f 1)"; *)
(*       Codegen.append fmt "${FAT} create ${IMG} ${SIZE}KiB"; *)
(*       Codegen.append fmt "${FAT} add ${IMG} %s" t.regexp; *)
(*       Codegen.append fmt "echo Created '%s'" self#block_file; *)

(*       close_out oc; *)
(*       Unix.chmod file 0o755; *)
(*       command "./make-%s-image.sh" self#name *)

(*     method! clean = *)
(*       command "rm -f make-%s-image.sh %s" self#name self#block_file *)

(*     method! update_path root = *)
(*       let t = match t.dir with *)
(*         | None   -> t *)
(*         | Some d -> { t with dir = Some (root / d) } *)
(*       in {< t = t >} *)
(*   end *)

(* let fat_of_files ?dir ?regexp () = *)
(*   impl (new fat_of_files_conf ?dir ?regexp ()) *)




(* type network_config = Tap0 | Custom of string *)

(* module Network = struct *)

(*   type t = network_config *)

(*   let name t = *)
(*     "net_" ^ match t with *)
(*     | Tap0     -> "tap0" *)
(*     | Custom s -> s *)

(*   let module_name _ = *)
(*     "Netif" *)

(*   let packages t = *)
(*     match get_mode () with *)
(*     | `Unix -> ["mirage-net-unix"] *)
(*     | `MacOSX -> ["mirage-net-macosx"] *)
(*     | `Xen  -> ["mirage-net-xen"] *)

(*   let libraries t = *)
(*     packages t *)

(*   let configure t = *)
(*     append_main "let %s () =" (name t); *)
(*     append_main "  %s.connect %S" *)
(*       (module_name t) *)
(*       (match t with Tap0 -> "tap0" | Custom s -> s); *)
(*     newline_main () *)

(*   let clean _ = *)
(*     () *)

(*   let update_path t _ = *)
(*     t *)

(* end *)

(* type network = NETWORK *)

(* let network = Type NETWORK *)

(* let tap0 = *)
(*   impl network Tap0 (module Network) *)

(* let netif dev = *)
(*   impl network (Custom dev) (module Network) *)

(* module Ethif = struct *)

(*   type t = network impl *)

(*   let name t = *)
(*     Name.of_key ("ethif" ^ Impl.name t) ~base:"ethif" *)

(*   let module_name t = *)
(*     String.capitalize (name t) *)

(*   let packages t = *)
(*     Impl.packages t @ ["tcpip"] *)

(*   let libraries t = *)
(*     Impl.libraries t @ *)
(*     match get_mode () with *)
(*     | `Unix | `MacOSX -> [ "tcpip.ethif-unix" ] *)
(*     | `Xen  -> [ "tcpip.ethif" ] *)

(*   let configure t = *)
(*     let name = name t in *)
(*     Impl.configure t; *)
(*     append_main "module %s = Ethif.Make(%s)" (module_name t) (Impl.module_name t); *)
(*     newline_main (); *)
(*     append_main "let %s () =" name; *)
(*     append_main "   %s () >>= function" (Impl.name t); *)
(*     append_main "   | `Error _ -> %s" (driver_initialisation_error name); *)
(*     append_main "   | `Ok eth  -> %s.connect eth" (module_name t); *)
(*     newline_main () *)

(*   let clean t = *)
(*     Impl.clean t *)

(*   let update_path t root = *)
(*     Impl.update_path t root *)

(* end *)

(* type ethernet = ETHERNET *)

(* let ethernet = Type ETHERNET *)

(* let etif network = *)
(*   impl ethernet network (module Ethif) *)

(* module Arpv4 = struct *)
(*   type t = { *)
(*     ethernet: ethernet impl; *)
(*     clock: clock impl; *)
(*     time: time impl; *)
(*   } *)

(*   let name t = *)
(*     Name.of_key ("arpv4" ^ Impl.name t.ethernet) ~base:"arpv4" *)

(*   let module_name t = *)
(*     String.capitalize (name t) *)

(*   let packages t = *)
(*     "tcpip" :: Impl.packages t.time @ Impl.packages t.clock @ Impl.packages t.ethernet *)

(*   let libraries t = *)
(*     let arp_library = *)
(*       match get_mode () with *)
(*       | `Unix | `MacOSX -> "tcpip.arpv4-unix" *)
(*       | `Xen  -> "tcpip.arpv4" *)
(*     in *)
(*     arp_library :: *)
(*     Impl.libraries t.ethernet @ *)
(*     Impl.libraries t.clock @ *)
(*     Impl.libraries t.ethernet *)

(*   let configure t = *)
(*     let name = name t in *)
(*     let mname = module_name t in *)
(*     append_main "module %s = Arpv4.Make(%s)(%s)(%s)" mname *)
(*       (Impl.module_name t.ethernet) *)
(*       (Impl.module_name t.clock) *)
(*       (Impl.module_name t.time); *)
(*     newline_main (); *)
(*     append_main "let %s () =" name; *)
(*     append_main "   %s () >>= function" (Impl.name t.ethernet); *)
(*     append_main "   | `Error _ -> %s" (driver_initialisation_error name); *)
(*     append_main "   | `Ok eth  ->"; *)
(*     append_main "   %s.connect eth >>= function" mname; *)
(*     append_main "   | `Error _ -> %s" (driver_initialisation_error "ARP"); *)
(*     append_main "   | `Ok arp   -> arp" *)

(*   let clean t = *)
(*     Impl.clean t.ethernet *)

(*   let update_path t root = *)
(*     { t with ethernet = Impl.update_path t.ethernet root } *)

(* end *)

(* type arpv4 = Arpv4 *)
(* let arpv4 = Type Arpv4 *)

(* let arp ?(clock = default_clock) ?(time = default_time) (eth : ethernet impl) = impl arpv4 *)
(*     { Arpv4.ethernet = eth; *)
(*       clock; *)
(*       time *)
(*     } (module Arpv4) *)


(* type ('ipaddr, 'prefix) ip_config = { *)
(*   address: 'ipaddr; *)
(*   netmask: 'prefix; *)
(*   gateways: 'ipaddr list; *)
(* } *)

(* type ipv4_config = (Ipaddr.V4.t, Ipaddr.V4.t) ip_config *)

(* let meta_ipv4_config t = *)
(*   Printf.sprintf "(Ipaddr.V4.of_string_exn %S, Ipaddr.V4.of_string_exn %S, [%s])" *)
(*     (Ipaddr.V4.to_string t.address) *)
(*     (Ipaddr.V4.to_string t.netmask) *)
(*     (String.concat "; " *)
(*        (List.map (Printf.sprintf "Ipaddr.V4.of_string_exn %S") *)
(*           (List.map Ipaddr.V4.to_string t.gateways))) *)

(* module IPV4 = struct *)

(*   type t = { *)
(*     arpv4 : arpv4 impl; *)
(*     config  : ipv4_config; *)
(*   } *)
(*   (\* XXX: should the type if ipv4.id be ipv4.t ? *)
(*      N.connect ethif |> N.set_ip up *\) *)

(*   let name t = *)
(*     let key = "ipv4" ^ Impl.name t.arpv4 ^ meta_ipv4_config t.config in *)
(*     Name.of_key key ~base:"ipv4" *)

(*   let module_name t = *)
(*     String.capitalize (name t) *)

(*   let packages t = *)
(*     "tcpip" :: Impl.packages t.arpv4 *)

(*   let libraries t  = *)
(*     (match get_mode () with *)
(*      | `Unix | `MacOSX -> [ "tcpip.ipv4-unix" ] *)
(*      | `Xen  -> [ "tcpip.ipv4" ]) *)
(*     @ Impl.libraries t.arpv4 *)

(*   let configure t = *)
(*     let name = name t in *)
(*     let mname = module_name t in *)
(*     Impl.configure t.arpv4; *)
(*     append_main "module %s = Ipv4.Make(%s)" *)
(*       (module_name t) (Impl.module_name t.arpv4); *)
(*     newline_main (); *)
(*     append_main "let %s () =" name; *)
(*     append_main "   %s () >>= function" (Impl.name t.arpv4); *)
(*     append_main "   | `Error _ -> %s" (driver_initialisation_error name); *)
(*     append_main "   | `Ok arp ->"; *)
(*     append_main "   %s.connect arp >>= function" mname; *)
(*     append_main "   | `Error _ -> %s" (driver_initialisation_error "IPV4"); *)
(*     append_main "   | `Ok ip   ->"; *)
(*     append_main "   let i = Ipaddr.V4.of_string_exn in"; *)
(*     append_main "   %s.set_ip ip (i %S) >>= fun () ->" *)
(*       mname (Ipaddr.V4.to_string t.config.address); *)
(*     append_main "   %s.set_ip_netmask ip (i %S) >>= fun () ->" *)
(*       mname (Ipaddr.V4.to_string t.config.netmask); *)
(*     append_main "   %s.set_ip_gateways ip [%s] >>= fun () ->" *)
(*       mname *)
(*       (String.concat "; " *)
(*          (List.map *)
(*             (fun n -> Printf.sprintf "(i %S)" (Ipaddr.V4.to_string n)) *)
(*             t.config.gateways)); *)
(*     append_main "   return (`Ok ip)"; *)
(*     newline_main () *)

(*   let clean t = *)
(*     Impl.clean t.arpv4 *)

(*   let update_path t root = *)
(*     { t with arpv4 = Impl.update_path t.arpv4 root } *)

(* end *)

(* type ipv6_config = (Ipaddr.V6.t, Ipaddr.V6.Prefix.t list) ip_config *)

(* let meta_ipv6_config t = *)
(*   Printf.sprintf "(Ipaddr.V6.of_string_exn %S, [%s], [%s])" *)
(*     (Ipaddr.V6.to_string t.address) *)
(*     (String.concat "; " *)
(*        (List.map (Printf.sprintf "Ipaddr.V6.Prefix.of_string_exn %S") *)
(*           (List.map Ipaddr.V6.Prefix.to_string t.netmask))) *)
(*     (String.concat "; " *)
(*        (List.map (Printf.sprintf "Ipaddr.V6.of_string_exn %S") *)
(*           (List.map Ipaddr.V6.to_string t.gateways))) *)

(* module IPV6 = struct *)

(*   type t = { *)
(*     time    : time impl; *)
(*     clock   : clock impl; *)
(*     ethernet: ethernet impl; *)
(*     config  : ipv6_config; *)
(*   } *)
(*   (\* XXX: should the type if ipv4.id be ipv4.t ? *)
(*      N.connect ethif |> N.set_ip up *\) *)

(*   let name t = *)
(*     let key = "ipv6" ^ Impl.name t.time ^ Impl.name t.clock ^ Impl.name t.ethernet ^ meta_ipv6_config t.config in *)
(*     Name.of_key key ~base:"ipv6" *)

(*   let module_name t = *)
(*     String.capitalize (name t) *)

(*   let packages t = *)
(*     "tcpip" :: Impl.packages t.time @ Impl.packages t.clock @ Impl.packages t.ethernet *)

(*   let libraries t  = *)
(*     (match get_mode () with *)
(*      | `Unix | `MacOSX -> [ "tcpip.ipv6-unix" ] *)
(*      | `Xen  -> [ "tcpip.ipv6" ]) *)
(*     @ Impl.libraries t.time @ Impl.libraries t.clock @ Impl.libraries t.ethernet *)

(*   let configure t = *)
(*     let name = name t in *)
(*     let mname = module_name t in *)
(*     Impl.configure t.ethernet; *)
(*     append_main "module %s = Ipv6.Make(%s)(%s)(%s)" *)
(*       (module_name t) (Impl.module_name t.ethernet) (Impl.module_name t.time) (Impl.module_name t.clock); *)
(*     newline_main (); *)
(*     append_main "let %s () =" name; *)
(*     append_main "   %s () >>= function" (Impl.name t.ethernet); *)
(*     append_main "   | `Error _ -> %s" (driver_initialisation_error name); *)
(*     append_main "   | `Ok eth  ->"; *)
(*     append_main "   %s.connect eth >>= function" mname; *)
(*     append_main "   | `Error _ -> %s" (driver_initialisation_error name); *)
(*     append_main "   | `Ok ip   ->"; *)
(*     append_main "   let i = Ipaddr.V6.of_string_exn in"; *)
(*     append_main "   %s.set_ip ip (i %S) >>= fun () ->" *)
(*       mname (Ipaddr.V6.to_string t.config.address); *)
(*     List.iter begin fun netmask -> *)
(*       append_main "   %s.set_ip_netmask ip (i %S) >>= fun () ->" *)
(*         mname (Ipaddr.V6.Prefix.to_string netmask) *)
(*     end t.config.netmask; *)
(*     append_main "   %s.set_ip_gateways ip [%s] >>= fun () ->" *)
(*       mname *)
(*       (String.concat "; " *)
(*          (List.map *)
(*             (fun n -> Printf.sprintf "(i %S)" (Ipaddr.V6.to_string n)) *)
(*             t.config.gateways)); *)
(*     append_main "   return (`Ok ip)"; *)
(*     newline_main () *)

(*   let clean t = *)
(*     Impl.clean t.time; *)
(*     Impl.clean t.clock; *)
(*     Impl.clean t.ethernet *)

(*   let update_path t root = *)
(*     { t with *)
(*       time = Impl.update_path t.time root; *)
(*       clock = Impl.update_path t.clock root; *)
(*       ethernet = Impl.update_path t.ethernet root } *)

(* end *)

(* type v4 *)
(* type v6 *)

(* type 'a ip = IP *)

(* let ip = Type IP *)

(* type ipv4 = v4 ip *)
(* type ipv6 = v6 ip *)

(* let ipv4 : ipv4 typ = ip *)
(* let ipv6 : ipv6 typ = ip *)

(* let create_ipv4 ?(clock = default_clock) ?(time = default_time) net config = *)
(*   let etif = etif net in *)
(*   let arp = arp ~clock ~time etif in *)
(*   let t = { *)
(*     IPV4.arpv4 = arp; *)
(*     config } in *)
(*   impl ipv4 t (module IPV4) *)

(* let default_ipv4_conf = *)
(*   let i = Ipaddr.V4.of_string_exn in *)
(*   { *)
(*     address  = i "10.0.0.2"; *)
(*     netmask  = i "255.255.255.0"; *)
(*     gateways = [i "10.0.0.1"]; *)
(*   } *)

(* let default_ipv4 net = *)
(*   create_ipv4 net default_ipv4_conf *)

(* let create_ipv6 *)
(*     ?(time = default_time) *)
(*     ?(clock = default_clock) *)
(*     net config = *)
(*   let etif = etif net in *)
(*   let t = { *)
(*     IPV6.ethernet = etif; *)
(*     time; clock; *)
(*     config *)
(*   } in *)
(*   impl ipv6 t (module IPV6) *)

(* module UDP_direct (V : sig type t end) = struct *)

(*   type t = V.t ip impl *)

(*   let name t = *)
(*     Name.of_key ("udp" ^ Impl.name t) ~base:"udp" *)

(*   let module_name t = *)
(*     String.capitalize (name t) *)

(*   let packages t = *)
(*     Impl.packages t @ [ "tcpip" ] *)

(*   let libraries t = *)
(*     Impl.libraries t @ [ "tcpip.udp" ] *)

(*   let configure t = *)
(*     let name = name t in *)
(*     Impl.configure t; *)
(*     append_main "module %s = Udp.Make(%s)" (module_name t) (Impl.module_name t); *)
(*     newline_main (); *)
(*     append_main "let %s () =" name; *)
(*     append_main "   %s () >>= function" (Impl.name t); *)
(*     append_main "   | `Error _ -> %s" (driver_initialisation_error name); *)
(*     append_main "   | `Ok ip   -> %s.connect ip" (module_name t); *)
(*     newline_main () *)

(*   let clean t = *)
(*     Impl.clean t *)

(*   let update_path t root = *)
(*     Impl.update_path t root *)

(* end *)

(* module UDPV4_socket = struct *)

(*   type t = Ipaddr.V4.t option *)

(*   let name _ = "udpv4_socket" *)

(*   let module_name _ = "Udpv4_socket" *)

(*   let packages t = [ "tcpip" ] *)

(*   let libraries t = *)
(*     match get_mode () with *)
(*     | `Unix | `MacOSX -> [ "tcpip.udpv4-socket" ] *)
(*     | `Xen  -> failwith "No socket implementation available for Xen" *)

(*   let configure t = *)
(*     append_main "let %s () =" (name t); *)
(*     let ip = match t with *)
(*       | None    -> "None" *)
(*       | Some ip -> *)
(*         Printf.sprintf "Some (Ipaddr.V4.of_string_exn %s)" (Ipaddr.V4.to_string ip) *)
(*     in *)
(*     append_main " %s.connect %S" (module_name t) ip; *)
(*     newline_main () *)

(*   let clean t = *)
(*     () *)

(*   let update_path t root = *)
(*     t *)

(* end *)

(* type 'a udp = UDP *)

(* type udpv4 = v4 udp *)
(* type udpv6 = v6 udp *)

(* let udp = Type UDP *)
(* let udpv4 : udpv4 typ = udp *)
(* let udpv6 : udpv6 typ = udp *)

(* let direct_udp (type v) (ip : v ip impl) = *)
(*   impl udp ip (module UDP_direct (struct type t = v end)) *)

(* let socket_udpv4 ip = *)
(*   impl udpv4 ip (module UDPV4_socket) *)

(* module TCP_direct (V : sig type t end) = struct *)

(*   type t = { *)
(*     clock : clock impl; *)
(*     time  : time impl; *)
(*     ip    : V.t ip impl; *)
(*     random: random impl; *)
(*   } *)

(*   let name t = *)
(*     let key = "tcp" *)
(*               ^ Impl.name t.clock *)
(*               ^ Impl.name t.time *)
(*               ^ Impl.name t.ip in *)
(*     Name.of_key key ~base:"tcp" *)

(*   let module_name t = *)
(*     String.capitalize (name t) *)

(*   let packages t = *)
(*     "tcpip" *)
(*     :: Impl.packages t.clock *)
(*     @  Impl.packages t.time *)
(*     @  Impl.packages t.ip *)
(*     @  Impl.packages t.random *)

(*   let libraries t = *)
(*     "tcpip.tcp" *)
(*     :: Impl.libraries t.clock *)
(*     @  Impl.libraries t.time *)
(*     @  Impl.libraries t.ip *)
(*     @  Impl.libraries t.random *)

(*   let configure t = *)
(*     let name = name t in *)
(*     Impl.configure t.clock; *)
(*     Impl.configure t.time; *)
(*     Impl.configure t.ip; *)
(*     Impl.configure t.random; *)
(*     append_main "module %s = Tcp.Flow.Make(%s)(%s)(%s)(%s)" *)
(*       (module_name t) *)
(*       (Impl.module_name t.ip) *)
(*       (Impl.module_name t.time) *)
(*       (Impl.module_name t.clock) *)
(*       (Impl.module_name t.random); *)
(*     newline_main (); *)
(*     append_main "let %s () =" name; *)
(*     append_main "   %s () >>= function" (Impl.name t.ip); *)
(*     append_main "   | `Error _ -> %s" (driver_initialisation_error (Impl.name t.ip)); *)
(*     append_main "   | `Ok ip   -> %s.connect ip" (module_name t); *)
(*     newline_main () *)

(*   let clean t = *)
(*     Impl.clean t.clock; *)
(*     Impl.clean t.time; *)
(*     Impl.clean t.ip; *)
(*     Impl.clean t.random *)

(*   let update_path t root = *)
(*     { clock  = Impl.update_path t.clock root; *)
(*       ip     = Impl.update_path t.ip root; *)
(*       time   = Impl.update_path t.time root; *)
(*       random = Impl.update_path t.random root; *)
(*     } *)

(* end *)

(* module TCPV4_socket = struct *)

(*   type t = Ipaddr.V4.t option *)

(*   let name _ = "tcpv4_socket" *)

(*   let module_name _ = "Tcpv4_socket" *)

(*   let packages t = [ "tcpip" ] *)

(*   let libraries t = *)
(*     match get_mode () with *)
(*     | `Unix | `MacOSX -> [ "tcpip.tcpv4-socket" ] *)
(*     | `Xen  -> failwith "No socket implementation available for Xen" *)

(*   let configure t = *)
(*     append_main "let %s () =" (name t); *)
(*     let ip = match t with *)
(*       | None    -> "None" *)
(*       | Some ip -> *)
(*         Printf.sprintf "Some (Ipaddr.V4.of_string_exn %s)" (Ipaddr.V4.to_string ip) *)
(*     in *)
(*     append_main "  %s.connect %S" (module_name t) ip; *)
(*     newline_main () *)

(*   let clean t = *)
(*     () *)

(*   let update_path t root = *)
(*     t *)

(* end *)

(* type 'a tcp = TCP *)

(* type tcpv4 = v4 tcp *)
(* type tcpv6 = v6 tcp *)

(* let tcp = Type TCP *)
(* let tcpv4 : tcpv4 typ = tcp *)
(* let tcpv6 : tcpv6 typ = tcp *)

(* let direct_tcp (type v) *)
(*     ?(clock=default_clock) ?(random=default_random) ?(time=default_time) (ip : v ip impl) = *)
(*   let module TCP_direct = TCP_direct (struct type t = v end) in *)
(*   let t = { TCP_direct.clock; random; time; ip } in *)
(*   impl tcp t (module TCP_direct) *)

(* let socket_tcpv4 ip = *)
(*   impl tcpv4 ip (module TCPV4_socket) *)

(* module STACKV4_direct = struct *)

(*   type t = { *)
(*     clock  : clock impl; *)
(*     time   : time impl; *)
(*     console: console impl; *)
(*     network: network impl; *)
(*     random : random impl; *)
(*     config : [`DHCP | `IPV4 of ipv4_config]; *)
(*   } *)

(*   let name t = *)
(*     let key = "stackv4" *)
(*               ^ Impl.name t.clock *)
(*               ^ Impl.name t.time *)
(*               ^ Impl.name t.console *)
(*               ^ Impl.name t.network *)
(*               ^ Impl.name t.random *)
(*               ^ match t.config with *)
(*               | `DHCP   -> "dhcp" *)
(*               | `IPV4 i -> meta_ipv4_config i in *)
(*     Name.of_key key ~base:"stackv4" *)

(*   let module_name t = *)
(*     String.capitalize (name t) *)

(*   let packages t = *)
(*     "tcpip" *)
(*     :: Impl.packages t.clock *)
(*     @  Impl.packages t.time *)
(*     @  Impl.packages t.console *)
(*     @  Impl.packages t.network *)
(*     @  Impl.packages t.random *)

(*   let libraries t = *)
(*     "tcpip.stack-direct" *)
(*     :: "mirage.runtime" *)
(*     :: Impl.libraries t.clock *)
(*     @  Impl.libraries t.time *)
(*     @  Impl.libraries t.console *)
(*     @  Impl.libraries t.network *)
(*     @  Impl.libraries t.random *)

(*   let configure t = *)
(*     let name = name t in *)
(*     Impl.configure t.clock; *)
(*     Impl.configure t.time; *)
(*     Impl.configure t.console; *)
(*     Impl.configure t.network; *)
(*     Impl.configure t.random; *)
(*     let ethif_name = module_name t ^ "_E" in *)
(*     let arpv4_name = module_name t ^ "_A" in *)
(*     let ipv4_name = module_name t ^ "_I" in *)
(*     let udpv4_name = module_name t ^ "_U" in *)
(*     let tcpv4_name = module_name t ^ "_T" in *)
(*     append_main "module %s = Ethif.Make(%s)" ethif_name (Impl.module_name t.network); *)
(*     append_main "module %s = Arpv4.Make(%s)(%s)(%s)" arpv4_name ethif_name *)
(*       (Impl.module_name t.clock) (Impl.module_name t.time); *)
(*     append_main "module %s = Ipv4.Make(%s)(%s)" ipv4_name ethif_name arpv4_name; *)
(*     append_main "module %s = Udp.Make (%s)" udpv4_name ipv4_name; *)
(*     append_main "module %s = Tcp.Flow.Make(%s)(%s)(%s)(%s)" *)
(*       tcpv4_name ipv4_name (Impl.module_name t.time) *)
(*       (Impl.module_name t.clock) (Impl.module_name t.random); *)
(*     append_main "module %s = Tcpip_stack_direct.Make(%s)(%s)(%s)(%s)(%s)(%s)(%s)(%s)(%s)" *)
(*       (module_name t) *)
(*       (Impl.module_name t.console) *)
(*       (Impl.module_name t.time) *)
(*       (Impl.module_name t.random) *)
(*       (Impl.module_name t.network) *)
(*       ethif_name arpv4_name ipv4_name udpv4_name tcpv4_name; *)
(*     newline_main (); *)
(*     append_main "let %s () =" name; *)
(*     append_main "  %s () >>= function" (Impl.name t.console); *)
(*     append_main "  | `Error _    -> %s" *)
(*       (driver_initialisation_error (Impl.name t.console)); *)
(*     append_main "  | `Ok console ->"; *)
(*     append_main "  %s () >>= function" (Impl.name t.network); *)
(*     append_main "  | `Error e      ->"; *)
(*     let net_init_error_msg_fn = "Mirage_runtime.string_of_network_init_error" in *)
(*     append_main "    fail (Failure (%s %S e))" *)
(*       net_init_error_msg_fn (Impl.name t.network); *)
(*     append_main "  | `Ok interface ->"; *)
(*     append_main "  let config = {"; *)
(*     append_main "    V1_LWT.name = %S;" name; *)
(*     append_main "    console; interface;"; *)
(*     begin match t.config with *)
(*       | `DHCP   -> append_main "    mode = `DHCP;" *)
(*       | `IPV4 i -> append_main "    mode = `IPv4 %s;" (meta_ipv4_config i); *)
(*     end; *)
(*     append_main "  } in"; *)
(*     append_main "  %s.connect interface >>= function" ethif_name; *)
(*     append_main "  | `Error _ -> %s" (driver_initialisation_error ethif_name); *)
(*     append_main "  | `Ok ethif ->"; *)
(*     append_main "  %s.connect ethif >>= function" arpv4_name; *)
(*     append_main "  | `Error _ -> %s" (driver_initialisation_error arpv4_name); *)
(*     append_main "  | `Ok arpv4 ->"; *)
(*     append_main "  %s.connect ethif arpv4 >>= function" ipv4_name; *)
(*     append_main "  | `Error _ -> %s" (driver_initialisation_error ipv4_name); *)
(*     append_main "  | `Ok ipv4 ->"; *)
(*     append_main "  %s.connect ipv4 >>= function" udpv4_name; *)
(*     append_main "  | `Error _ -> %s" (driver_initialisation_error udpv4_name); *)
(*     append_main "  | `Ok udpv4 ->"; *)
(*     append_main "  %s.connect ipv4 >>= function" tcpv4_name; *)
(*     append_main "  | `Error _ -> %s" (driver_initialisation_error tcpv4_name); *)
(*     append_main "  | `Ok tcpv4 ->"; *)
(*     append_main "  %s.connect config ethif arpv4 ipv4 udpv4 tcpv4" (module_name t); *)
(*     newline_main () *)

(*   let clean t = *)
(*     Impl.clean t.clock; *)
(*     Impl.clean t.time; *)
(*     Impl.clean t.console; *)
(*     Impl.clean t.network; *)
(*     Impl.clean t.random *)

(*   let update_path t root = *)
(*     { t with *)
(*       clock   = Impl.update_path t.clock root; *)
(*       time    = Impl.update_path t.time root; *)
(*       console = Impl.update_path t.console root; *)
(*       network = Impl.update_path t.network root; *)
(*       random  = Impl.update_path t.random root; *)
(*     } *)

(* end *)

(* module STACKV4_socket = struct *)

(*   type t = { *)
(*     console: console impl; *)
(*     ipv4s  : Ipaddr.V4.t list; *)
(*   } *)

(*   let meta_ips ips = *)
(*     String.concat "; " *)
(*       (List.map (fun x -> *)
(*            Printf.sprintf "Ipaddr.V4.of_string_exn %S" (Ipaddr.V4.to_string x) *)
(*          ) ips) *)

(*   let name t = *)
(*     let key = "stackv4" ^ Impl.name t.console ^ meta_ips t.ipv4s in *)
(*     Name.of_key key ~base:"stackv4" *)

(*   let module_name t = *)
(*     String.capitalize (name t) *)

(*   let packages t = *)
(*     "tcpip" :: Impl.packages t.console *)

(*   let libraries t = *)
(*     "tcpip.stack-socket" :: Impl.libraries t.console *)

(*   let configure t = *)
(*     let name = name t in *)
(*     Impl.configure t.console; *)
(*     append_main "module %s = Tcpip_stack_socket.Make(%s)" *)
(*       (module_name t) (Impl.module_name t.console); *)
(*     newline_main (); *)
(*     append_main "let %s () =" name; *)
(*     append_main "  %s () >>= function" (Impl.name t.console); *)
(*     append_main "  | `Error _    -> %s" *)
(*       (driver_initialisation_error (Impl.name t.console)); *)
(*     append_main "  | `Ok console ->"; *)
(*     append_main "  let config = {"; *)
(*     append_main "    V1_LWT.name = %S;" name; *)
(*     append_main "    console; interface = [%s];" (meta_ips t.ipv4s); *)
(*     append_main "    mode = ();"; *)
(*     append_main "  } in"; *)
(*     append_main "  Udpv4_socket.connect None >>= function"; *)
(*     append_main "  | `Error _ -> %s" (driver_initialisation_error "Udpv4_socket"); *)
(*     append_main "  | `Ok udpv4 ->"; *)
(*     append_main "  Tcpv4_socket.connect None >>= function"; *)
(*     append_main "  | `Error _ -> %s" (driver_initialisation_error "Tcpv4_socket"); *)
(*     append_main "  | `Ok tcpv4 ->"; *)
(*     append_main "  %s.connect config udpv4 tcpv4" (module_name t); *)
(*     newline_main () *)

(*   let clean t = *)
(*     Impl.clean t.console *)

(*   let update_path t root = *)
(*     { t with console = Impl.update_path t.console root } *)

(* end *)

(* type stackv4 = STACKV4 *)

(* let stackv4 = Type STACKV4 *)

(* let direct_stackv4_with_dhcp *)
(*     ?(clock=default_clock) *)
(*     ?(random=default_random) *)
(*     ?(time=default_time) *)
(*     console network = *)
(*   let t = { *)
(*     STACKV4_direct.console; network; time; clock; random; *)
(*     config = `DHCP } in *)
(*   impl stackv4 t (module STACKV4_direct) *)

(* let direct_stackv4_with_default_ipv4 *)
(*     ?(clock=default_clock) *)
(*     ?(random=default_random) *)
(*     ?(time=default_time) *)
(*     console network = *)
(*   let t = { *)
(*     STACKV4_direct.console; network; clock; time; random; *)
(*     config = `IPV4 default_ipv4_conf; *)
(*   } in *)
(*   impl stackv4 t (module STACKV4_direct) *)

(* let direct_stackv4_with_static_ipv4 *)
(*     ?(clock=default_clock) *)
(*     ?(random=default_random) *)
(*     ?(time=default_time) *)
(*     console network ipv4 = *)
(*   let t = { *)
(*     STACKV4_direct.console; network; clock; time; random; *)
(*     config = `IPV4 ipv4; *)
(*   } in *)
(*   impl stackv4 t (module STACKV4_direct) *)

(* let socket_stackv4 console ipv4s = *)
(*   impl stackv4 { STACKV4_socket.console; ipv4s } (module STACKV4_socket) *)

(* module Conduit = struct *)

(*   type t = { *)
(*     stackv4: stackv4 impl option; *)
(*     tls    : bool; *)
(*   } *)

(*   let name t = *)
(*     let key = *)
(*       "conduit" ^ *)
(*       (match t.stackv4 with None -> "" | Some t -> Impl.name t) ^ *)
(*       (match t.tls with false -> "" | true -> "tls") *)
(*     in *)
(*     Name.of_key key ~base:"conduit" *)

(*   let module_name t = String.capitalize (name t) *)

(*   let packages t = *)
(*     "mirage-conduit" :: ( *)
(*       match t.stackv4 with *)
(*       | None   -> [] *)
(*       | Some s -> Impl.packages s *)
(*     ) @ ( *)
(*       match t.tls with *)
(*       | false -> [] *)
(*       | true  -> ["tls"] *)
(*     ) *)

(*   let libraries t = *)
(*     "conduit.mirage" :: ( *)
(*       match t.stackv4 with *)
(*       | None   -> [] *)
(*       | Some s -> Impl.libraries s *)
(*     ) @ ( *)
(*       match t.tls with *)
(*       | false -> [] *)
(*       | true  -> ["tls"] *)
(*     ) *)

(*   let configure t = *)
(*     begin match t.stackv4 with *)
(*       | None   -> () *)
(*       | Some s -> Impl.configure s *)
(*     end; *)
(*     append_main "module %s = Conduit_mirage" (module_name t); *)
(*     newline_main (); *)
(*     append_main "let %s () = Lwt.return Conduit_mirage.empty" (name t); *)
(*     begin match t.stackv4 with *)
(*       | None   -> () *)
(*       | Some s -> *)
(*         append_main "let %s () =" (name t); *)
(*         append_main "  %s () >>= fun t ->" (name t); *)
(*         append_main "  %s () >>= function" (Impl.name s); *)
(*         append_main "  | `Error e -> %s" (driver_initialisation_error "stack"); *)
(*         append_main "  | `Ok s    ->"; *)
(*         append_main "    let tcp = Conduit_mirage.stackv4 (module %s) in" *)
(*           (Impl.module_name s); *)
(*         append_main "    Conduit_mirage.with_tcp t tcp s" *)
(*     end; *)
(*     begin match t.tls with *)
(*       | false -> () *)
(*       | true  -> *)
(*         append_main "let %s () =" (name t); *)
(*         append_main "  %s () >>= fun t ->" (name t); *)
(*         append_main "  Conduit_mirage.with_tls t" *)
(*     end; *)
(*     append_main "let %s () = %s () >>= fun t -> Lwt.return (`Ok t)" *)
(*       (name t) (name t); *)
(*     newline_main () *)

(*   let clean t = *)
(*     match t.stackv4 with *)
(*     | None   -> () *)
(*     | Some s -> Impl.clean s *)

(*   let update_path t root = *)
(*     match t.stackv4 with *)
(*     | None   -> t *)
(*     | Some s -> { t with stackv4 = Some (Impl.update_path s root) } *)

(* end *)

(* type conduit = Conduit *)

(* let conduit = Type Conduit *)

(* let conduit_direct ?(tls=false) s = *)
(*   impl conduit { Conduit.stackv4 = Some s; tls } (module Conduit) *)

(* module Resolver_unix = struct *)
(*   type t = unit *)

(*   let name t = *)
(*     let key = "resolver_unix" in *)
(*     Name.of_key key ~base:"resolver" *)

(*   let module_name t = *)
(*     String.capitalize (name t) *)

(*   let packages t = *)
(*     match get_mode () with *)
(*     |`Unix | `MacOSX -> [ "mirage-conduit" ] *)
(*     |`Xen -> failwith "Resolver_unix not supported on Xen" *)

(*   let libraries t = *)
(*     [ "conduit.mirage"; "conduit.lwt-unix" ] *)

(*   let configure t = *)
(*     append_main "module %s = Resolver_lwt" (module_name t); *)
(*     append_main "let %s () =" (name t); *)
(*     append_main "  return (`Ok Resolver_lwt_unix.system)"; *)
(*     newline_main () *)

(*   let clean t = () *)

(*   let update_path t root = t *)

(* end *)

(* module Resolver_direct = struct *)
(*   type t = *)
(*     [ `DNS of stackv4 impl * Ipaddr.V4.t option * int option ] *)

(*   let name t = *)
(*     let key = "resolver" ^ match t with *)
(*      | `DNS (s,_,_) -> Impl.name s in *)
(*     Name.of_key key ~base:"resolver" *)

(*   let module_name_core t = *)
(*     String.capitalize (name t) *)

(*   let module_name t = *)
(*     (module_name_core t) ^ "_res" *)

(*   let packages t = *)
(*     [ "dns"; "tcpip" ] @ *)
(*     match t with *)
(*     | `DNS (s,_,_) -> Impl.packages s *)

(*   let libraries t = *)
(*     [ "dns.mirage" ] @ *)
(*     match t with *)
(*     | `DNS (s,_,_) -> Impl.libraries s *)

(*   let configure t = *)
(*     begin match t with *)
(*       | `DNS (s,_,_) -> *)
(*         Impl.configure s; *)
(*         append_main "module %s = Resolver_lwt" (module_name t); *)
(*         append_main "module %s_dns = Dns_resolver_mirage.Make(OS.Time)(%s)" *)
(*           (module_name_core t) (Impl.module_name s); *)
(*         append_main "module %s = Resolver_mirage.Make(%s_dns)" *)
(*           (module_name_core t) (module_name_core t); *)
(*     end; *)
(*     newline_main (); *)
(*     append_main "let %s () =" (name t); *)
(*     let subname = match t with *)
(*       | `DNS (s,_,_) -> Impl.name s in *)
(*     append_main "  %s () >>= function" subname; *)
(*     append_main "  | `Error _  -> %s" (driver_initialisation_error subname); *)
(*     append_main "  | `Ok %s ->" subname; *)
(*     let res_ns = match t with *)
(*      | `DNS (_,None,_) -> "None" *)
(*      | `DNS (_,Some ns,_) -> *)
(*          Printf.sprintf "Ipaddr.V4.of_string %S" (Ipaddr.V4.to_string ns) in *)
(*     append_main "  let ns = %s in" res_ns; *)
(*     let res_ns_port = match t with *)
(*      | `DNS (_,_,None) -> "None" *)
(*      | `DNS (_,_,Some ns_port) -> Printf.sprintf "Some %d" ns_port in *)
(*     append_main "  let ns_port = %s in" res_ns_port; *)
(*     append_main "  let res = %s.init ?ns ?ns_port ~stack:%s () in" (module_name_core t) subname; *)
(*     append_main "  return (`Ok res)"; *)
(*     newline_main () *)

(*   let clean = function *)
(*     | `DNS (s,_,_) -> Impl.clean s *)

(*   let update_path t root = *)
(*     match t with *)
(*     | `DNS (s,a,b) -> `DNS (Impl.update_path s root, a, b) *)

(* end *)

(* type resolver = Resolver *)

(* let resolver = Type Resolver *)

(* let resolver_dns ?ns ?ns_port stack = *)
(*   impl resolver (`DNS (stack, ns, ns_port)) (module Resolver_direct) *)

(* let resolver_unix_system = *)
(*   impl resolver () (module Resolver_unix) *)

(* module HTTP = struct *)

(*   type t = { conduit: conduit impl } *)

(*   let name { conduit } = *)
(*     let key = "http" ^ Impl.name conduit in *)
(*     Name.of_key key ~base:"http" *)

(*   let module_name t = *)
(*     String.capitalize (name t) *)

(*   let packages { conduit }= *)
(*     [ "mirage-http" ] @ *)
(*     Impl.packages conduit *)

(*   let libraries { conduit } = *)
(*     [ "mirage-http" ] @ *)
(*     Impl.libraries conduit *)

(*   let configure t = *)
(*     Impl.configure t.conduit; *)
(*     append_main "module %s = Cohttp_mirage.Server(%s.Flow)" *)
(*       (module_name t) (Impl.module_name t.conduit); *)
(*     newline_main (); *)
(*     append_main "let %s () =" (name t); *)
(*     append_main "  %s () >>= function" (Impl.name t.conduit); *)
(*     append_main "  | `Error _ -> assert false"; *)
(*     append_main "  | `Ok t ->"; *)
(*     append_main "    let listen s f ="; *)
(*     append_main "      %s.listen t s (%s.listen f)" *)
(*       (Impl.module_name t.conduit) (module_name t); *)
(*     append_main "    in"; *)
(*     append_main "    return (`Ok listen)"; *)
(*     newline_main () *)

(*   let clean { conduit } = Impl.clean conduit *)

(*   let update_path { conduit } root = *)
(*     { conduit =  Impl.update_path conduit root } *)

(* end *)

(* type http = HTTP *)

(* let http = Type HTTP *)

(* let http_server conduit = impl http { HTTP.conduit } (module HTTP) *)

(* type job = JOB *)

(* let job = Type JOB *)

(* module Job = struct *)

(*   type t = { *)
(*     name: string; *)
(*     impl: job impl; *)
(*   } *)

(*   let create impl = *)
(*     let name = Name.create "job" in *)
(*     { name; impl } *)

(*   let name t = *)
(*     t.name *)

(*   let module_name t = *)
(*     "Job_" ^ t.name *)

(*   let packages t = *)
(*     Impl.packages t.impl *)

(*   let libraries t = *)
(*     Impl.libraries t.impl *)

(*   let configure t = *)
(*     Impl.configure t.impl; *)
(*     newline_main () *)

(*   let clean t = *)
(*     Impl.clean t.impl *)

(*   let update_path t root = *)
(*     { t with impl = Impl.update_path t.impl root } *)

(* end *)

(* module Tracing = struct *)
(*   type t = { *)
(*     size : int; *)
(*   } *)

(*   let unix_trace_file = "trace.ctf" *)

(*   let packages _ = StringSet.singleton "mirage-profile" *)

(*   let libraries _ = *)
(*     match get_mode () with *)
(*     | `Unix | `MacOSX -> StringSet.singleton "mirage-profile.unix" *)
(*     | `Xen  -> StringSet.singleton "mirage-profile.xen" *)

(*   let configure t = *)
(*     if Sys.command "ocamlfind query lwt.tracing 2>/dev/null" <> 0 then ( *)
(*       flush stdout; *)
(*       error "lwt.tracing module not found. Hint:\n\ *)
(*              opam pin add lwt 'https://github.com/mirage/lwt.git#tracing'" *)
(*     ); *)

(*     append_main "let () = "; *)
(*     begin match get_mode () with *)
(*     | `Unix | `MacOSX -> *)
(*         append_main "  let buffer = MProf_unix.mmap_buffer ~size:%d %S in" t.size unix_trace_file; *)
(*         append_main "  let trace_config = MProf.Trace.Control.make buffer MProf_unix.timestamper in"; *)
(*         append_main "  MProf.Trace.Control.start trace_config"; *)
(*     | `Xen  -> *)
(*         append_main "  let trace_pages = MProf_xen.make_shared_buffer ~size:%d in" t.size; *)
(*         append_main "  let buffer = trace_pages |> Io_page.to_cstruct |> Cstruct.to_bigarray in"; *)
(*         append_main "  let trace_config = MProf.Trace.Control.make buffer MProf_xen.timestamper in"; *)
(*         append_main "  MProf.Trace.Control.start trace_config;"; *)
(*         append_main "  MProf_xen.share_with (module Gnt.Gntshr) (module OS.Xs) ~domid:0 trace_pages"; *)
(*         append_main "  |> OS.Main.run"; *)
(*     end; *)
(*     newline_main () *)
(* end *)

(* type tracing = Tracing.t *)

(* let mprof_trace ~size () = *)
(*   { Tracing.size } *)

(* module Nocrypto_entropy = struct *)

(*   (\* XXX *)
(*    * Nocrypto needs `mirage-entropy-xen` if compiled for xen. *)
(*    * This is currently handled by always installing this library, regardless of *)
(*    * usage of Nocrypto. *)
(*    * As `libraries` is run after opam setup, it will correctly detect Nocrypto *)
(*    * usage and inject appropriate deps for linkage, if needed. *)
(*    * The `packages` function, unconditional installation of *)
(*    * `mirage-entropy-xen`, and this comment, should be cleared once we have *)
(*    * conditional dependencies support in opam. *)
(*    * See https://github.com/mirage/mirage/pull/394 for discussion. *)
(*    *\) *)

(*   module SS = StringSet *)

(*   let remembering r f = *)
(*     match !r with *)
(*     | Some x -> x *)
(*     | None   -> let x = f () in r := Some x ; x *)

(*   let linkage_ = ref None *)

(*   let linkage () = *)
(*     match !linkage_ with *)
(*     | None   -> failwith "Nocrypto_entropy: `linkage` queried before `libraries`" *)
(*     | Some x -> x *)

(*   let packages () = *)
(*     match get_mode () with *)
(*     | `Xen -> SS.singleton "mirage-entropy-xen" *)
(*     | _    -> SS.empty *)

(*   let libraries libs = *)
(*     remembering linkage_ @@ fun () -> *)
(*       let needed = *)
(*         OCamlfind.query ~recursive:true (SS.elements libs) *)
(*           |> List.exists ((=) "nocrypto") in *)
(*       match get_mode () with *)
(*       | `Xen              when needed -> SS.singleton "nocrypto.xen" *)
(*       | (`Unix | `MacOSX) when needed -> SS.singleton "nocrypto.lwt" *)
(*       | _                             -> SS.empty *)

(*   let configure () = *)
(*     SS.elements (linkage ()) |> List.iter (fun lib -> *)
(*       if not (OCamlfind.installed lib) then *)
(*         error "%s module not found. Hint: reinstall nocrypto." lib *)
(*       ) *)

(*   let preamble () = *)
(*     match (get_mode (), not (SS.is_empty @@ linkage ())) with *)
(*     | (`Xen             , true) -> "Nocrypto_entropy_xen.initialize ()" *)
(*     | ((`Unix | `MacOSX), true) -> "Nocrypto_entropy_lwt.initialize ()" *)
(*     | _                         -> "return_unit" *)
(* end *)

let configure_main_libvirt_xml t =
  let open Codegen in
  let file = t.root / t.name ^ "_libvirt.xml" in
  Fmt.with_file file @@ fun fmt ->
  append fmt "<!-- %s -->" (generated_header t.name);
  append fmt "<domain type='xen'>";
  append fmt "    <name>%s</name>" t.name;
  append fmt "    <memory unit='KiB'>262144</memory>";
  append fmt "    <currentMemory unit='KiB'>262144</currentMemory>";
  append fmt "    <vcpu placement='static'>1</vcpu>";
  append fmt "    <os>";
  append fmt "        <type arch='armv7l' machine='xenpv'>linux</type>";
  append fmt "        <kernel>%s/mir-%s.xen</kernel>" t.root t.name;
  append fmt "        <cmdline> </cmdline>"; (* the libxl driver currently needs an empty cmdline to be able to start the domain on arm - due to this? http://lists.xen.org/archives/html/xen-devel/2014-02/msg02375.html *)
  append fmt "    </os>";
  append fmt "    <clock offset='utc' adjustment='reset'/>";
  append fmt "    <on_crash>preserve</on_crash>";
  append fmt "    <!-- ";
  append fmt "    You must define network and block interfaces manually.";
  append fmt "    See http://libvirt.org/drvxen.html for information about converting .xl-files to libvirt xml automatically.";
  append fmt "    -->";
  append fmt "    <devices>";
  append fmt "        <!--";
  append fmt "        The disk configuration is defined here:";
  append fmt "        http://libvirt.org/formatstorage.html.";
  append fmt "        An example would look like:";
  append fmt"         <disk type='block' device='disk'>";
  append fmt "            <driver name='phy'/>";
  append fmt "            <source dev='/dev/loop0'/>";
  append fmt "            <target dev='' bus='xen'/>";
  append fmt "        </disk>";
  append fmt "        -->";
  append fmt "        <!-- ";
  append fmt "        The network configuration is defined here:";
  append fmt "        http://libvirt.org/formatnetwork.html";
  append fmt "        An example would look like:";
  append fmt "        <interface type='bridge'>";
  append fmt "            <mac address='c0:ff:ee:c0:ff:ee'/>";
  append fmt "            <source bridge='br0'/>";
  append fmt "        </interface>";
  append fmt "        -->";
  append fmt "        <console type='pty'>";
  append fmt "            <target type='xen' port='0'/>";
  append fmt "        </console>";
  append fmt "    </devices>";
  append fmt "</domain>";
  ()

let clean_main_libvirt_xml t =
  remove (t.root / t.name ^ "_libvirt.xml")

let configure_main_xl t =
  let open Codegen in
  let file = t.root / t.name ^ ".xl" in
  Fmt.with_file file @@ fun fmt ->
  append fmt "# %s" (generated_header t.name);
  newline fmt;
  append fmt "name = '%s'" t.name;
  append fmt "kernel = '%s/mir-%s.xen'" t.root t.name;
  append fmt "builder = 'linux'";
  append fmt "memory = 256";
  append fmt "on_crash = 'preserve'";
  newline fmt;
  let blocks = List.map (fun b ->
    (* We need the Linux version of the block number (this is a strange historical
       artifact) Taken from https://github.com/mirage/mirage-block-xen/blob/a64d152586c7ebc1d23c5adaa4ddd440b45a3a83/lib/device_number.ml#L128 *)
      let rec string_of_int26 x =
        let (/) = Pervasives.(/) in
        let high, low = x / 26 - 1, x mod 26 + 1 in
        let high' = if high = -1 then "" else string_of_int26 high in
        let low' = String.make 1 (char_of_int (low + (int_of_char 'a') - 1)) in
        high' ^ low' in
    let vdev = Printf.sprintf "xvd%s" (string_of_int26 b.number) in
    let path = Filename.concat t.root b.filename in
    Printf.sprintf "'format=raw, vdev=%s, access=rw, target=%s'" vdev path
  ) (Hashtbl.fold (fun _ v acc -> v :: acc) all_blocks []) in
  append fmt "disk = [ %s ]" (String.concat ", " blocks);
  newline fmt;
  append fmt "# The network configuration is defined here:";
  append fmt "# http://xenbits.xen.org/docs/4.3-testing/misc/xl-network-configuration.html";
  append fmt "# An example would look like:";
  append fmt "# vif = [ 'mac=c0:ff:ee:c0:ff:ee,bridge=br0' ]";
  ()

let clean_main_xl t =
  remove (t.root / t.name ^ ".xl")

let configure_main_xe t =
  let open Codegen in
  let file = t.root / t.name ^ ".xe" in
  Fmt.with_file file @@ fun fmt ->
  append fmt "#!/bin/sh";
  append fmt "# %s" (generated_header t.name);
  newline fmt;
  append fmt "set -e";
  newline fmt;
  append fmt "# Dependency: xe";
  append fmt "command -v xe >/dev/null 2>&1 || { echo >&2 \"I require xe but it's not installed.  Aborting.\"; exit 1; }";
  append fmt "# Dependency: xe-unikernel-upload";
  append fmt "command -v xe-unikernel-upload >/dev/null 2>&1 || { echo >&2 \"I require xe-unikernel-upload but it's not installed.  Aborting.\"; exit 1; }";
  append fmt "# Dependency: a $HOME/.xe";
  append fmt "if [ ! -e $HOME/.xe ]; then";
  append fmt "  echo Please create a config file for xe in $HOME/.xe which contains:";
  append fmt "  echo server='<IP or DNS name of the host running xapi>'";
  append fmt "  echo username=root";
  append fmt "  echo password=password";
  append fmt "  exit 1";
  append fmt "fi";
  newline fmt;
  append fmt "echo Uploading VDI containing unikernel";
  append fmt "VDI=$(xe-unikernel-upload --path %s/mir-%s.xen)" t.root t.name;
  append fmt "echo VDI=$VDI";
  append fmt "echo Creating VM metadata";
  append fmt "VM=$(xe vm-create name-label=%s)" t.name;
  append fmt "echo VM=$VM";
  append fmt "xe vm-param-set uuid=$VM PV-bootloader=pygrub";
  append fmt "echo Adding network interface connected to xenbr0";
  append fmt "ETH0=$(xe network-list bridge=xenbr0 params=uuid --minimal)";
  append fmt "VIF=$(xe vif-create vm-uuid=$VM network-uuid=$ETH0 device=0)";
  append fmt "echo Atting block device and making it bootable";
  append fmt "VBD=$(xe vbd-create vm-uuid=$VM vdi-uuid=$VDI device=0)";
  append fmt "xe vbd-param-set uuid=$VBD bootable=true";
  append fmt "xe vbd-param-set uuid=$VBD other-config:owner=true";
  List.iter (fun b ->
    append fmt "echo Uploading data VDI %s" b.filename;
    append fmt "echo VDI=$VDI";
    append fmt "SIZE=$(stat --format '%%s' %s/%s)" t.root b.filename;
    append fmt "POOL=$(xe pool-list params=uuid --minimal)";
    append fmt "SR=$(xe pool-list uuid=$POOL params=default-SR --minimal)";
    append fmt "VDI=$(xe vdi-create type=user name-label='%s' virtual-size=$SIZE sr-uuid=$SR)" b.filename;
    append fmt "xe vdi-import uuid=$VDI filename=%s/%s" t.root b.filename;
    append fmt "VBD=$(xe vbd-create vm-uuid=$VM vdi-uuid=$VDI device=%d)" b.number;
    append fmt "xe vbd-param-set uuid=$VBD other-config:owner=true";
  ) (Hashtbl.fold (fun _ v acc -> v :: acc) all_blocks []);
  append fmt "echo Starting VM";
  append fmt "xe vm-start vm=%s" t.name;
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

let configure_myocamlbuild_ml t =
  let open Functoria_misc in
  let minor, major = ocaml_version () in
  if minor < 4 || major < 1 then (
    (* Previous ocamlbuild versions weren't able to understand the
       --output-obj rules *)
    let file = t.root / "myocamlbuild.ml" in
    Fmt.with_file file @@ fun fmt ->
    Codegen.append fmt "(* %s *)" (generated_header t.name);
    Codegen.newline fmt;
    Codegen.append fmt
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
  )

let clean_myocamlbuild_ml t =
  remove (t.root / "myocamlbuild.ml")

let configure_makefile t =
  let open Codegen in
  let file = t.root / "Makefile" in
  let pkgs = libraries t in
  let libraries_str =
    match pkgs with
    | [] -> ""
    | ls -> "-pkgs " ^ String.concat "," ls in
  let packages = String.concat " " pkgs in
  Fmt.with_file file @@ fun fmt ->
  append fmt "# %s" (generated_header t.name);
  newline fmt;
  append fmt "LIBS   = %s" libraries_str;
  append fmt "PKGS   = %s" packages;
  begin match get_mode () with
    | `Xen  ->
      append fmt "SYNTAX = -tags \"syntax(camlp4o),annot,bin_annot,strict_sequence,principal\"\n";
      append fmt "SYNTAX += -tag-line \"<static*.*>: -syntax(camlp4o)\"\n";
      append fmt "FLAGS  = -cflag -g -lflags -g,-linkpkg,-dontlink,unix\n";
      append fmt "XENLIB = $(shell ocamlfind query mirage-xen)\n"
    | `Unix ->
      append fmt "SYNTAX = -tags \"syntax(camlp4o),annot,bin_annot,strict_sequence,principal\"\n";
      append fmt "SYNTAX += -tag-line \"<static*.*>: -syntax(camlp4o)\"\n";
      append fmt "FLAGS  = -cflag -g -lflags -g,-linkpkg\n"
    | `MacOSX ->
      append fmt "SYNTAX = -tags \"syntax(camlp4o),annot,bin_annot,strict_sequence,principal,thread\"\n";
      append fmt "SYNTAX += -tag-line \"<static*.*>: -syntax(camlp4o)\"\n";
      append fmt "FLAGS  = -cflag -g -lflags -g,-linkpkg\n"
  end;
  append fmt "BUILD  = ocamlbuild -use-ocamlfind $(LIBS) $(SYNTAX) $(FLAGS)\n\
             OPAM   = opam\n\n\
             export PKG_CONFIG_PATH=$(shell opam config var prefix)/lib/pkgconfig\n\n\
             export OPAMVERBOSE=1\n\
             export OPAMYES=1";
  newline fmt;
  append fmt ".PHONY: all depend clean build main.native\n\
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
  newline fmt;

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

  begin match get_mode () with
    | `Xen ->
      let filter = function
        | "unix" | "bigarray" |"shared_memory_ring_stubs" -> false    (* Provided by mirage-xen instead. *)
        | _ -> true in
      let extra_c_archives =
        get_extra_ld_flags ~filter pkgs
        |> String.concat " \\\n\t  " in

      append fmt "build:: main.native.o";
      let pkg_config_deps = "mirage-xen" in
      append fmt "\tpkg-config --print-errors --exists %s" pkg_config_deps;
      append fmt "\tld -d -static -nostdlib \\\n\
                 \t  _build/main.native.o \\\n\
                 \t  %s \\\n\
                 \t  $$(pkg-config --static --libs %s) \\\n\
                 \t  $(shell gcc -print-libgcc-file-name) \\\n\
                 %s"
        extra_c_archives pkg_config_deps generate_image;
    | `Unix | `MacOSX ->
      append fmt "build: main.native";
      append fmt "\tln -nfs _build/main.native mir-%s" t.name;
  end;
  newline fmt;
  append fmt "clean::\n\
             \tocamlbuild -clean";
  newline fmt;
  append fmt "-include Makefile.user";
  ()


let clean_makefile t =
  remove (t.root / "Makefile")


let configure t =
  info "%a %s" blue "Configuring for target:" (string_of_mode @@ get_mode ());
  in_dir t.root (fun () ->
      configure_main_xl t;
      configure_main_xe t;
      configure_main_libvirt_xml t;
      configure_myocamlbuild_ml t;
      configure_makefile t;
    )


let clean t =
  in_dir t.root (fun () ->
      clean_main_xl t;
      clean_main_xe t;
      clean_main_libvirt_xml t;
      clean_myocamlbuild_ml t;
      clean_makefile t;
      command "rm -rf %s/mir-%s" t.root t.name;
    )

module Project = struct

  let application_name = "mirage"

  let version = Mirage_version.current

  type state = unit

  class conf global_conf : [job] configurable = object (self)
    inherit dummy_conf
    method private conf = Lazy.force global_conf
    method ty = job
    method name = "mirage"
    method module_name = "Mirage_runtime"
    method! keys = [ Key.V target ]

    method! packages =
      match get_mode () with
      | `Unix | `MacOSX -> ["mirage-unix"]
      | `Xen  -> ["mirage-xen"]

    method! libraries = [
      "lwt.syntax" ; "mirage.runtime" ;
      "mirage-types.lwt"
    ]

    method! connect _mod names =
      Some (Printf.sprintf
        "OS.Main.run (set_bootvar () >>= fun () -> join [%s])"
        (* (Nocrypto_entropy.preamble ()) *)
        (String.concat "; " names))

    method configure = configure self#conf

    method clean = clean self#conf

  end


end

let () = set_section "Mirage"

module Config = Functoria.Make (Project)
include (Config : CONFIG with module Project := Project)
