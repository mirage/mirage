(*
 * Copyright (c) 2013 Thomas Gazagnaire <thomas@gazagnaire.org>
 * Copyright (c) 2013 Anil Madhavapeddy <anil@recoil.org>
 * Copyright (c) 2018 Mindy Preston     <meetup@yomimono.org>
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

open Rresult
open Astring

module Key = Mirage_key
module Name = Functoria_app.Name
module Codegen = Functoria_app.Codegen

let src = Logs.Src.create "mirage" ~doc:"mirage cli tool"
module Log = (val Logs.src_log src : Logs.LOG)

include Functoria

let get_target i = Key.(get (Info.context i) target)

let with_output ?mode f k err =
  match Bos.OS.File.with_oc ?mode f k () with
  | Ok b -> b
  | Error _ -> R.error_msg ("couldn't open output channel for " ^ err)

let connect_err name number =
  Fmt.strf "The %s connect expects exactly %d argument%s"
    name number (if number = 1 then "" else "s")

(** {2 OCamlfind predicates} *)

(* Mirage implementation backing the target. *)
let backend_predicate = function
  | `Xen | `Qubes           -> "mirage_xen"
  | `Virtio | `Ukvm | `Muen -> "mirage_solo5"
  | `Unix | `MacOSX         -> "mirage_unix"

(** {2 Devices} *)
let qrexec = job

let qrexec_qubes = impl @@ object
  inherit base_configurable
  method ty = qrexec
  val name = Name.ocamlify @@ "qrexec_"
  method name = name
  method module_name = "Qubes.RExec"
  method! packages = Key.pure [ package ~min:"0.4" "mirage-qubes" ]
  method! configure i =
    match get_target i with
    | `Qubes -> R.ok ()
    | _ -> R.error_msg "Qubes remote-exec invoked for non-Qubes target."
  method! connect _ modname _args =
    Fmt.strf
      "@[<v 2>\
       %s.connect ~domid:0 () >>= fun qrexec ->@ \
       Lwt.async (fun () ->@ \
       OS.Lifecycle.await_shutdown_request () >>= fun _ ->@ \
       %s.disconnect qrexec);@ \
       Lwt.return (`Ok qrexec)@]"
      modname modname
end

let gui = job

let gui_qubes = impl @@ object
  inherit base_configurable
  method ty = gui
  val name = Name.ocamlify @@ "gui"
  method name = name
  method module_name = "Qubes.GUI"
  method! packages = Key.pure [ package ~min:"0.4" "mirage-qubes" ]
  method! configure i =
    match get_target i with
    | `Qubes -> R.ok ()
    | _ -> R.error_msg "Qubes GUI invoked for non-Qubes target."
  method! connect _ modname _args =
    Fmt.strf
      "@[<v 2>\
       %s.connect ~domid:0 () >>= fun gui ->@ \
       Lwt.async (fun () -> %s.listen gui);@ \
       Lwt.return (`Ok gui)@]"
      modname modname
end

type qubesdb = QUBES_DB
let qubesdb = Type QUBES_DB

let qubesdb_conf = object
  inherit base_configurable
  method ty = qubesdb
  method name = "qubesdb"
  method module_name = "Qubes.DB"
  method! packages = Key.pure [ package ~min:"0.4" "mirage-qubes" ]
  method! configure i =
    match get_target i with
    | `Qubes | `Xen -> R.ok ()
    | _ -> R.error_msg "Qubes DB invoked for an unsupported target; qubes and xen are supported"
  method! connect _ modname _args = Fmt.strf "%s.connect ~domid:0 ()" modname
end

let default_qubesdb = impl qubesdb_conf

type io_page = IO_PAGE
let io_page = Type IO_PAGE

let io_page_conf = object
  inherit base_configurable
  method ty = io_page
  method name = "io_page"
  method module_name = "Io_page"
  method! packages =
    Key.(if_ is_unix)
      [ package ~sublibs:["unix"] "io-page" ]
      [ package "io-page" ]
end

let default_io_page = impl io_page_conf

type time = TIME
let time = Type TIME

let time_conf = object
  inherit base_configurable
  method ty = time
  method name = "time"
  method module_name = "OS.Time"
end

let default_time = impl time_conf

type pclock = PCLOCK
let pclock = Type PCLOCK

let posix_clock_conf = object
  inherit base_configurable
  method ty = pclock
  method name = "pclock"
  method module_name = "Pclock"
  method! packages =
    Key.(if_ is_unix)
      [ package ~min:"1.2.0" "mirage-clock-unix" ]
      [ package ~min:"1.2.0" "mirage-clock-freestanding" ]
  method! connect _ modname _args = Fmt.strf "%s.connect ()" modname
end

let default_posix_clock = impl posix_clock_conf

type mclock = MCLOCK
let mclock = Type MCLOCK

let monotonic_clock_conf = object
  inherit base_configurable
  method ty = mclock
  method name = "mclock"
  method module_name = "Mclock"
  method! packages =
    Key.(if_ is_unix)
      [ package ~min:"1.2.0" "mirage-clock-unix" ]
      [ package ~min:"1.2.0" "mirage-clock-freestanding" ]
  method! connect _ modname _args = Fmt.strf "%s.connect ()" modname
end

let default_monotonic_clock = impl monotonic_clock_conf

type random = RANDOM
let random = Type RANDOM

let stdlib_random_conf = object
  inherit base_configurable
  method ty = random
  method name = "random"
  method module_name = "Stdlibrandom"
  method! packages = Key.pure [ package "mirage-random" ]
  method! connect _ modname _ = Fmt.strf "Lwt.return (%s.initialize ())" modname
end

let stdlib_random = impl stdlib_random_conf


let query_ocamlfind ?(recursive = false) ?(format="%p") ?predicates libs =
  let open Bos in
  let flag = if recursive then (Cmd.v "-recursive") else Cmd.empty
  and format = Cmd.of_list [ "-format" ; format ]
  and predicate = match predicates with
    | None -> []
    | Some x -> [ "-predicates" ; x ]
  and q = "query"
  in
  let cmd =
    Cmd.(v "ocamlfind" % q %% flag %% format %% of_list predicate %% of_list libs)
  in
  OS.Cmd.run_out cmd |> OS.Cmd.out_lines >>| fst

(* This is to check that entropy is a dependency if "tls" is in
   the package array. *)
let enable_entropy, is_entropy_enabled =
  let r = ref false in
  let f () = r := true in
  let g () = !r in
  (f, g)

let check_entropy libs =
  query_ocamlfind ~recursive:true libs >>= fun ps ->
  if List.mem "nocrypto" ps && not (is_entropy_enabled ()) then
    R.error_msg
      {___|The \"nocrypto\" library is loaded but entropy is not enabled!@ \
       Please enable the entropy by adding a dependency to the nocrypto \
       device. You can do so by adding ~deps:[abstract nocrypto] \
       to the arguments of Mirage.foreign.|___}
  else
    R.ok ()

let nocrypto = impl @@ object
    inherit base_configurable
    method ty = job
    method name = "nocrypto"
    method module_name = "Nocrypto_entropy"
    method! packages =
      Key.match_ Key.(value target) @@ function
      | `Xen | `Qubes ->
        [ package ~min:"0.5.4" ~sublibs:["mirage"] "nocrypto";
          package ~ocamlfind:[] "zarith-xen" ]
      | `Virtio | `Ukvm | `Muen ->
        [ package ~min:"0.5.4" ~sublibs:["mirage"] "nocrypto";
          package ~ocamlfind:[] "zarith-freestanding" ]
      | `Unix | `MacOSX ->
        [ package ~min:"0.5.4" ~sublibs:["lwt"] "nocrypto" ]

    method! build _ = R.ok (enable_entropy ())
    method! connect i _ _ =
      match get_target i with
      | `Xen | `Qubes | `Virtio | `Ukvm | `Muen -> "Nocrypto_entropy_mirage.initialize ()"
      | `Unix | `MacOSX -> "Nocrypto_entropy_lwt.initialize ()"
  end

let nocrypto_random_conf = object
  inherit base_configurable
  method ty = random
  method name = "random"
  method module_name = "Nocrypto.Rng"
  method! packages = Key.pure [ package ~min:"0.5.4" "nocrypto" ]
  method! deps = [abstract nocrypto]
end

let nocrypto_random = impl nocrypto_random_conf

let default_random =
  match_impl (Key.value @@ Key.prng ()) [
    `Stdlib  , stdlib_random;
    `Nocrypto, nocrypto_random;
  ] ~default:stdlib_random

type console = CONSOLE
let console = Type CONSOLE

let console_unix str = impl @@ object
    inherit base_configurable
    method ty = console
    val name = Name.ocamlify @@ "console_unix_" ^ str
    method name = name
    method module_name = "Console_unix"
    method! packages = Key.pure [ package ~min:"2.2.0" "mirage-console-unix" ]
    method! connect _ modname _args = Fmt.strf "%s.connect %S" modname str
  end

let console_xen str = impl @@ object
    inherit base_configurable
    method ty = console
    val name = Name.ocamlify @@ "console_xen_" ^ str
    method name = name
    method module_name = "Console_xen"
    method! packages = Key.pure [ package ~min:"2.2.0" "mirage-console-xen" ]
    method! connect _ modname _args = Fmt.strf "%s.connect %S" modname str
  end

let console_solo5 str = impl @@ object
    inherit base_configurable
    method ty = console
    val name = Name.ocamlify @@ "console_solo5_" ^ str
    method name = name
    method module_name = "Console_solo5"
    method! packages = Key.pure [ package ~min:"0.2.0" "mirage-console-solo5" ]
    method! connect _ modname _args = Fmt.strf "%s.connect %S" modname str
  end

let custom_console str =
  match_impl Key.(value target) [
    `Xen, console_xen str;
    `Qubes, console_xen str;
    `Virtio, console_solo5 str;
    `Ukvm, console_solo5 str;
    `Muen, console_solo5 str
  ] ~default:(console_unix str)

let default_console = custom_console "0"

type kv_ro = KV_RO
let kv_ro = Type KV_RO

let crunch dirname = impl @@ object
    inherit base_configurable
    method ty = kv_ro
    val name = Name.create ("static" ^ dirname) ~prefix:"static"
    method name = name
    method module_name = String.Ascii.capitalize name
    method! packages =
      Key.pure [ package "io-page"; package ~min:"2.0.0" ~build:true "crunch" ]
    method! deps = [ abstract default_io_page ]
    method! connect _ modname _ = Fmt.strf "%s.connect ()" modname
    method! build _i =
      let dir = Fpath.(v dirname) in
      let file = Fpath.(v name + "ml") in
      Bos.OS.Path.exists dir >>= function
      | true ->
        Log.info (fun m -> m "Generating: %a" Fpath.pp file);
        Bos.OS.Cmd.run Bos.Cmd.(v "ocaml-crunch" % "-o" % p file % p dir)
      | false ->
        R.error_msg (Fmt.strf "The directory %s does not exist." dirname)
    method! clean _i =
      Bos.OS.File.delete Fpath.(v name + "ml") >>= fun () ->
      Bos.OS.File.delete Fpath.(v name + "mli")
  end

let direct_kv_ro_conf dirname = impl @@ object
    inherit base_configurable
    method ty = kv_ro
    val name = Name.create ("direct" ^ dirname) ~prefix:"direct"
    method name = name
    method module_name = "Kvro_fs_unix"
    method! packages = Key.pure [ package ~min:"1.3.0" "mirage-fs-unix" ]
    method! connect i _modname _names =
      let path = Fpath.(Info.build_dir i / dirname) in
      Fmt.strf "Kvro_fs_unix.connect \"%a\"" Fpath.pp path
  end

let direct_kv_ro dirname =
  match_impl Key.(value target) [
    `Xen, crunch dirname;
    `Qubes, crunch dirname;
    `Virtio, crunch dirname;
    `Ukvm, crunch dirname;
    `Muen, crunch dirname
  ] ~default:(direct_kv_ro_conf dirname)

type block = BLOCK
let block = Type BLOCK
type block_t = { filename: string; number: int }
let all_blocks = Hashtbl.create 7

let make_block_t =
  (* NB: reserve number 0 for the boot disk *)
  let next_number = ref 1 in
  fun filename ->
    let b =
      if Hashtbl.mem all_blocks filename then
        Hashtbl.find all_blocks filename
      else begin
        let number = !next_number in
        incr next_number;
        let b = { filename; number } in
        Hashtbl.add all_blocks filename b;
        b
      end in
    b

let xen_block_packages =
  [ package ~min:"1.5.0" ~sublibs:["front"] "mirage-block-xen" ]

(* this class takes a string rather than an int as `id` to allow the user to
   pass stuff like "/dev/xvdi1", which mirage-block-xen also understands *)
class xenstore_conf id =
  let name = Name.create id ~prefix:"block" in
  object
    inherit base_configurable
    method ty = block
    method name = name
    method module_name = "Block"
    method! packages = Key.pure xen_block_packages
    method! configure i =
      match get_target i with
      | `Qubes | `Xen -> R.ok ()
      | _ -> R.error_msg "XenStore IDs are only valid ways of specifying block \
                          devices when the target is Xen or Qubes."
    method! connect _ s _ =
      Fmt.strf "%s.connect %S" s id
  end

let block_of_xenstore_id id = impl (new xenstore_conf id)

(* calculate the XenStore ID for the nth available block device.
   Taken from https://github.com/mirage/mirage-block-xen/blob/
   a64d152586c7ebc1d23c5adaa4ddd440b45a3a83/lib/device_number.ml#L64 . *)
let xenstore_id_of_index number =
        (if number < 16
         then (202 lsl 8) lor (number lsl 4)
         else (1 lsl 28)  lor (number lsl 8))

class block_conf file =
  let name = Name.create file ~prefix:"block" in
  object (self)
    inherit base_configurable
    method ty = block
    method name = name
    method module_name = "Block"
    method! packages =
      Key.match_ Key.(value target) @@ function
      | `Xen | `Qubes -> xen_block_packages
      | `Virtio | `Ukvm | `Muen -> [ package ~min:"0.2.1" "mirage-block-solo5" ]
      | `Unix | `MacOSX -> [ package ~min:"2.5.0" "mirage-block-unix" ]

    method! configure _ =
      let _block = make_block_t file in
      R.ok ()

    method private connect_name target root =
      match target with
      | `Unix | `MacOSX | `Virtio | `Ukvm | `Muen ->
        Fpath.(to_string (root / file)) (* open the file directly *)
      | `Xen | `Qubes ->
        let b = make_block_t file in
        xenstore_id_of_index b.number |> string_of_int

    method! connect i s _ =
      match get_target i with
      | `Muen -> failwith "Block devices not supported on Muen target."
      | `Unix | `MacOSX | `Virtio | `Ukvm | `Xen | `Qubes ->
        Fmt.strf "%s.connect %S" s
          (self#connect_name (get_target i) @@ Info.build_dir i)
  end

let block_of_file file = impl (new block_conf file)

class ramdisk_conf rname =
  object
    inherit base_configurable
    method ty = block
    method name = "ramdisk"
    method module_name = "Ramdisk"
    method! packages =
      Key.pure [ package "mirage-block-ramdisk" ]

    method! connect _i modname _names =
      Fmt.strf "%s.connect ~name:%S" modname rname
  end


let ramdisk rname = impl (new ramdisk_conf rname)

let generic_block ?(key = Key.value @@ Key.block ()) name =
  match_impl key [
    `XenstoreId, block_of_xenstore_id name;
    `BlockFile, block_of_file name;
    `Ramdisk, ramdisk name;
  ] ~default:(ramdisk name)

let tar_block dir =
  let name = Name.create ("tar_block" ^ dir) ~prefix:"tar_block" in
  let block_file = name ^ ".img" in
  impl @@ object
    inherit block_conf block_file as super
    method! build i =
      Bos.OS.Cmd.run Bos.Cmd.(v "tar" % "-cvf" % block_file % dir) >>= fun () ->
      super#build i
  end

let archive_conf = impl @@ object
    inherit base_configurable
    method ty = block @-> kv_ro
    method name = "archive"
    method module_name = "Tar_mirage.Make_KV_RO"
    method! packages =
      Key.pure [ package ~min:"0.8.0" "tar-mirage" ]
    method! connect _ modname = function
      | [ block ] -> Fmt.strf "%s.connect %s" modname block
      | _ -> failwith (connect_err "archive" 1)
  end

let archive block = archive_conf $ block
let archive_of_files ?(dir=".") () = archive @@ tar_block dir

type fs = FS
let fs = Type FS

let fat_conf = impl @@ object
    inherit base_configurable
    method ty = (block @-> fs)
    method! packages = Key.pure [ package ~min:"0.12.0" "fat-filesystem" ]
    method name = "fat"
    method module_name = "Fat.FS"
    method! connect _ modname l = match l with
      | [ block_name ] -> Fmt.strf "%s.connect %s" modname block_name
      | _ -> failwith (connect_err "fat" 1)
  end

let fat block = fat_conf $ block

let fat_block ?(dir=".") ?(regexp="*") () =
  let name =
    Name.(ocamlify @@ create (Fmt.strf "fat%s:%s" dir regexp) ~prefix:"fat_block")
  in
  let block_file = name ^ ".img" in
  impl @@ object
    inherit block_conf block_file as super
    method! packages =
      Key.map (List.cons (package ~min:"0.12.0" ~build:true "fat-filesystem")) super#packages
    method! build i =
      let root = Info.build_dir i in
      let file = Fmt.strf "make-%s-image.sh" name in
      let dir = Fpath.of_string dir |> R.error_msg_to_invalid_arg in
      Log.info (fun m -> m "Generating block generator script: %s" file);
      with_output ~mode:0o755 (Fpath.v file)
        (fun oc () ->
           let fmt = Format.formatter_of_out_channel oc in
           Codegen.append fmt "#!/bin/sh";
           Codegen.append fmt "";
           Codegen.append fmt "echo This uses the 'fat' command-line tool to \
                               build a simple FAT";
           Codegen.append fmt "echo filesystem image.";
           Codegen.append fmt "";
           Codegen.append fmt "FAT=$(which fat)";
           Codegen.append fmt "if [ ! -x \"${FAT}\" ]; then";
           Codegen.append fmt "  echo I couldn\\'t find the 'fat' command-line \
                               tool.";
           Codegen.append fmt "  echo Try running 'opam install fat-filesystem'";
           Codegen.append fmt "  exit 1";
           Codegen.append fmt "fi";
           Codegen.append fmt "";
           Codegen.append fmt "IMG=$(pwd)/%s" block_file;
           Codegen.append fmt "rm -f ${IMG}";
           Codegen.append fmt "cd %a" Fpath.pp (Fpath.append root dir);
           Codegen.append fmt "SIZE=$(du -s . | cut -f 1)";
           Codegen.append fmt "${FAT} create ${IMG} ${SIZE}KiB";
           Codegen.append fmt "${FAT} add ${IMG} %s" regexp;
           Codegen.append fmt "echo Created '%s'" block_file;
           R.ok ())
        "fat shell script" >>= fun () ->
      Log.info (fun m -> m "Executing block generator script: ./%s" file);
      Bos.OS.Cmd.run (Bos.Cmd.v ("./" ^ file)) >>= fun () ->
      super#build i

    method! clean i =
      let file = Fmt.strf "make-%s-image.sh" name in
      Bos.OS.File.delete (Fpath.v file) >>= fun () ->
      Bos.OS.File.delete (Fpath.v block_file) >>= fun () ->
      super#clean i
  end

let fat_of_files ?dir ?regexp () = fat @@ fat_block ?dir ?regexp ()


let kv_ro_of_fs_conf = impl @@ object
    inherit base_configurable
    method ty = fs @-> kv_ro
    method name = "kv_ro_of_fs"
    method module_name = "Mirage_fs_lwt.To_KV_RO"
    method! packages = Key.pure [ package "mirage-fs-lwt" ]
    method! connect _ modname = function
      | [ fs ] -> Fmt.strf "%s.connect %s" modname fs
      | _ -> failwith (connect_err "kv_ro_of_fs" 1)
  end

let kv_ro_of_fs x = kv_ro_of_fs_conf $ x

(** generic kv_ro. *)

let generic_kv_ro ?(key = Key.value @@ Key.kv_ro ()) dir =
  match_impl key [
    `Fat    , kv_ro_of_fs @@ fat_of_files ~dir () ;
    `Archive, archive_of_files ~dir () ;
    `Crunch , crunch dir ;
    `Direct , direct_kv_ro dir ;
  ] ~default:(direct_kv_ro dir)

(** network devices *)

type network = NETWORK
let network = Type NETWORK

let all_networks = ref []

let network_conf (intf : string Key.key) =
  let key = Key.abstract intf in
  object
    inherit base_configurable
    method ty = network
    val name = Functoria_app.Name.create "net" ~prefix:"net"
    method name = name
    method module_name = "Netif"
    method! keys = [ key ]
    method! packages =
      Key.match_ Key.(value target) @@ function
      | `Unix -> [ package ~min:"2.3.0" "mirage-net-unix" ]
      | `MacOSX -> [ package ~min:"1.3.0" "mirage-net-macosx" ]
      | `Xen -> [ package ~min:"1.7.0" "mirage-net-xen"]
      | `Qubes -> [ package ~min:"1.7.0" "mirage-net-xen" ; package ~min:"0.4" "mirage-qubes" ]
      | `Virtio | `Ukvm | `Muen -> [ package ~min:"0.2.0" "mirage-net-solo5" ]
    method! connect _ modname _ =
      Fmt.strf "%s.connect %a" modname Key.serialize_call key
    method! configure i =
      all_networks := Key.get (Info.context i) intf :: !all_networks;
      R.ok ()
  end

let netif ?group dev = impl (network_conf @@ Key.interface ?group dev)
let default_network =
  match_impl Key.(value target) [
    `Unix   , netif "tap0";
    `MacOSX , netif "tap0";
  ] ~default:(netif "0")

type dhcp = Dhcp_client
let dhcp = Type Dhcp_client

type ethernet = ETHERNET
let ethernet = Type ETHERNET

let ethernet_conf = object
  inherit base_configurable
  method ty = network @-> ethernet
  method name = "ethif"
  method module_name = "Ethif.Make"
  method! packages = Key.pure [ package ~min:"3.1.0" ~sublibs:["ethif"] "tcpip" ]
  method! connect _ modname = function
    | [ eth ] -> Fmt.strf "%s.connect %s" modname eth
    | _ -> failwith (connect_err "ethernet" 1)
end

let etif_func = impl ethernet_conf
let etif network = etif_func $ network

type arpv4 = Arpv4
let arpv4 = Type Arpv4

let arpv4_conf = object
  inherit base_configurable
  method ty = ethernet @-> mclock @-> time @-> arpv4
  method name = "arpv4"
  method module_name = "Arpv4.Make"
  method! packages = Key.pure [ package ~min:"3.0.0" ~sublibs:["arpv4"] "tcpip" ]
  method! connect _ modname = function
    | [ eth ; clock ; _time ] -> Fmt.strf "%s.connect %s %s" modname eth clock
    | _ -> failwith (connect_err "arpv4" 3)
end

let arp_func = impl arpv4_conf
let arp
    ?(clock = default_monotonic_clock)
    ?(time = default_time)
    (eth : ethernet impl) =
  arp_func $ eth $ clock $ time


let farp_conf = object
  inherit base_configurable
  method ty = ethernet @-> mclock @-> time @-> arpv4
  method name = "arp"
  method module_name = "Arp.Make"
  method! packages = Key.pure [ package ~min:"0.2.0" ~sublibs:["mirage"] "arp" ]
  method! connect _ modname = function
    | [ eth ; clock ; _time ] -> Fmt.strf "%s.connect %s %s" modname eth clock
    | _ -> failwith (connect_err "arp" 3)
end

let farp_func = impl farp_conf
let farp
    ?(clock = default_monotonic_clock)
    ?(time = default_time)
    (eth : ethernet impl) =
  farp_func $ eth $ clock $ time


type v4
type v6
type 'a ip = IP
type ipv4 = v4 ip
type ipv6 = v6 ip

let ip = Type IP
let ipv4: ipv4 typ = ip
let ipv6: ipv6 typ = ip

let meta_ipv4 ppf s =
  Fmt.pf ppf "(Ipaddr.V4.of_string_exn %S)" (Ipaddr.V4.to_string s)

type ipv4_config = {
  network : Ipaddr.V4.Prefix.t * Ipaddr.V4.t;
  gateway : Ipaddr.V4.t option;
}
(** Types for IPv4 manual configuration. *)


let pp_key fmt k = Key.serialize_call fmt (Key.abstract k)
let opt_key s = Fmt.(option @@ prefix (unit ("~"^^s^^":")) pp_key)
let opt_map f = function Some x -> Some (f x) | None -> None
let (@?) x l = match x with Some s -> s :: l | None -> l
let (@??) x y = opt_map Key.abstract x @? y

(* convenience function for linking tcpip.unix or .xen for checksums *)
let right_tcpip_library ?min ?max ?ocamlfind ~sublibs pkg =
  Key.match_ Key.(value target) @@ function
  |`MacOSX | `Unix         -> [ package ?min ?max ?ocamlfind ~sublibs:("unix"::sublibs) pkg ]
  |`Qubes  | `Xen          -> [ package ?min ?max ?ocamlfind ~sublibs:("xen"::sublibs) pkg ]
  |`Virtio | `Ukvm | `Muen -> [ package ?min ?max ?ocamlfind ~sublibs pkg ]

let ipv4_keyed_conf ?network ?gateway () = impl @@ object
    inherit base_configurable
    method ty = ethernet @-> arpv4 @-> ipv4
    method name = Name.create "ipv4" ~prefix:"ipv4"
    method module_name = "Static_ipv4.Make"
    method! packages = right_tcpip_library ~min:"3.1.0" ~sublibs:["ipv4"] "tcpip"
    method! keys = network @?? gateway @?? []
    method! connect _ modname = function
    | [ etif ; arp ] ->
      Fmt.strf
        "let (network, ip) = %a in @ \
         %s.connect@[@ ~ip ~network %a@ %s@ %s@]"
        (Fmt.option pp_key) network
        modname
        (opt_key "gateway") gateway
        etif arp
      | _ -> failwith (connect_err "ipv4 keyed" 2)
  end

let dhcp_conf = impl @@ object
    inherit base_configurable
    method ty = time @-> network @-> dhcp
    method name = "dhcp_client"
    method module_name = "Dhcp_client_mirage.Make"
    method! packages = Key.pure [ package "charrua-client-mirage" ]
    method! connect _ modname = function
      | [ _time; network ] -> Fmt.strf "%s.connect %s " modname network
      | _ -> failwith (connect_err "dhcp" 2)
  end

let ipv4_dhcp_conf = impl @@ object
    inherit base_configurable
    method ty = dhcp @-> ethernet @-> arpv4 @-> ipv4
    method name = Name.create "dhcp_ipv4" ~prefix:"dhcp_ipv4"
    method module_name = "Dhcp_ipv4.Make"
    method! packages = Key.pure [ package "charrua-client-mirage" ]
    method! connect _ modname = function
      | [ dhcp ; ethernet ; arp ] ->
        Fmt.strf "%s.connect@[@ %s@ %s@ %s@]" modname dhcp ethernet arp
      | _ -> failwith (connect_err "ipv4 dhcp" 3)
  end


let dhcp time net = dhcp_conf $ time $ net
let ipv4_of_dhcp dhcp ethif arp = ipv4_dhcp_conf $ dhcp $ ethif $ arp

let create_ipv4 ?group ?config etif arp =
  let config = match config with
  | None ->
    let network = Ipaddr.V4.Prefix.of_address_string_exn "10.0.0.2/24"
    and gateway = Some (Ipaddr.V4.of_string_exn "10.0.0.1")
    in
    { network; gateway }
  | Some config -> config
  in
  let network = Key.V4.network ?group config.network
  and gateway = Key.V4.gateway ?group config.gateway
  in
  ipv4_keyed_conf ~network ~gateway () $ etif $ arp

type ipv6_config = {
  addresses: Ipaddr.V6.t list;
  netmasks: Ipaddr.V6.Prefix.t list;
  gateways: Ipaddr.V6.t list;
}
(** Types for IP manual configuration. *)

let ipv4_qubes_conf = impl @@ object
    inherit base_configurable
    method ty = qubesdb @-> ethernet @-> arpv4 @-> ipv4
    method name = Name.create "qubes_ipv4" ~prefix:"qubes_ipv4"
    method module_name = "Qubesdb_ipv4.Make"
    method! packages = Key.pure [ package ~min:"0.5" "mirage-qubes-ipv4" ]
    method! connect _ modname = function
      | [ db ; etif; arp ] -> Fmt.strf "%s.connect %s %s %s" modname db etif arp
      | _ -> failwith (connect_err "qubes ipv4" 3)
  end

let ipv4_qubes db ethernet arp = ipv4_qubes_conf $ db $ ethernet $ arp

let ipv6_conf ?addresses ?netmasks ?gateways () = impl @@ object
    inherit base_configurable
    method ty = ethernet @-> random @-> time @-> mclock @-> ipv6
    method name = Name.create "ipv6" ~prefix:"ipv6"
    method module_name = "Ipv6.Make"
    method! packages = right_tcpip_library ~min:"3.1.0" ~sublibs:["ipv6"] "tcpip"
    method! keys = addresses @?? netmasks @?? gateways @?? []
    method! connect _ modname = function
      | [ etif ; _random ; _time ; clock ] ->
        Fmt.strf "%s.connect@[@ %a@ %a@ %a@ %s@ %s@]"
          modname
          (opt_key "ip") addresses
          (opt_key "netmask") netmasks
          (opt_key "gateways") gateways
          etif clock
      | _ -> failwith (connect_err "ipv6" 3)
  end

let create_ipv6
    ?(random = default_random)
    ?(time = default_time)
    ?(clock = default_monotonic_clock)
    ?group etif { addresses ; netmasks ; gateways } =
  let addresses = Key.V6.ips ?group addresses in
  let netmasks = Key.V6.netmasks ?group netmasks in
  let gateways = Key.V6.gateways ?group gateways in
  ipv6_conf ~addresses ~netmasks ~gateways () $ etif $ random $ time $ clock

type 'a icmp = ICMP
type icmpv4 = v4 icmp

let icmp = Type ICMP
let icmpv4: icmpv4 typ = icmp

let icmpv4_direct_conf () = object
  inherit base_configurable
  method ty : ('a ip -> 'a icmp) typ = ip @-> icmp
  method name = "icmpv4"
  method module_name = "Icmpv4.Make"
  method! packages = right_tcpip_library ~min:"3.0.0" ~sublibs:["icmpv4"] "tcpip"
  method! connect _ modname = function
    | [ ip ] -> Fmt.strf "%s.connect %s" modname ip
    | _  -> failwith (connect_err "icmpv4" 1)
end

let icmpv4_direct_func () = impl (icmpv4_direct_conf ())
let direct_icmpv4 ip = icmpv4_direct_func () $ ip

type 'a udp = UDP
type udpv4 = v4 udp
type udpv6 = v6 udp

let udp = Type UDP
let udpv4: udpv4 typ = udp
let udpv6: udpv6 typ = udp

(* Value restriction ... *)
let udp_direct_conf () = object
  inherit base_configurable
  method ty = (ip: 'a ip typ) @-> random @-> (udp: 'a udp typ)
  method name = "udp"
  method module_name = "Udp.Make"
  method! packages = right_tcpip_library ~min:"3.0.0" ~sublibs:["udp"] "tcpip"
  method! connect _ modname = function
    | [ ip; _random ] -> Fmt.strf "%s.connect %s" modname ip
    | _  -> failwith (connect_err "udp" 2)
end

(* Value restriction ... *)
let udp_direct_func () = impl (udp_direct_conf ())
let direct_udp ?(random=default_random) ip = udp_direct_func () $ ip $ random

let udpv4_socket_conf ipv4_key = object
  inherit base_configurable
  method ty = udpv4
  val name = Name.create "udpv4_socket" ~prefix:"udpv4_socket"
  method name = name
  method module_name = "Udpv4_socket"
  method! keys = [ Key.abstract ipv4_key ]
  method! packages =
    Key.(if_ is_unix) [ package ~min:"3.0.0" ~sublibs:["udpv4-socket"; "unix"]
      "tcpip" ] []
  method! configure i =
    match get_target i with
    | `Unix | `MacOSX -> R.ok ()
    | _ -> R.error_msg "UDPv4 socket not supported on non-UNIX targets."
  method! connect _ modname _ = Fmt.strf "%s.connect %a" modname pp_key ipv4_key
end

let socket_udpv4 ?group ip = impl (udpv4_socket_conf @@ Key.V4.socket ?group ip)

type 'a tcp = TCP
type tcpv4 = v4 tcp
type tcpv6 = v6 tcp

let tcp = Type TCP
let tcpv4 : tcpv4 typ = tcp
let tcpv6 : tcpv6 typ = tcp

(* Value restriction ... *)
let tcp_direct_conf () = object
  inherit base_configurable
  method ty = (ip: 'a ip typ) @-> time @-> mclock @-> random @-> (tcp: 'a tcp typ)
  method name = "tcp"
  method module_name = "Tcp.Flow.Make"
  method! packages = right_tcpip_library ~min:"3.1.0" ~sublibs:["tcp"] "tcpip"
  method! connect _ modname = function
    | [ip; _time; clock; _random] -> Fmt.strf "%s.connect %s %s" modname ip clock
    | _ -> failwith (connect_err "direct tcp" 4)
end

(* Value restriction ... *)
let tcp_direct_func () = impl (tcp_direct_conf ())

let direct_tcp
    ?(clock=default_monotonic_clock)
    ?(random=default_random)
    ?(time=default_time) ip =
  tcp_direct_func () $ ip $ time $ clock $ random

let tcpv4_socket_conf ipv4_key = object
  inherit base_configurable
  method ty = tcpv4
  val name = Name.create "tcpv4_socket" ~prefix:"tcpv4_socket"
  method name = name
  method module_name = "Tcpv4_socket"
  method! keys = [ Key.abstract ipv4_key ]
  method! packages =
Key.(if_ is_unix) [ package ~min:"3.0.0" ~sublibs:["tcpv4-socket"; "unix"] "tcpip" ] []
  method! configure i =
    match get_target i with
    | `Unix | `MacOSX -> R.ok ()
    | _  -> R.error_msg "TCPv4 socket not supported on non-UNIX targets."
  method! connect _ modname _ = Fmt.strf "%s.connect %a" modname pp_key ipv4_key
end

let socket_tcpv4 ?group ip = impl (tcpv4_socket_conf @@ Key.V4.socket ?group ip)

type stackv4 = STACKV4
let stackv4 = Type STACKV4

let add_suffix s ~suffix = if suffix = "" then s else s^"_"^suffix

let stackv4_direct_conf ?(group="") () = impl @@ object
    inherit base_configurable
    method ty =
      time @-> random @-> network @->
      ethernet @-> arpv4 @-> ipv4 @-> icmpv4 @-> udpv4 @-> tcpv4 @->
      stackv4
    val name = add_suffix "stackv4_" ~suffix:group
    method name = name
    method module_name = "Tcpip_stack_direct.Make"
    method! packages = Key.pure [ package ~min:"3.0.0" ~sublibs:["stack-direct"] "tcpip" ]
    method! connect _i modname = function
      | [ _t; _r; interface; ethif; arp; ip; icmp; udp; tcp ] ->
        Fmt.strf
          "@[<2>let config = {Mirage_stack_lwt.@ \
           name = %S;@ \
           interface = %s;}@]@ in@ \
           %s.connect config@ %s %s %s %s %s %s"
          name interface modname ethif arp ip icmp udp tcp
      | _ -> failwith (connect_err "direct stackv4" 9)
  end

let direct_stackv4
    ?(clock=default_monotonic_clock)
    ?(random=default_random)
    ?(time=default_time)
    ?group
    network eth arp ip =
  stackv4_direct_conf ?group ()
  $ time $ random $ network
  $ eth $ arp $ ip
  $ direct_icmpv4 ip
  $ direct_udp ~random ip
  $ direct_tcp ~clock ~random ~time ip

let dhcp_ipv4_stack ?group ?(time = default_time) ?(arp = arp ?clock:None ?time:None) tap =
  let config = dhcp time tap in
  let e = etif tap in
  let a = arp e in
  let i = ipv4_of_dhcp config e a in
  direct_stackv4 ?group tap e a i

let static_ipv4_stack ?group ?config ?(arp = arp ?clock:None ?time:None) tap =
  let e = etif tap in
  let a = arp e in
  let i = create_ipv4 ?group ?config e a in
  direct_stackv4 ?group tap e a i

let qubes_ipv4_stack ?group ?(qubesdb = default_qubesdb) ?(arp = arp ?clock:None ?time:None) tap =
  let e = etif tap in
  let a = arp e in
  let i = ipv4_qubes qubesdb e a in
  direct_stackv4 ?group tap e a i

let stackv4_socket_conf ?(group="") interfaces = impl @@ object
    inherit base_configurable
    method ty = stackv4
    val name = add_suffix "stackv4_socket" ~suffix:group
    method name = name
    method module_name = "Tcpip_stack_socket"
    method! keys = [ Key.abstract interfaces ]
    method! packages = Key.pure [ package ~min:"3.0.0" ~sublibs:["stack-socket"; "unix"] "tcpip" ]
    method! deps = [abstract (socket_udpv4 None); abstract (socket_tcpv4 None)]
    method! connect _i modname = function
      | [ udpv4 ; tcpv4 ] ->
        Fmt.strf
          "let config =@[@ \
           { Mirage_stack_lwt.name = %S;@ \
           interface = %a ;}@] in@ \
           %s.connect config %s %s"
          name pp_key interfaces modname udpv4 tcpv4
      | _ -> failwith (connect_err "socket stack" 2)
  end

let socket_stackv4 ?group ipv4s =
  stackv4_socket_conf ?group (Key.V4.interfaces ?group ipv4s)

(** Generic stack *)

let generic_stackv4
    ?group ?config
    ?(dhcp_key = Key.value @@ Key.dhcp ?group ())
    ?(net_key = Key.value @@ Key.net ?group ())
    (tap : network impl) : stackv4 impl =
  let eq a b = Key.(pure ((=) a) $ b) in
  let choose qubes socket dhcp =
    if qubes then `Qubes
    else if socket then `Socket
    else if dhcp then `Dhcp
    else `Static
  in
  let p = Functoria_key.((pure choose)
          $ eq `Qubes Key.(value target)
          $ eq `Socket net_key
          $ eq true dhcp_key) in
  match_impl p [
    `Dhcp, dhcp_ipv4_stack ?group tap;
    `Socket, socket_stackv4 ?group [Ipaddr.V4.any];
    `Qubes, qubes_ipv4_stack ?group tap;
  ] ~default:(static_ipv4_stack ?config ?group tap)

type conduit_connector = Conduit_connector
let conduit_connector = Type Conduit_connector

let tcp_conduit_connector = impl @@ object
    inherit base_configurable
    method ty = stackv4 @-> conduit_connector
    method name = "tcp_conduit_connector"
    method module_name = "Conduit_mirage.With_tcp"
    method! packages =
      Key.pure [
        package ~min:"3.0.1" "mirage-conduit";
      ]
    method! connect _ modname = function
      | [ stack ] -> Fmt.strf "Lwt.return (%s.connect %s)@;" modname stack
      | _ -> failwith (connect_err "tcp conduit" 1)
  end

let tls_conduit_connector = impl @@ object
    inherit base_configurable
    method ty = conduit_connector
    method name = "tls_conduit_connector"
    method module_name = "Conduit_mirage"
    method! packages =
      Key.pure [
        package ~min:"0.8.0" ~sublibs:["mirage"] "tls" ;
        package "mirage-flow-lwt";
        package "mirage-kv-lwt";
        package "mirage-clock";
        package ~min:"3.0.1" "mirage-conduit" ;
      ]
    method! deps = [ abstract nocrypto ]
    method! connect _ _ _ = "Lwt.return Conduit_mirage.with_tls"
  end

type conduit = Conduit
let conduit = Type Conduit

let conduit_with_connectors connectors = impl @@ object
    inherit base_configurable
    method ty = conduit
    method name = Name.create "conduit" ~prefix:"conduit"
    method module_name = "Conduit_mirage"
    method! packages =
      Key.pure [
        package ~min:"3.0.1" "mirage-conduit";
      ]
    method! deps = abstract nocrypto :: List.map abstract connectors

    method! connect _i _ = function
      (* There is always at least the nocrypto device *)
      | _nocrypto :: connectors ->
        let pp_connector = Fmt.fmt "%s >>=@ " in
        let pp_connectors = Fmt.list ~sep:Fmt.nop pp_connector in
        Fmt.strf
          "Lwt.return Conduit_mirage.empty >>=@ \
           %a\
           fun t -> Lwt.return t"
          pp_connectors connectors
      | [] -> failwith "The conduit with connectors expects at least one argument"
  end

let conduit_direct ?(tls=false) s =
  (* TCP must be before tls in the list. *)
  let connectors = [tcp_conduit_connector $ s] in
  let connectors =
    if tls then
      connectors @ [tls_conduit_connector]
    else
      connectors
  in
  conduit_with_connectors connectors

type resolver = Resolver
let resolver = Type Resolver

let resolver_unix_system = impl @@ object
    inherit base_configurable
    method ty = resolver
    method name = "resolver_unix"
    method module_name = "Resolver_lwt"
    method! packages =
      Key.(if_ is_unix)
        [ package ~min:"3.1.0" ~ocamlfind:[] "mirage-conduit" ;
          package ~min:"1.0.0" "conduit-lwt-unix"; ]
        []
    method! configure i =
      match get_target i with
      | `Unix | `MacOSX -> R.ok ()
      | _ -> R.error_msg "Unix resolver not supported on non-UNIX targets."
    method! connect _ _modname _ = "Lwt.return Resolver_lwt_unix.system"
  end

let resolver_dns_conf ~ns ~ns_port = impl @@ object
    inherit base_configurable
    method ty = time @-> stackv4 @-> resolver
    method name = "resolver"
    method module_name = "Resolver_mirage.Make_with_stack"
    method! packages =
      Key.pure [
        package ~min:"3.0.1" "mirage-conduit" ;
      ]
    method! connect _ modname = function
      | [ _t ; stack ] ->
        let meta_ns = Fmt.Dump.option meta_ipv4 in
        let meta_port = Fmt.(Dump.option int) in
        Fmt.strf
          "let ns = %a in@;\
           let ns_port = %a in@;\
           let res = %s.R.init ?ns ?ns_port ~stack:%s () in@;\
           Lwt.return res@;"
          meta_ns ns meta_port ns_port modname stack
      | _ -> failwith (connect_err "resolver" 2)
  end

let resolver_dns ?ns ?ns_port ?(time = default_time) stack =
  resolver_dns_conf ~ns ~ns_port $ time $ stack


type syslog_config = {
  hostname : string;
  server   : Ipaddr.V4.t option;
  port     : int option;
  truncate : int option;
}

let syslog_config ?port ?truncate ?server hostname = {
  hostname ; server ; port ; truncate
}

let default_syslog_config =
  let hostname = "no_name"
  and server = None
  and port = None
  and truncate = None
  in
  { hostname ; server ; port ; truncate }

type syslog = SYSLOG
let syslog = Type SYSLOG

let opt p s = Fmt.(option @@ prefix (unit ("~"^^s^^":")) p)
let opt_int = opt Fmt.int
let opt_string = opt (fun pp v -> Format.fprintf pp "%S" v)

let syslog_udp_conf config =
  let endpoint = Key.syslog config.server
  and port = Key.syslog_port config.port
  and hostname = Key.syslog_hostname config.hostname
  in
  impl @@ object
    inherit base_configurable
    method ty = console @-> pclock @-> stackv4 @-> syslog
    method name = "udp_syslog"
    method module_name = "Logs_syslog_mirage.Udp"
    method! packages = Key.pure [ package ~min:"0.1.0" ~sublibs:["mirage"] "logs-syslog" ]
    method! keys = [ Key.abstract endpoint ; Key.abstract hostname ; Key.abstract port ]
    method! connect _i modname = function
      | [ console ; pclock ; stack ] ->
        Fmt.strf
          "@[<v 2>\
           match %a with@ \
           | None -> Lwt.return_unit@ \
           | Some server ->@ \
             let port = %a in@ \
             let reporter =@ \
               %s.create %s %s %s ~hostname:%a ?port server %a ()@ \
             in@ \
             Logs.set_reporter reporter;@ \
             Lwt.return_unit@]"
          pp_key endpoint
          pp_key port
          modname console pclock stack
          pp_key hostname
          (opt_int "truncate") config.truncate
      | _ -> failwith (connect_err "syslog udp" 3)
  end

let syslog_udp ?(config = default_syslog_config) ?(console = default_console) ?(clock = default_posix_clock) stack =
  syslog_udp_conf config $ console $ clock $ stack

let syslog_tcp_conf config =
  let endpoint = Key.syslog config.server
  and port = Key.syslog_port config.port
  and hostname = Key.syslog_hostname config.hostname
  in
  impl @@ object
    inherit base_configurable
    method ty = console @-> pclock @-> stackv4 @-> syslog
    method name = "tcp_syslog"
    method module_name = "Logs_syslog_mirage.Tcp"
    method! packages = Key.pure [ package ~min:"0.1.0" ~sublibs:["mirage"] "logs-syslog" ]
    method! keys = [ Key.abstract endpoint ; Key.abstract hostname ; Key.abstract port ]
    method! connect _i modname = function
      | [ console ; pclock ; stack ] ->
        Fmt.strf
          "@[<v 2>\
           match %a with@ \
           | None -> Lwt.return_unit@ \
           | Some server ->@ \
             let port = %a in@ \
             %s.create %s %s %s ~hostname:%a ?port server %a () >>= function@ \
             | Ok reporter -> Logs.set_reporter reporter; Lwt.return_unit@ \
             | Error e -> invalid_arg e@]"
          pp_key endpoint
          pp_key port
          modname console pclock stack
          pp_key hostname
          (opt_int "truncate") config.truncate
      | _ -> failwith (connect_err "syslog tcp" 3)
  end

let syslog_tcp ?(config = default_syslog_config) ?(console = default_console) ?(clock = default_posix_clock) stack =
  syslog_tcp_conf config $ console $ clock $ stack

let syslog_tls_conf ?keyname config =
  let endpoint = Key.syslog config.server
  and port = Key.syslog_port config.port
  and hostname = Key.syslog_hostname config.hostname
  in
  impl @@ object
    inherit base_configurable
    method ty = console @-> pclock @-> stackv4 @-> kv_ro @-> syslog
    method name = "tls_syslog"
    method module_name = "Logs_syslog_mirage_tls.Tls"
    method! packages = Key.pure [ package ~min:"0.1.0" ~sublibs:["mirage" ; "mirage.tls"] "logs-syslog" ]
    method! keys = [ Key.abstract endpoint ; Key.abstract hostname ; Key.abstract port ]
    method! connect _i modname = function
      | [ console ; pclock ; stack ; kv ] ->
        Fmt.strf
          "@[<v 2>\
           match %a with@ \
           | None -> Lwt.return_unit@ \
           | Some server ->@ \
             let port = %a in@ \
             %s.create %s %s %s %s ~hostname:%a ?port server %a %a () >>= function@ \
             | Ok reporter -> Logs.set_reporter reporter; Lwt.return_unit@ \
             | Error e -> invalid_arg e@]"
          pp_key endpoint
          pp_key port
          modname console pclock stack kv
          pp_key hostname
          (opt_int "truncate") config.truncate
          (opt_string "keyname") keyname
      | _ -> failwith (connect_err "syslog tls" 4)
  end

let syslog_tls ?(config = default_syslog_config) ?keyname ?(console = default_console) ?(clock = default_posix_clock) stack kv =
  syslog_tls_conf ?keyname config $ console $ clock $ stack $ kv


type http = HTTP
let http = Type HTTP

let http_server conduit = impl @@ object
    inherit base_configurable
    method ty = http
    method name = "http"
    method module_name = "Cohttp_mirage.Server_with_conduit"
    method! packages = Key.pure [ package ~min:"1.0.0" "cohttp-mirage" ]
    method! deps = [ abstract conduit ]
    method! connect _i modname = function
      | [ conduit ] -> Fmt.strf "%s.connect %s" modname conduit
      | _ -> failwith (connect_err "http" 1)
  end

(** Argv *)

let argv_unix = impl @@ object
    inherit base_configurable
    method ty = Functoria_app.argv
    method name = "argv_unix"
    method module_name = "OS.Env"
    method! connect _ _ _ = "OS.Env.argv ()"
  end

let argv_solo5 = impl @@ object
    inherit base_configurable
    method ty = Functoria_app.argv
    method name = "argv_solo5"
    method module_name = "Bootvar"
    method! packages = Key.pure [ package ~min:"0.2.0" "mirage-bootvar-solo5" ]
    method! connect _ _ _ = "Bootvar.argv ()"
  end

let no_argv = impl @@ object
    inherit base_configurable
    method ty = Functoria_app.argv
    method name = "argv_empty"
    method module_name = "Mirage_runtime"
    method! connect _ _ _ = "Lwt.return [|\"\"|]"
  end

let argv_xen = impl @@ object
    inherit base_configurable
    method ty = Functoria_app.argv
    method name = "argv_xen"
    method module_name = "Bootvar"
    method! packages = Key.pure [ package ~min:"0.4.0" "mirage-bootvar-xen" ]
    method! connect _ _ _ = Fmt.strf
      (* Some hypervisor configurations try to pass some extra arguments.
       * They means well, but we can't do much with them,
       * and they cause Functoria to abort. *)
      "let filter (key, _) = List.mem key (List.map snd Key_gen.runtime_keys) in@ \
       Bootvar.argv ~filter ()"
  end

let default_argv =
  match_impl Key.(value target) [
    `Xen, argv_xen;
    `Qubes, argv_xen;
    `Virtio, argv_solo5;
    `Ukvm, argv_solo5;
    `Muen, argv_solo5
  ] ~default:argv_unix

(** Log reporting *)

type reporter = job
let reporter = job

let pp_level ppf = function
  | Logs.Error    -> Fmt.string ppf "Logs.Error"
  | Logs.Warning  -> Fmt.string ppf "Logs.Warning"
  | Logs.Info     -> Fmt.string ppf "Logs.Info"
  | Logs.Debug    -> Fmt.string ppf "Logs.Debug"
  | Logs.App      -> Fmt.string ppf "Logs.App"

let mirage_log ?ring_size ~default =
  let logs = Key.logs in
  impl @@ object
    inherit base_configurable
    method ty = pclock @-> reporter
    method name = "mirage_logs"
    method module_name = "Mirage_logs.Make"
    method! packages = Key.pure [ package ~min:"0.3.0" "mirage-logs"]
    method! keys = [ Key.abstract logs ]
    method! connect _ modname = function
      | [ pclock ] ->
        Fmt.strf
          "@[<v 2>\
           let ring_size = %a in@ \
           let reporter = %s.create ?ring_size %s in@ \
           Mirage_runtime.set_level ~default:%a %a;@ \
           %s.set_reporter reporter;@ \
           Lwt.return reporter"
          Fmt.(Dump.option int) ring_size
          modname pclock
          pp_level default
          pp_key logs
          modname
    | _ -> failwith (connect_err "log" 1)
  end

let default_reporter
    ?(clock=default_posix_clock) ?ring_size ?(level=Logs.Info) () =
  mirage_log ?ring_size ~default:level $ clock

let no_reporter = impl @@ object
    inherit base_configurable
    method ty = reporter
    method name = "no_reporter"
    method module_name = "Mirage_runtime"
    method! connect _ _ _ = "assert false"
  end

(** Tracing *)

type tracing = job
let tracing = job

let mprof_trace ~size () =
  let unix_trace_file = "trace.ctf" in
  let key = Key.tracing_size size in
  impl @@ object
    inherit base_configurable
    method ty = job
    method name = "mprof_trace"
    method module_name = "MProf"
    method! keys = [ Key.abstract key ]
    method! packages =
      Key.match_ Key.(value target) @@ function
      | `Xen | `Qubes -> [ package "mirage-profile"; package "mirage-profile-xen" ]
      | `Virtio | `Ukvm | `Muen -> []
      | `Unix | `MacOSX -> [ package "mirage-profile"; package "mirage-profile-unix" ]
    method! build _ =
      match query_ocamlfind ["lwt.tracing"] with
      | Error _ | Ok [] ->
        R.error_msg "lwt.tracing module not found. Hint:\
                     opam pin add lwt https://github.com/mirage/lwt.git#tracing"
      | Ok _ -> Ok ()
    method! connect i _ _ = match get_target i with
      | `Virtio | `Ukvm | `Muen -> failwith  "tracing is not currently implemented for solo5 targets"
      | `Unix | `MacOSX ->
        Fmt.strf
          "Lwt.return ())@.\
           let () = (@ \
           @[<v 2> let buffer = MProf_unix.mmap_buffer ~size:%a %S in@ \
           let trace_config = MProf.Trace.Control.make buffer MProf_unix.timestamper in@ \
           MProf.Trace.Control.start trace_config@]"
          Key.serialize_call (Key.abstract key)
          unix_trace_file;
      | `Xen | `Qubes ->
        Fmt.strf
          "Lwt.return ())@.\
           let () = (@ \
           @[<v 2> let trace_pages = MProf_xen.make_shared_buffer ~size:%a in@ \
           let buffer = trace_pages |> Io_page.to_cstruct |> Cstruct.to_bigarray in@ \
           let trace_config = MProf.Trace.Control.make buffer MProf_xen.timestamper in@ \
           MProf.Trace.Control.start trace_config;@ \
           MProf_xen.share_with (module Gnt.Gntshr) (module OS.Xs) ~domid:0 trace_pages@ \
           |> OS.Main.run@]"
          Key.serialize_call (Key.abstract key)
  end

(** Functoria devices *)

type info = Functoria_app.info
let noop = Functoria_app.noop
let info = Functoria_app.info
let app_info = Functoria_app.app_info ~type_modname:"Mirage_info" ()

let configure_main_libvirt_xml ~root ~name =
  let open Codegen in
  let file = Fpath.(v (name ^  "_libvirt") + "xml") in
  with_output file
    (fun oc () ->
       let fmt = Format.formatter_of_out_channel oc in
       append fmt "<!-- %s -->" (generated_header ());
       append fmt "<domain type='xen'>";
       append fmt "    <name>%s</name>" name;
       append fmt "    <memory unit='KiB'>262144</memory>";
       append fmt "    <currentMemory unit='KiB'>262144</currentMemory>";
       append fmt "    <vcpu placement='static'>1</vcpu>";
       append fmt "    <os>";
       append fmt "        <type arch='armv7l' machine='xenpv'>linux</type>";
       append fmt "        <kernel>%s/%s.xen</kernel>" root name;
       append fmt "        <cmdline> </cmdline>";
       (* the libxl driver currently needs an empty cmdline to be able to
           start the domain on arm - due to this?
           http://lists.xen.org/archives/html/xen-devel/2014-02/msg02375.html *)
       append fmt "    </os>";
       append fmt "    <clock offset='utc' adjustment='reset'/>";
       append fmt "    <on_crash>preserve</on_crash>";
       append fmt "    <!-- ";
       append fmt "    You must define network and block interfaces manually.";
       append fmt "    See http://libvirt.org/drvxen.html for information about \
                   converting .xl-files to libvirt xml automatically.";
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
       R.ok ())
    "libvirt.xml"

let configure_virtio_libvirt_xml ~root ~name =
  let open Codegen in
  let file = Fpath.(v (name ^  "_libvirt") + "xml") in
  with_output file
    (fun oc () ->
      let fmt = Format.formatter_of_out_channel oc in
      append fmt "<!-- %s -->" (generated_header ());
      append fmt "<domain type='kvm'>";
      append fmt "    <name>%s</name>" name;
      append fmt "    <memory unit='KiB'>262144</memory>";
      append fmt "    <currentMemory unit='KiB'>262144</currentMemory>";
      append fmt "    <vcpu placement='static'>1</vcpu>";
      append fmt "    <os>";
      append fmt "        <type arch='x86_64' machine='pc'>hvm</type>";
      append fmt "        <kernel>%s/%s.virtio</kernel>" root name;
      append fmt "        <!-- Command line arguments can be given if required:";
      append fmt "        <cmdline>-l *:debug</cmdline>";
      append fmt "        -->";
      append fmt "    </os>";
      append fmt "    <clock offset='utc' adjustment='reset'/>";
      append fmt "    <devices>";
      append fmt "        <emulator>/usr/bin/qemu-system-x86_64</emulator>";
      append fmt "        <!--";
      append fmt "        Disk/block configuration reference is here:";
      append fmt "        https://libvirt.org/formatdomain.html#elementsDisks";
      append fmt "        This example uses a raw file on the host as a block in the guest:";
      append fmt "        <disk type='file' device='disk'>";
      append fmt "            <driver name='qemu' type='raw'/>";
      append fmt "            <source file='/var/lib/libvirt/images/%s.img'/>" name;
      append fmt "            <target dev='vda' bus='virtio'/>";
      append fmt "        </disk>";
      append fmt "        -->";
      append fmt "        <!-- ";
      append fmt "        Network configuration reference is here:";
      append fmt "        https://libvirt.org/formatdomain.html#elementsNICS";
      append fmt "        This example adds a device in the 'default' libvirt bridge:";
      append fmt "        <interface type='bridge'>";
      append fmt "            <source bridge='virbr0'/>";
      append fmt "            <model type='virtio'/>";
      append fmt "            <alias name='0'/>";
      append fmt "        </interface>";
      append fmt "        -->";
      append fmt "        <serial type='pty'>";
      append fmt "            <target port='0'/>";
      append fmt "        </serial>";
      append fmt "        <console type='pty'>";
      append fmt "            <target type='serial' port='0'/>";
      append fmt "        </console>";
      append fmt "        <memballoon model='none'/>";
      append fmt "    </devices>";
      append fmt "</domain>";
      R.ok ())
    "libvirt.xml"

let clean_main_libvirt_xml ~name =
  Bos.OS.File.delete Fpath.(v (name ^ "_libvirt") + "xml")

(* We generate an example .xl with common defaults, and a generic
   .xl.in which has @VARIABLES@ which must be substituted by sed
   according to the preferences of the system administrator.

   The common defaults chosen for the .xl file will be based on values
   detected from the build host. We assume that the .xl file will
   mainly be used by developers where build and deployment are on the
   same host. Production users should use the .xl.in and perform the
   appropriate variable substition.
*)

let detected_bridge_name =
  (* Best-effort guess of a bridge name stem to use. Note this
     inspects the build host and will probably be wrong if the
     deployment host is different.  *)
  match
    List.fold_left (fun sofar x ->
        match sofar with
        (* This is Linux-specific *)
        | None when Sys.file_exists (Fmt.strf "/sys/class/net/%s0" x) -> Some x
        | None -> None
        | Some x -> Some x)
      None [ "xenbr"; "br"; "virbr" ]
  with
  | Some x -> x
  | None -> "br"

module Substitutions = struct
  type v =
    | Name
    | Kernel
    | Memory
    | Block of block_t
    | Network of string

  let string_of_v = function
    | Name -> "@NAME@"
    | Kernel -> "@KERNEL@"
    | Memory -> "@MEMORY@"
    | Block b -> Fmt.strf "@BLOCK:%s@" b.filename
    | Network n -> Fmt.strf "@NETWORK:%s@" n

  let lookup ts v =
    if List.mem_assoc v ts then
      List.assoc v ts
    else
      string_of_v v

  let defaults i =
    let blocks =
      List.map (fun b -> Block b, Fpath.(to_string ((Info.build_dir i) / b.filename)))
        (Hashtbl.fold (fun _ v acc -> v :: acc) all_blocks [])
    and networks =
      List.mapi (fun i n -> Network n, Fmt.strf "%s%d" detected_bridge_name i)
        !all_networks
    in [
      Name, (Info.name i);
      Kernel, Fpath.(to_string ((Info.build_dir i) / (Info.name i) + "xen"));
      Memory, "256";
    ] @ blocks @ networks
end

let configure_main_xl ?substitutions ext i =
  let open Substitutions in
  let substitutions = match substitutions with
    | Some x -> x
    | None -> defaults i in
  let file = Fpath.(v (Info.name i) + ext) in
  let open Codegen in
  with_output file (fun oc () ->
      let fmt = Format.formatter_of_out_channel oc in
      append fmt "# %s" (generated_header ()) ;
      newline fmt;
      append fmt "name = '%s'" (lookup substitutions Name);
      append fmt "kernel = '%s'" (lookup substitutions Kernel);
      append fmt "builder = 'linux'";
      append fmt "memory = %s" (lookup substitutions Memory);
      append fmt "on_crash = 'preserve'";
      newline fmt;
      let blocks = List.map
          (fun b ->
             (* We need the Linux version of the block number (this is a
                strange historical artifact) Taken from
                https://github.com/mirage/mirage-block-xen/blob/
                a64d152586c7ebc1d23c5adaa4ddd440b45a3a83/lib/device_number.ml#L128 *)
             let rec string_of_int26 x =
               let high, low = x / 26 - 1, x mod 26 + 1 in
               let high' = if high = -1 then "" else string_of_int26 high in
               let low' =
                 String.v ~len:1
                   (fun _ -> char_of_int (low + (int_of_char 'a') - 1))
               in
               high' ^ low' in
             let vdev = Fmt.strf "xvd%s" (string_of_int26 b.number) in
             let path = lookup substitutions (Block b) in
             Fmt.strf "'format=raw, vdev=%s, access=rw, target=%s'" vdev path)
          (Hashtbl.fold (fun _ v acc -> v :: acc) all_blocks [])
      in
      append fmt "disk = [ %s ]" (String.concat ~sep:", " blocks);
      newline fmt;
      let networks = List.map (fun n ->
          Fmt.strf "'bridge=%s'" (lookup substitutions (Network n)))
          !all_networks
      in
      append fmt "# if your system uses openvswitch then either edit \
                  /etc/xen/xl.conf and set";
      append fmt "#     vif.default.script=\"vif-openvswitch\"";
      append fmt "# or add \"script=vif-openvswitch,\" before the \"bridge=\" \
                  below:";
      append fmt "vif = [ %s ]" (String.concat ~sep:", " networks);
      R.ok ())
    "xl file"

let clean_main_xl ~name ext = Bos.OS.File.delete Fpath.(v name + ext)

let configure_main_xe ~root ~name =
  let open Codegen in
  let file = Fpath.(v name + "xe") in
  with_output ~mode:0o755 file (fun oc () ->
      let fmt = Format.formatter_of_out_channel oc in
      append fmt "#!/bin/sh";
      append fmt "# %s" (generated_header ());
      newline fmt;
      append fmt "set -e";
      newline fmt;
      append fmt "# Dependency: xe";
      append fmt "command -v xe >/dev/null 2>&1 || { echo >&2 \"I require xe but \
                  it's not installed.  Aborting.\"; exit 1; }";
      append fmt "# Dependency: xe-unikernel-upload";
      append fmt "command -v xe-unikernel-upload >/dev/null 2>&1 || { echo >&2 \"I \
                  require xe-unikernel-upload but it's not installed.  Aborting.\"\
                  ; exit 1; }";
      append fmt "# Dependency: a $HOME/.xe";
      append fmt "if [ ! -e $HOME/.xe ]; then";
      append fmt "  echo Please create a config file for xe in $HOME/.xe which \
                  contains:";
      append fmt "  echo server='<IP or DNS name of the host running xapi>'";
      append fmt "  echo username=root";
      append fmt "  echo password=password";
      append fmt "  exit 1";
      append fmt "fi";
      newline fmt;
      append fmt "echo Uploading VDI containing unikernel";
      append fmt "VDI=$(xe-unikernel-upload --path %s/%s.xen)" root name;
      append fmt "echo VDI=$VDI";
      append fmt "echo Creating VM metadata";
      append fmt "VM=$(xe vm-create name-label=%s)" name;
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
          append fmt "SIZE=$(stat --format '%%s' %s/%s)" root b.filename;
          append fmt "POOL=$(xe pool-list params=uuid --minimal)";
          append fmt "SR=$(xe pool-list uuid=$POOL params=default-SR --minimal)";
          append fmt "VDI=$(xe vdi-create type=user name-label='%s' \
                      virtual-size=$SIZE sr-uuid=$SR)" b.filename;
          append fmt "xe vdi-import uuid=$VDI filename=%s/%s" root b.filename;
          append fmt "VBD=$(xe vbd-create vm-uuid=$VM vdi-uuid=$VDI device=%d)"
            b.number;
          append fmt "xe vbd-param-set uuid=$VBD other-config:owner=true")
        (Hashtbl.fold (fun _ v acc -> v :: acc) all_blocks []);
      append fmt "echo Starting VM";
      append fmt "xe vm-start uuid=$VM";
      R.ok ())
    "xe file"

let clean_main_xe ~name = Bos.OS.File.delete Fpath.(v name + "xe")

let configure_makefile ~opam_name =
  let open Codegen in
  let file = Fpath.(v "Makefile") in
  with_output file (fun oc () ->
      let fmt = Format.formatter_of_out_channel oc in
      append fmt "# %s" (generated_header ());
      newline fmt;
      append fmt "-include Makefile.user";
      newline fmt;
      append fmt "OPAM = opam\n\
                  DEPEXT ?= opam depext --yes --update %s\n\
                  \n\
                  .PHONY: all depend depends clean build\n\
                  all:: build\n\
                  \n\
                  depend depends::\n\
                  \t$(OPAM) pin add -k path --no-action --yes %s .\n\
                  \t$(DEPEXT)\n\
                  \t$(OPAM) install --yes --deps-only %s\n\
                  \t$(OPAM) pin remove --no-action %s\n\
                  \n\
                  build::\n\
                  \tmirage build\n\
                  \n\
                  clean::\n\
                  \tmirage clean\n"
        opam_name opam_name opam_name opam_name;
      R.ok ())
    "Makefile"

let clean_makefile () = Bos.OS.File.delete Fpath.(v "Makefile")

let fn = Fpath.(v "myocamlbuild.ml")

(* ocamlbuild will give a misleading hint on build failures
 * ( https://github.com/ocaml/ocamlbuild/blob/0eb62b72b5abd520484210125b18073338a634bc/src/ocaml_compiler.ml#L130 )
 * if it doesn't detect that the project is an ocamlbuild
 * project.  The only facility for hinting this is presence of
 * myocamlbuild.ml or _tags
 * ( https://github.com/ocaml/ocamlbuild/blob/0eb62b72b5abd520484210125b18073338a634bc/src/options.ml#L375-L387 )
 * so we create an empty myocamlbuild.ml . *)
let configure_myocamlbuild () =
  Bos.OS.File.exists fn >>= function
  | true -> R.ok ()
  | false -> Bos.OS.File.write fn ""

(* we made it, so we should clean it up *)
let clean_myocamlbuild () =
  match Bos.OS.Path.stat fn with
  | Ok stat when stat.Unix.st_size = 0 -> Bos.OS.File.delete fn
  | _ -> R.ok ()

let configure_opam ~name info =
  let open Codegen in
  let file = Fpath.(v name + "opam") in
  with_output file (fun oc () ->
      let fmt = Format.formatter_of_out_channel oc in
      append fmt "# %s" (generated_header ());
      Info.opam ~name fmt info;
      append fmt "maintainer: \"dummy\"";
      append fmt "authors: \"dummy\"";
      append fmt "homepage: \"dummy\"";
      append fmt "bug-reports: \"dummy\"";
      append fmt "build: [ \"mirage\" \"build\" ]";
      append fmt "available: [ ocaml-version >= \"4.03.0\" ]";
      R.ok ())
    "opam file"

let clean_opam ~name = Bos.OS.File.delete Fpath.(v name + "opam")

let unikernel_name target name =
  let target = Fmt.strf "%a" Key.pp_target target in
  String.concat ~sep:"-" ["mirage" ; "unikernel" ; name ; target]

let configure i =
  let name = Info.name i in
  let root = Fpath.to_string (Info.build_dir i) in
  let ctx = Info.context i in
  let target = Key.(get ctx target) in
  Log.info (fun m -> m "Configuring for target: %a" Key.pp_target target);
  let opam_name = unikernel_name target name in
  let target_debug = Key.(get ctx target_debug) in
  if target_debug && target <> `Ukvm then
    Log.warn (fun m -> m "-g not supported for target: %a" Key.pp_target target);
  configure_myocamlbuild () >>= fun () ->
  configure_opam ~name:opam_name i >>= fun () ->
  configure_makefile ~opam_name >>= fun () ->
  match target with
  | `Xen ->
    configure_main_xl "xl" i >>= fun () ->
    configure_main_xl ~substitutions:[] "xl.in" i >>= fun () ->
    configure_main_xe ~root ~name >>= fun () ->
    configure_main_libvirt_xml ~root ~name
  | `Virtio ->
    configure_virtio_libvirt_xml ~root ~name
  | _ -> R.ok ()

let terminal () =
  let dumb = try Sys.getenv "TERM" = "dumb" with Not_found -> true in
  let isatty = try Unix.(isatty (descr_of_out_channel Pervasives.stdout)) with
    | Unix.Unix_error _ -> false
  in
  not dumb && isatty

let compile libs warn_error target =
  let tags =
    [ Fmt.strf "predicate(%s)" (backend_predicate target);
      "warn(A-4-41-42-44)";
      "debug";
      "bin_annot";
      "strict_sequence";
      "principal";
      "safe_string" ] @
    (if warn_error then ["warn_error(+1..49)"] else []) @
    (match target with `MacOSX -> ["thread"] | _ -> []) @
    (if terminal () then ["color(always)"] else [])
  and result = match target with
    | `Unix | `MacOSX -> "main.native"
    | `Xen | `Qubes | `Virtio | `Ukvm | `Muen -> "main.native.o"
  and cflags = [ "-g" ]
  and lflags =
    let dontlink =
      match target with
      | `Xen | `Qubes | `Virtio | `Ukvm | `Muen -> ["unix"; "str"; "num"; "threads"]
      | `Unix | `MacOSX -> []
    in
    let dont = List.map (fun k -> [ "-dontlink" ; k ]) dontlink in
    "-g" :: List.flatten dont
  in
  let concat = String.concat ~sep:"," in
  let cmd = Bos.Cmd.(v "ocamlbuild" % "-use-ocamlfind" %
                     "-classic-display" %
                     "-tags" % concat tags %
                     "-pkgs" % concat libs %
                     "-cflags" % concat cflags %
                     "-lflags" % concat lflags %
                     "-tag-line" % "<static*.*>: warn(-32-34)" %
                     "-X" %  "_build-ukvm" %
                     result)
  in
  Log.info (fun m -> m "executing %a" Bos.Cmd.pp cmd);
  Bos.OS.Cmd.run cmd

(* Implement something similar to the @name/file extended names of findlib. *)
let rec expand_name ~lib param =
  match String.cut param ~sep:"@" with
  | None -> param
  | Some (prefix, name) -> match String.cut name ~sep:"/" with
    | None              -> prefix ^ Fpath.(to_string (v lib / name))
    | Some (name, rest) ->
      let rest = expand_name ~lib rest in
      prefix ^ Fpath.(to_string (v lib / name / rest))

let opam_prefix =
  let cmd = Bos.Cmd.(v "opam" % "config" % "var" % "prefix") in
  lazy (Bos.OS.Cmd.run_out cmd |> Bos.OS.Cmd.out_string >>| fst)

(* Invoke pkg-config and return output if successful. *)
let pkg_config pkgs args =
  let var = "PKG_CONFIG_PATH" in
  let pkg_config_fallback = match Bos.OS.Env.var var with
    | Some path -> ":" ^ path
    | None -> ""
  in
  Lazy.force opam_prefix >>= fun prefix ->
  (* the order here matters (at least for ancient 0.26, distributed with
       ubuntu 14.04 versions): use share before lib! *)
  let value = Fmt.strf "%s/share/pkgconfig:%s/lib/pkgconfig%s" prefix prefix pkg_config_fallback in
  Bos.OS.Env.set_var var (Some value) >>= fun () ->
  let cmd = Bos.Cmd.(v "pkg-config" % pkgs %% of_list args) in
  Bos.OS.Cmd.run_out cmd |> Bos.OS.Cmd.out_string >>| fun (data, _) ->
  String.cuts ~sep:" " ~empty:false data

(* Get the linker flags for any extra C objects we depend on.
 * This is needed when building a Xen/Solo5 image as we do the link manually. *)
let extra_c_artifacts target pkgs =
  Lazy.force opam_prefix >>= fun prefix ->
  let lib = prefix ^ "/lib" in
  let format = Fmt.strf "%%d\t%%(%s_linkopts)" target
  and predicates = "native"
  in
  query_ocamlfind ~recursive:true ~format ~predicates pkgs >>= fun data ->
  let r = List.fold_left (fun acc line ->
      match String.cut line ~sep:"\t" with
      | None -> acc
      | Some (dir, ldflags) ->
        if ldflags <> "" then begin
          let ldflags = String.cuts ldflags ~sep:" " in
          let ldflags = List.map (expand_name ~lib) ldflags in
          acc @ ("-L" ^ dir) :: ldflags
        end else
          acc
    ) [] data
  in
  R.ok r

let static_libs pkg_config_deps = pkg_config pkg_config_deps [ "--static" ; "--libs" ]

let ldflags pkg = pkg_config pkg ["--variable=ldflags"]

let ldpostflags pkg = pkg_config pkg ["--variable=ldpostflags"]

let find_ld pkg =
  match pkg_config pkg ["--variable=ld"] with
  | Ok (ld::_) ->
    Log.warn (fun m -> m "using %s as ld (pkg-config %s --variable=ld)" ld pkg) ;
    ld
  | Ok [] ->
    Log.warn (fun m -> m "pkg-config %s --variable=ld returned nothing, using ld" pkg) ;
    "ld"
  | Error msg ->
    Log.warn (fun m -> m "error %a while pkg-config %s --variable=ld, using ld"
                 Rresult.R.pp_msg msg pkg) ;
    "ld"

let solo5_pkg = function
  | `Virtio -> "solo5-kernel-virtio", ".virtio"
  | `Muen -> "solo5-kernel-muen", ".muen"
  | `Ukvm -> "solo5-kernel-ukvm", ".ukvm"
  | `Unix | `MacOSX | `Xen | `Qubes ->
    invalid_arg "solo5_kernel only defined for solo5 targets"

let link info name target target_debug =
  let libs = Info.libraries info in
  match target with
  | `Unix | `MacOSX ->
    Bos.OS.Cmd.run Bos.Cmd.(v "ln" % "-nfs" % "_build/main.native" % name) >>= fun () ->
    Ok name
  | `Xen | `Qubes ->
    extra_c_artifacts "xen" libs >>= fun c_artifacts ->
    static_libs "mirage-xen" >>= fun static_libs ->
    let linker =
      Bos.Cmd.(v "ld" % "-d" % "-static" % "-nostdlib" % "_build/main.native.o" %%
               of_list c_artifacts %% of_list static_libs)
    in
    let out = name ^ ".xen" in
    Bos.OS.Cmd.run_out Bos.Cmd.(v "uname" % "-m") |> Bos.OS.Cmd.out_string >>= fun (machine, _) ->
    if String.is_prefix ~affix:"arm" machine then begin
      (* On ARM:
         - we must convert the ELF image to an ARM boot executable zImage,
           while on x86 we leave it as it is.
         - we need to link libgcc.a (otherwise we get undefined references to:
           __aeabi_dcmpge, __aeabi_dadd, ...) *)
      Bos.OS.Cmd.run_out Bos.Cmd.(v "gcc" % "-print-libgcc-file-name") |> Bos.OS.Cmd.out_string >>= fun (libgcc, _) ->
      let elf = name ^ ".elf" in
      let link = Bos.Cmd.(linker % libgcc % "-o" % elf) in
      Log.info (fun m -> m "linking with %a" Bos.Cmd.pp link);
      Bos.OS.Cmd.run link >>= fun () ->
      Bos.OS.Cmd.run Bos.Cmd.(v "objcopy" % "-O" % "binary" % elf % out) >>= fun () ->
      Ok out
    end else begin
      let link = Bos.Cmd.(linker % "-o" % out) in
      Log.info (fun m -> m "linking with %a" Bos.Cmd.pp link);
      Bos.OS.Cmd.run link >>= fun () ->
      Ok out
    end
  | `Virtio | `Muen | `Ukvm ->
    let pkg, post = solo5_pkg target in
    extra_c_artifacts "freestanding" libs >>= fun c_artifacts ->
    static_libs "mirage-solo5" >>= fun static_libs ->
    ldflags pkg >>= fun ldflags ->
    ldpostflags pkg >>= fun ldpostflags ->
    let out = name ^ post in
    let ld = find_ld pkg in
    let linker =
      Bos.Cmd.(v ld %% of_list ldflags % "_build/main.native.o" %%
               of_list c_artifacts %% of_list static_libs % "-o" % out
               %% of_list ldpostflags)
    in
    Log.info (fun m -> m "linking with %a" Bos.Cmd.pp linker);
    Bos.OS.Cmd.run linker >>= fun () ->
    if target = `Ukvm then
      let ukvm_mods =
        List.fold_left (fun acc -> function
            | "mirage-net-solo5" -> "net" :: acc
            | "mirage-block-solo5" -> "blk" :: acc
            | _ -> acc)
          [] libs @ (if target_debug then ["gdb"] else [])
      in
      pkg_config pkg ["--variable=libdir"] >>= function
      | [ libdir ] ->
        Bos.OS.Cmd.run Bos.Cmd.(v "ukvm-configure" % (libdir ^ "/src/ukvm") %% of_list ukvm_mods) >>= fun () ->
        Bos.OS.Cmd.run Bos.Cmd.(v "make" % "-f" % "Makefile.ukvm" % "ukvm-bin") >>= fun () ->
        Ok out
      | _ -> R.error_msg ("pkg-config " ^ pkg ^ " --variable=libdir failed")
    else
      Ok out

let build i =
  let name = Info.name i in
  let ctx = Info.context i in
  let warn_error = Key.(get ctx warn_error) in
  let target = Key.(get ctx target) in
  let libs = Info.libraries i in
  let target_debug = Key.(get ctx target_debug) in
  check_entropy libs >>= fun () ->
  compile libs warn_error target >>= fun () ->
  link i name target target_debug >>| fun out ->
  Log.info (fun m -> m "Build succeeded: %s" out)

let clean i =
  let name = Info.name i in
  let ctx = Info.context i in
  let target = Key.(get ctx target) in
  clean_main_xl ~name "xl" >>= fun () ->
  clean_main_xl ~name "xl.in" >>= fun () ->
  clean_main_xe ~name >>= fun () ->
  clean_main_libvirt_xml ~name >>= fun () ->
  clean_myocamlbuild () >>= fun () ->
  clean_makefile () >>= fun () ->
  clean_opam ~name:(unikernel_name target name) >>= fun () ->
  Bos.OS.File.delete Fpath.(v "main.native.o") >>= fun () ->
  Bos.OS.File.delete Fpath.(v "main.native") >>= fun () ->
  Bos.OS.File.delete Fpath.(v name) >>= fun () ->
  Bos.OS.File.delete Fpath.(v name + "xen") >>= fun () ->
  Bos.OS.File.delete Fpath.(v name + "elf") >>= fun () ->
  Bos.OS.File.delete Fpath.(v name + "virtio") >>= fun () ->
  Bos.OS.File.delete Fpath.(v name + "muen") >>= fun () ->
  Bos.OS.File.delete Fpath.(v name + "ukvm") >>= fun () ->
  Bos.OS.File.delete Fpath.(v "Makefile.ukvm") >>= fun () ->
  Bos.OS.Dir.delete ~recurse:true Fpath.(v "_build-ukvm") >>= fun () ->
  Bos.OS.File.delete Fpath.(v "ukvm-bin")

module Project = struct
  let name = "mirage"
  let version = "%%VERSION%%"
  let prelude =
    "open Lwt.Infix\n\
     let return = Lwt.return\n\
     let run = OS.Main.run"

  (* The ocamlfind packages to use when compiling config.ml *)
  let packages = [package "mirage"]

  (* The directories to ignore when compiling config.ml *)
  let ignore_dirs = ["_build-ukvm"]

  let create jobs = impl @@ object
      inherit base_configurable
      method ty = job
      method name = "mirage"
      method module_name = "Mirage_runtime"
      method! keys = [
        Key.(abstract target);
        Key.(abstract warn_error);
        Key.(abstract target_debug);
      ]
      method! packages =
        let common = [
          (* XXX: use %%VERSION_NUM%% here instead of hardcoding a version? *)
          package "lwt";
          package ~min:"3.0.0" "mirage-types-lwt";
          package ~min:"3.0.0" "mirage-types";
          package ~min:"3.0.0" "mirage-runtime" ;
          package ~build:true "ocamlfind" ;
          package ~build:true "ocamlbuild" ;
        ] in
        Key.match_ Key.(value target) @@ function
        | `Unix | `MacOSX -> [ package ~min:"3.0.0" "mirage-unix" ] @ common
        | `Xen | `Qubes -> [ package ~min:"3.0.4" "mirage-xen" ] @ common
        | `Virtio | `Ukvm | `Muen as tgt ->
          let pkg, _ = solo5_pkg tgt in
          [ package ~min:"0.2.1" ~ocamlfind:[] pkg ;
            package ~min:"0.2.0" "mirage-solo5" ] @ common

      method! build = build
      method! configure = configure
      method! clean = clean
      method! connect _ _mod _names = "Lwt.return_unit"
      method! deps = List.map abstract jobs
    end

end

include Functoria_app.Make (Project)

(** {Custom registration} *)

let (++) acc x = match acc, x with
  | _       , None   -> acc
  | None    , Some x -> Some [x]
  | Some acc, Some x -> Some (acc @ [x])

(* TODO: ideally we'd combine these *)
let qrexec_init = match_impl Key.(value target) [
  `Qubes, qrexec_qubes;
] ~default:Functoria_app.noop

let gui_init = match_impl Key.(value target) [
  `Qubes, gui_qubes;
] ~default:Functoria_app.noop

let register
    ?(argv=default_argv) ?tracing ?(reporter=default_reporter ())
    ?keys ?packages
    name jobs =
  let argv = Some (Functoria_app.keys argv) in
  let reporter = if reporter == no_reporter then None else Some reporter in
  let qubes_init = Some [qrexec_init; gui_init] in
  let init = qubes_init ++ argv ++ reporter ++ tracing in
  register ?keys ?packages ?init name jobs
