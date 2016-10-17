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

open Rresult
open Astring

module Key = Mirage_key
module Name = Functoria_app.Name
module Cmd = Functoria_app.Cmd
module Log = Functoria_app.Log
module Codegen = Functoria_app.Codegen

include Functoria

let get_target i = Key.(get (Info.context i) target)

(** {2 Devices} *)

type io_page = IO_PAGE
let io_page = Type IO_PAGE

let io_page_conf = object
  inherit base_configurable
  method ty = io_page
  method name = "io_page"
  method module_name = "Io_page"
  method libraries =
    Key.match_ Key.(value target) @@ function
    | `Xen | `Virtio | `Ukvm -> ["io-page"]
    | `Unix | `MacOSX -> ["io-page"; "io-page.unix"]
  method packages = Key.pure [ "io-page" ]
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

let posix_clock_conf = object (self)
  inherit base_configurable
  method ty = pclock
  method name = "pclock"
  method module_name = "Pclock"
  method libraries =
    Key.(if_ is_unix) ["mirage-clock-unix"] ["mirage-clock-xen"]
  method packages = self#libraries
  method connect _ modname _args =
    Printf.sprintf "%s.connect ()" modname
end

let default_posix_clock = impl posix_clock_conf

type mclock = MCLOCK
let mclock = Type MCLOCK

let monotonic_clock_conf = object (self)
  inherit base_configurable
  method ty = mclock
  method name = "mclock"
  method module_name = "Mclock"
  method libraries =
    Key.(if_ is_unix) ["mirage-clock-unix"] ["mirage-clock-xen"]
  method packages = self#libraries
  method connect _ modname _args =
    Printf.sprintf "%s.connect ()" modname
end

let default_monotonic_clock = impl monotonic_clock_conf

type random = RANDOM
let random = Type RANDOM

let stdlib_random_conf = object
  inherit base_configurable
  method ty = random
  method name = "random"
  method module_name = "Stdlibrandom"
  method packages = Key.pure ["mirage-stdlib-random"]
  method libraries = Key.pure ["mirage-stdlib-random"]
  method connect _ modname _args =
    Printf.sprintf "Lwt.return (%s.initialize ())" modname
end

let stdlib_random = impl stdlib_random_conf


(* This is to check that entropy is a dependency if "tls" is in
   the package array. *)
let enable_entropy, is_entropy_enabled =
  let r = ref false in
  let f () = r := true in
  let g () = !r in
  (f, g)

let check_entropy libs =
  Cmd.OCamlfind.query ~recursive:true libs
  >>| List.exists ((=) "nocrypto")
  >>= fun is_needed ->
  if is_needed && not (is_entropy_enabled ()) then
    Log.error
      "The \"nocrypto\" library is loaded but entropy is not enabled!@ \
       Please enable the entropy by adding a dependency to the nocrypto \
       device. You can do so by adding ~deps:[abstract nocrypto] \
       to the arguments of Mirage.foreign."
  else R.ok ()

let nocrypto = impl @@ object
    inherit base_configurable
    method ty = job
    method name = "nocrypto"
    method module_name = "Nocrypto_entropy"

    method packages =
      Key.match_ Key.(value target) @@ function
      | `Xen ->
        ["nocrypto"; "mirage-entropy-xen"; "zarith-xen"]
      | `Virtio | `Ukvm ->
        ["nocrypto"; "mirage-entropy-solo5"; "zarith-freestanding"]
      | `Unix | `MacOSX -> ["nocrypto"]

    method libraries =
      Key.match_ Key.(value target) @@ function
      | `Xen -> ["nocrypto.xen"]
      | `Virtio | `Ukvm -> ["nocrypto.solo5"]
      | `Unix | `MacOSX -> ["nocrypto.lwt"]

    method configure _ = R.ok (enable_entropy ())
    method connect i _ _ =
      match Key.(get (Info.context i) target) with
        | `Xen | `Virtio | `Ukvm -> "Nocrypto_entropy_mirage.initialize ()"
        | `Unix | `MacOSX -> "Nocrypto_entropy_lwt.initialize ()"

  end

let nocrypto_random_conf = object
  inherit base_configurable
  method ty = random
  method name = "random"
  method module_name = "Nocrypto.Rng"
  method packages = Key.pure ["nocrypto"]
  method libraries = Key.pure ["nocrypto"]
  method deps = [abstract nocrypto]
end

let nocrypto_random = impl nocrypto_random_conf

type console = CONSOLE
let console = Type CONSOLE

let console_unix str = impl @@ object
    inherit base_configurable
    method ty = console
    val name = Name.ocamlify @@ "console_unix_" ^ str
    method name = name
    method module_name = "Console_unix"
    method packages = Key.pure ["mirage-console"; "mirage-unix"]
    method libraries = Key.pure ["mirage-console.unix"]
    method connect _ modname _args =
      Printf.sprintf "%s.connect %S" modname str
  end

let console_xen str = impl @@ object
    inherit base_configurable
    method ty = console
    val name = Name.ocamlify @@ "console_xen_" ^ str
    method name = name
    method module_name = "Console_xen"
    method packages = Key.pure
        ["mirage-console"; "xenstore"; "mirage-xen"; "xen-gnt"; "xen-evtchn"]
    method libraries = Key.pure ["mirage-console.xen"]
    method connect _ modname _args =
      Printf.sprintf "%s.connect %S" modname str
  end

let console_solo5 str = impl @@ object
    inherit base_configurable
    method ty = console
    val name = Name.ocamlify @@ "console_solo5_" ^ str
    method name = name
    method module_name = "Console_solo5"
    method packages = Key.pure ["mirage-console-solo5";]
    method libraries = Key.pure ["mirage-console-solo5"]
    method connect _ modname _args =
      Printf.sprintf "%s.connect %S" modname str
  end

let custom_console str =
  match_impl Key.(value target) [
    `Xen, console_xen str;
    `Virtio, console_solo5 str;
    `Ukvm, console_solo5 str
  ] ~default:(console_unix str)

let default_console = custom_console "0"

type kv_ro = KV_RO
let kv_ro = Type KV_RO

let (/) = Filename.concat

let crunch dirname = impl @@ object
    inherit base_configurable
    method ty = kv_ro
    val name = Name.create ("static" ^ dirname) ~prefix:"static"
    method name = name
    method module_name = String.Ascii.capitalize name
    method packages = Key.pure [ "mirage-types"; "lwt"; "cstruct"; "crunch"; "io-page" ]
    method libraries = Key.pure [ "mirage-types"; "lwt"; "cstruct"; "io-page" ]
    method deps = [ abstract default_io_page ]
    method connect _ modname _ = Fmt.strf "%s.connect ()" modname

    method configure i =
      if not (Cmd.exists "ocaml-crunch") then
        Log.error "Couldn't find the ocaml-crunch binary.  Please install the opam package crunch."
      else begin
        let dir = Info.root i / dirname in
        let file = Info.root i / (name ^ ".ml") in
        if Sys.file_exists dir then (
          Log.info "%a %s" Log.blue "Generating:" file;
          Cmd.run "ocaml-crunch -o %s %s" file dir
        ) else (
          Log.error "The directory %s does not exist." dir
        )
      end

    method clean i =
      Cmd.remove (Info.root i / name ^ ".ml");
      Cmd.remove (Info.root i / name ^ ".mli");
      R.ok ()

  end

let direct_kv_ro_conf dirname = impl @@ object
    inherit base_configurable
    method ty = kv_ro
    val name = Name.create ("direct" ^ dirname) ~prefix:"direct"
    method name = name
    method module_name = "Kvro_fs_unix"
    method packages = Key.pure ["mirage-fs-unix"]
    method libraries = Key.pure ["mirage-fs-unix"]
    method connect i _modname _names =
      Fmt.strf "Kvro_fs_unix.connect %S" (Info.root i / dirname)
  end

let direct_kv_ro dirname =
  match_impl Key.(value target) [
    `Xen, crunch dirname;
    `Virtio, crunch dirname;
    `Ukvm, crunch dirname
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
      if Hashtbl.mem all_blocks filename
      then Hashtbl.find all_blocks filename
      else begin
        let number = !next_number in
        incr next_number;
        let b = { filename; number } in
        Hashtbl.add all_blocks filename b;
        b
      end in
    b

class block_conf file =
  let b = make_block_t file in
  let name = Name.create file ~prefix:"block" in
  object (self)
    inherit base_configurable
    method ty = block
    method name = name
    method module_name = "Block"
    method packages =
      Key.match_ Key.(value target) @@ function
      | `Xen -> ["mirage-block-xen"]
      | `Virtio | `Ukvm -> ["mirage-block-solo5"]
      | `Unix | `MacOSX -> ["mirage-block-unix"]
    method libraries =
      Key.match_ Key.(value target) @@ function
      | `Xen -> ["mirage-block-xen.front"]
      | `Virtio | `Ukvm -> ["mirage-block-solo5"]
      | `Unix | `MacOSX -> ["mirage-block-unix"]

    method private connect_name target root =
      match target with
      | `Unix | `MacOSX | `Virtio | `Ukvm ->
        root / b.filename (* open the file directly *)
      | `Xen ->
        (* We need the xenstore id *)
        (* Taken from https://github.com/mirage/mirage-block-xen/blob/
           a64d152586c7ebc1d23c5adaa4ddd440b45a3a83/lib/device_number.ml#L64 *)
        (if b. number < 16
         then (202 lsl 8) lor (b.number lsl 4)
         else (1 lsl 28)  lor (b.number lsl 8)) |> string_of_int

    method connect i s _ =
      Printf.sprintf "%s.connect %S" s
        (self#connect_name (get_target i) @@ Info.root i)

  end

let block_of_file file = impl (new block_conf file)

let tar_block dir =
  let name = Name.create ("tar_block" ^ dir) ~prefix:"tar_block" in
  let block_file = name ^ ".img" in
  impl @@ object
    inherit block_conf block_file as super
    method configure i =
      Cmd.run "tar -C %s -cvf %s ." dir block_file >>= fun () ->
      super#configure i
  end

let archive_conf = impl @@ object
    inherit base_configurable
    method ty = block @-> kv_ro
    method name = "archive"
    method module_name = "Tar_mirage.Make_KV_RO"
    method packages = Key.pure [ "tar-format" ]
    method libraries = Key.pure [ "tar.mirage" ]
    method connect _ modname = function
      | [ block ] ->
        Fmt.strf "%s.connect %s" modname block
      | _ -> failwith "The archive connect should receive exactly one argument."

  end

let archive block = archive_conf $ block
let archive_of_files ?(dir=".") () = archive @@ tar_block dir

type fs = FS
let fs = Type FS

let fat_conf = impl @@ object
    inherit base_configurable
    method ty = (block @-> io_page @-> fs)
    method packages = Key.pure [ "fat-filesystem" ]
    method libraries = Key.pure [ "fat-filesystem" ]
    method name = "fat"
    method module_name = "Fat.Fs.Make"
    method connect _ modname l = match l with
      | [ block_name ; _io_page_name ] ->
        Printf.sprintf "%s.connect %s" modname block_name
      | _ -> assert false
  end

let fat ?(io_page=default_io_page) block = fat_conf $ block $ io_page

let fat_block ?(dir=".") ?(regexp="*") () =
  let name = Name.create (Fmt.strf "fat%s:%s" dir regexp) ~prefix:"fat_block" in
  let block_file = name ^ ".img" in
  impl @@ object
    inherit block_conf block_file as super

    method configure i =
      let root = Info.root i in
      let file = Printf.sprintf "make-%s-image.sh" name in
      Cmd.with_file file begin fun fmt ->
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
        Codegen.append fmt "cd %s/" (root/dir);
        Codegen.append fmt "SIZE=$(du -s . | cut -f 1)";
        Codegen.append fmt "${FAT} create ${IMG} ${SIZE}KiB";
        Codegen.append fmt "${FAT} add ${IMG} %s" regexp;
        Codegen.append fmt "echo Created '%s'" block_file;
      end ;
      Unix.chmod file 0o755;
      Cmd.run "./make-%s-image.sh" name >>= fun () ->
      super#configure i

    method clean i =
      R.get_ok @@ Cmd.run "rm -f make-%s-image.sh %s" name block_file ;
      super#clean i
  end

let fat_of_files ?dir ?regexp () = fat @@ fat_block ?dir ?regexp ()


let kv_ro_of_fs_conf = impl @@ object
    inherit base_configurable
    method ty = fs @-> kv_ro
    method name = "kv_ro_of_fs"
    method module_name = "Fat.KV_RO.Make"
    method packages = Key.pure [ "fat-filesystem" ]
    method libraries = Key.pure [ "fat-filesystem" ]
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
  object (self)
    inherit base_configurable
    method ty = network
    val name = Functoria_app.Name.create "net" ~prefix:"net"
    method name = name
    method module_name = "Netif"
    method keys = [ key ]

    method packages =
      Key.match_ Key.(value target) @@ function
      | `Unix -> ["mirage-net-unix"]
      | `MacOSX -> ["mirage-net-macosx"]
      | `Xen -> ["mirage-net-xen"]
      | `Virtio | `Ukvm -> ["mirage-net-solo5"]

    method libraries = self#packages

    method connect _ modname _ =
      Fmt.strf "%s.connect %a" modname Key.serialize_call key

    method configure i =
      all_networks := Key.get (Info.context i) intf :: !all_networks;
      R.ok ()

  end

let netif ?group dev = impl (network_conf @@ Key.network ?group dev)
let tap0 = netif "tap0"

type ethernet = ETHERNET
let ethernet = Type ETHERNET

let ethernet_conf = object
  inherit base_configurable
  method ty = network @-> ethernet
  method name = "ethif"
  method module_name = "Ethif.Make"
  method packages = Key.pure ["tcpip"]
  method libraries = Key.pure ["tcpip.ethif"]
  method connect _ modname = function
    | [ eth ] -> Printf.sprintf "%s.connect %s" modname eth
    | _ -> failwith "The ethernet connect should receive exactly one argument."
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
  method packages = Key.pure ["tcpip"]
  method libraries = Key.pure ["tcpip.arpv4"]

  method connect _ modname = function
    | [ eth ; clock ; _time ] -> Printf.sprintf "%s.connect %s %s" modname eth clock
    | _ -> failwith "The arpv4 connect should receive exactly three arguments."

end

let arp_func = impl arpv4_conf
let arp ?(clock = default_monotonic_clock) ?(time = default_time) (eth : ethernet impl) =
  arp_func $ eth $ clock $ time

type ('ipaddr, 'prefix) ip_config = {
  address: 'ipaddr;
  netmask: 'prefix;
  gateways: 'ipaddr list;
}

type v4
type v6
type 'a ip = IP
type ipv4 = v4 ip
type ipv6 = v6 ip

let ip = Type IP
let ipv4: ipv4 typ = ip
let ipv6: ipv6 typ = ip

let pp_triple ?(sep=Fmt.cut) ppx ppy ppz fmt (x,y,z) =
  ppx fmt x ; sep fmt () ; ppy fmt y ; sep fmt () ; ppz fmt z

let meta_triple ppx ppy ppz =
  Fmt.parens @@ pp_triple ~sep:(Fmt.unit ",@ ") ppx ppy ppz

let meta_ipv4 ppf s =
  Fmt.pf ppf "(Ipaddr.V4.of_string_exn %S)" (Ipaddr.V4.to_string s)

type ipv4_config = (Ipaddr.V4.t, Ipaddr.V4.t) ip_config

let pp_key fmt k = Key.serialize_call fmt (Key.abstract k)
let opt_key s = Fmt.(option @@ prefix (unit ("~"^^s)) pp_key)
let opt_map f = function Some x -> Some (f x) | None -> None
let (@?) x l = match x with Some s -> s :: l | None -> l
let (@??) x y = opt_map Key.abstract x @? y

let ipv4_conf ?address ?netmask ?gateways () = impl @@ object
    inherit base_configurable
    method ty = ethernet @-> arpv4 @-> ipv4
    method name = Name.create "ipv4" ~prefix:"ipv4"
    method module_name = "Ipv4.Make"
    method packages = Key.pure ["tcpip"]
    method libraries = Key.pure ["tcpip.ipv4"]
    method keys = address @?? netmask @?? gateways @?? []
    method connect _ modname = function
      | [ etif ; arp ] ->
        Fmt.strf
          "%s.connect@[@ %a@ %a@ %a@ %s@ %s@]"
          modname
          (opt_key "ip") address
          (opt_key "netmask") netmask
          (opt_key "gateways") gateways
          etif arp
      | _ -> failwith "The ipv4 connect should receive exactly two arguments."
  end

let create_ipv4
    ?(clock = default_monotonic_clock) ?(time = default_time)
    ?group net { address ; netmask ; gateways } =
  let etif = etif net in
  let arp = arp ~clock ~time etif in
  let address = Key.V4.ip ?group address in
  let netmask = Key.V4.netmask ?group netmask in
  let gateways = Key.V4.gateways ?group gateways in
  ipv4_conf ~address ~netmask ~gateways () $ etif $ arp

let default_ipv4_conf =
  let i = Ipaddr.V4.of_string_exn in
  {
    address  = i "10.0.0.2";
    netmask  = i "255.255.255.0";
    gateways = [i "10.0.0.1"];
  }

let default_ipv4 ?group net = create_ipv4 ?group net default_ipv4_conf

type ipv6_config = (Ipaddr.V6.t, Ipaddr.V6.Prefix.t list) ip_config

let ipv6_conf ?address ?netmask ?gateways () = impl @@ object
    inherit base_configurable
    method ty = ethernet @-> time @-> mclock @-> ipv6
    method name = Name.create "ipv6" ~prefix:"ipv6"
    method module_name = "Ipv6.Make"
    method packages = Key.pure ["tcpip"]
    method libraries = Key.pure ["tcpip.ipv6"]
    method keys = address @?? netmask @?? gateways @?? []
    method connect _ modname = function
      | [ etif ; _time ; _clock ] ->
        Fmt.strf
          "%s.connect@[@ %a@ %a@ %a@ %s@@]"
          modname
          (opt_key "ip") address
          (opt_key "netmask") netmask
          (opt_key "gateways") gateways
          etif
      | _ -> failwith "The ipv6 connect should receive exactly three arguments."
  end

let create_ipv6
    ?(time = default_time)
    ?(clock = default_monotonic_clock)
    ?group net { address ; netmask ; gateways } =
  let etif = etif net in
  let address = Key.V6.ip ?group address in
  let netmask = Key.V6.netmask ?group netmask in
  let gateways = Key.V6.gateways ?group gateways in
  ipv6_conf ~address ~netmask ~gateways () $ etif $ time $ clock

type 'a icmp = ICMP
type icmpv4 = v4 icmp

let icmp = Type ICMP
let icmpv4: icmpv4 typ = icmp

let icmpv4_direct_conf () = object
  inherit base_configurable
  method ty : ('a ip -> 'a icmp) typ = ip @-> icmp
  method name = "icmpv4"
  method module_name = "Icmpv4.Make"
  method packages = Key.pure [ "tcpip" ]
  method libraries = Key.pure [ "tcpip.icmpv4" ]
  method connect _ modname = function
    | [ ip ] -> Printf.sprintf "%s.connect %s" modname ip
    | _  -> failwith "The icmpv4 connect should receive exactly one argument."
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
  method ty : ('a ip -> 'a udp) typ = ip @-> udp
  method name = "udp"
  method module_name = "Udp.Make"
  method packages = Key.pure [ "tcpip" ]
  method libraries = Key.pure [ "tcpip.udp" ]
  method connect _ modname = function
    | [ ip ] -> Printf.sprintf "%s.connect %s" modname ip
    | _  -> failwith "The udpv6 connect should receive exactly one argument."
end

(* Value restriction ... *)
let udp_direct_func () = impl (udp_direct_conf ())
let direct_udp ip = udp_direct_func () $ ip

let udpv4_socket_conf ipv4_key = object
  inherit base_configurable
  method ty = udpv4
  val name = Name.create "udpv4_socket" ~prefix:"udpv4_socket"
  method name = name
  method module_name = "Udpv4_socket"
  method keys = [ Key.abstract ipv4_key ]
  method packages = Key.pure [ "tcpip" ]
  method libraries =
    Key.match_ Key.(value target) @@ function
    | `Unix | `MacOSX -> [ "tcpip.udpv4-socket" ]
    | `Xen | `Virtio | `Ukvm -> failwith "No socket implementation available for unikernel"
  method connect _ modname _ =
    Format.asprintf "%s.connect %a" modname  pp_key ipv4_key
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
  method ty =
    (ip: 'a ip typ) @-> time @-> mclock @-> random @-> (tcp: 'a tcp typ)
  method name = "tcp"
  method module_name = "Tcp.Flow.Make"
  method packages = Key.pure [ "tcpip" ]
  method libraries = Key.pure [ "tcpip.tcp" ]
  method connect _ modname = function
    | [ip; _time; clock; _random] -> Printf.sprintf "%s.connect %s %s" modname ip clock
    | _ -> failwith "The tcp connect should receive exactly four arguments."
end

(* Value restriction ... *)
let tcp_direct_func () = impl (tcp_direct_conf ())

let direct_tcp
    ?(clock=default_monotonic_clock) ?(random=stdlib_random) ?(time=default_time) ip =
  tcp_direct_func () $ ip $ time $ clock $ random

let tcpv4_socket_conf ipv4_key = object
  inherit base_configurable
  method ty = tcpv4
  val name = Name.create "tcpv4_socket" ~prefix:"tcpv4_socket"
  method name = name
  method module_name = "Tcpv4_socket"
  method keys = [ Key.abstract ipv4_key ]
  method packages = Key.pure [ "tcpip" ]
  method libraries =
    Key.match_ Key.(value target) @@ function
    | `Unix | `MacOSX -> [ "tcpip.tcpv4-socket" ]
    | `Xen | `Virtio | `Ukvm  -> failwith "No socket implementation available for unikernel"
  method connect _ modname _ =
    Format.asprintf "%s.connect %a" modname  pp_key ipv4_key
end

let socket_tcpv4 ?group ip = impl (tcpv4_socket_conf @@ Key.V4.socket ?group ip)

type stackv4 = STACKV4
let stackv4 = Type STACKV4

let pp_stackv4_config fmt = function
  | `DHCP   -> Fmt.pf fmt "`DHCP"
  | `IPV4 i -> Fmt.pf fmt "`IPv4 %a" (meta_triple pp_key pp_key pp_key) i

let add_suffix s ~suffix = if suffix = "" then s else s^"_"^suffix

let stackv4_direct_conf ?(group="") config = impl @@ object
    inherit base_configurable

    method ty =
      time @-> random @-> network @->
      ethernet @-> arpv4 @-> ipv4 @-> icmpv4 @-> udpv4 @-> tcpv4 @->
      stackv4

    val name =
      let base = match config with
        | `DHCP -> "dhcp"
        | `IPV4 _ -> "ip"
      in add_suffix ("stackv4_" ^ base) ~suffix:group

    method name = name
    method module_name = "Tcpip_stack_direct.Make"

    method keys = match config with
      | `DHCP -> []
      | `IPV4 (addr,netm,gate) -> [
          Key.abstract addr;
          Key.abstract netm;
          Key.abstract gate
        ]

    method packages = Key.pure [ "tcpip" ]
    method libraries = Key.pure [ "tcpip.stack-direct" ; "mirage.runtime" ]

    method connect _i modname = function
      | [ _t; _r; interface; ethif; arp; ip; icmp; udp; tcp ] ->
        Fmt.strf
          "@[<2>let config = {V1_LWT.@ \
           name = %S;@ \
           interface = %s;@ mode = %a }@]@ in@ \
           %s.connect config@ %s %s %s %s %s %s"
          name interface pp_stackv4_config config
          modname ethif arp ip icmp udp tcp
      | _ -> failwith "Wrong arguments to connect to tcpip direct stack."

  end


let direct_stackv4_with_config
    ?(clock=default_monotonic_clock)
    ?(random=stdlib_random)
    ?(time=default_time)
    ?group
    network config =
  let eth = etif_func $ network in
  let arp = arp ~clock ~time eth in
  let ip = ipv4_conf () $ eth $ arp in
  stackv4_direct_conf ?group config
  $ time $ random $ network
  $ eth $ arp $ ip
  $ direct_icmpv4 ip
  $ direct_udp ip
  $ direct_tcp ~clock ~random ~time ip

let direct_stackv4_with_dhcp
    ?clock ?random ?time ?group network =
  direct_stackv4_with_config
    ?clock ?random ?time ?group network `DHCP

let direct_stackv4_with_static_ipv4
    ?clock ?random ?time ?group network
    {address; netmask; gateways} =
  let address = Key.V4.ip ?group address in
  let netmask = Key.V4.netmask ?group netmask in
  let gateways = Key.V4.gateways ?group gateways in
  direct_stackv4_with_config
    ?clock ?random ?time ?group network
    (`IPV4 (address, netmask, gateways))

let direct_stackv4_with_default_ipv4
    ?clock ?random ?time ?group network =
  direct_stackv4_with_static_ipv4
    ?clock ?random ?time ?group network
    default_ipv4_conf

let stackv4_socket_conf ?(group="") interfaces = impl @@ object
    inherit base_configurable
    method ty = stackv4
    val name = add_suffix "stackv4_socket" ~suffix:group
    method name = name
    method module_name = "Tcpip_stack_socket"
    method keys = [ Key.abstract interfaces ]
    method packages = Key.pure [ "tcpip" ]
    method libraries = Key.pure [ "tcpip.stack-socket" ]
    method deps = [
      abstract (socket_udpv4 None);
      abstract (socket_tcpv4 None);
    ]

    method connect _i modname = function
      | [ udpv4 ; tcpv4 ] ->
        Fmt.strf
          "let config =@[@ \
           { V1_LWT.name = %S;@ \
           interface = %a ;@ mode = () }@] in@ \
           %s.connect config %s %s"
          name
          pp_key interfaces
          modname udpv4 tcpv4
      | _ -> failwith "Wrong arguments to connect to tcpip socket stack."

  end

let socket_stackv4 ?group ipv4s =
  stackv4_socket_conf ?group (Key.V4.interfaces ?group ipv4s)

(** Generic stack *)

let generic_stackv4
    ?group
    ?(dhcp_key = Key.value @@ Key.dhcp ?group ())
    ?(net_key = Key.value @@ Key.net ?group ())
    (tap : network impl) : stackv4 impl=
  if_impl
    Key.(pure ((=) `Socket) $ net_key)
    (socket_stackv4 ?group [Ipaddr.V4.any])
    (if_impl
       dhcp_key
       (direct_stackv4_with_dhcp ?group tap)
       (direct_stackv4_with_default_ipv4 ?group tap)
    )

type conduit_connector = Conduit_connector
let conduit_connector = Type Conduit_connector

let tcp_conduit_connector = impl @@ object
    inherit base_configurable
    method ty = stackv4 @-> conduit_connector
    method name = "tcp_conduit_connector"
    method module_name = "Conduit_mirage.With_tcp"
    method packages = Key.pure [ "mirage-conduit" ]
    method libraries = Key.pure [ "conduit.mirage" ]
    method connect _ modname = function
      | [ stack ] ->
        Fmt.strf "Lwt.return (%s.connect %s)@;" modname stack
      | _ -> failwith "Wrong arguments to connect to tcp conduit connector."
  end

let tls_conduit_connector = impl @@ object
    inherit base_configurable
    method ty = conduit_connector
    method name = "tls_conduit_connector"
    method module_name = "Conduit_mirage"
    method packages = Key.pure [ "mirage-conduit" ; "tls" ]
    method libraries = Key.pure [ "conduit.mirage" ; "tls.mirage" ]
    method deps = [ abstract nocrypto ]
    method connect _ _ _ = "Lwt.return Conduit_mirage.with_tls"
  end

type conduit = Conduit
let conduit = Type Conduit

let conduit_with_connectors connectors = impl @@ object
    inherit base_configurable
    method ty = conduit
    method name = Name.create "conduit" ~prefix:"conduit"
    method module_name = "Conduit_mirage"
    method packages = Key.pure [ "mirage-conduit" ]
    method libraries = Key.pure [ "conduit.mirage" ]
    method deps = abstract nocrypto :: List.map abstract connectors

    method connect _i _ = function
      (* There is always at least the nocrypto device *)
      | [] -> invalid_arg "Mirage.conduit_with_connector"
      | _nocrypto :: connectors ->
        let pp_connector = Fmt.fmt "%s >>=@ " in
        let pp_connectors = Fmt.list ~sep:Fmt.nop pp_connector in
        Fmt.strf
          "Lwt.return Conduit_mirage.empty >>=@ \
           %a\
           fun t -> Lwt.return t"
          pp_connectors connectors
  end

let conduit_direct ?(tls=false) s =
  (* TCP must be before tls in the list. *)
  let connectors = [tcp_conduit_connector $ s] in
  let connectors =
    if tls
    then connectors @ [tls_conduit_connector]
    else connectors
  in
  conduit_with_connectors connectors

type resolver = Resolver
let resolver = Type Resolver

let resolver_unix_system = impl @@ object
    inherit base_configurable
    method ty = resolver
    method name = "resolver_unix"
    method module_name = "Resolver_lwt"
    method packages =
      Key.match_ Key.(value target) @@ function
      | `Unix | `MacOSX -> [ "mirage-conduit" ]
      | `Xen | `Virtio | `Ukvm -> failwith "Resolver_unix not supported on unikernel"
    method libraries = Key.pure [ "conduit.mirage"; "conduit.lwt-unix" ]
    method connect _ _modname _ = "Lwt.return Resolver_lwt_unix.system"
  end

let resolver_dns_conf ~ns ~ns_port = impl @@ object
    inherit base_configurable
    method ty = time @-> stackv4 @-> resolver
    method name = "resolver"
    method module_name = "Resolver_mirage.Make_with_stack"
    method packages = Key.pure [ "dns"; "tcpip" ]
    method libraries = Key.pure [ "dns.mirage" ]

    method connect _ modname = function
      | [ _t ; stack ] ->
        let meta_ns = Fmt.Dump.option meta_ipv4 in
        let meta_port = Fmt.(Dump.option int) in
        Fmt.strf
          "let ns = %a in@;\
           let ns_port = %a in@;\
           let res = %s.R.init ?ns ?ns_port ~stack:%s () in@;\
           Lwt.return res@;"
          meta_ns ns
          meta_port ns_port
          modname stack
      | _ -> failwith "The resolver connect should receive exactly two arguments."

  end

let resolver_dns ?ns ?ns_port ?(time = default_time) stack =
  resolver_dns_conf ~ns ~ns_port $ time $ stack

type http = HTTP
let http = Type HTTP

let http_server conduit = impl @@ object
    inherit base_configurable
    method ty = http
    method name = "http"
    method module_name = "Cohttp_mirage.Server_with_conduit"
    method packages = Key.pure [ "mirage-http" ]
    method libraries = Key.pure [ "mirage-http" ]
    method deps = [ abstract conduit ]
    method connect _i modname = function
      | [ conduit ] -> Fmt.strf "%s.connect %s" modname conduit
      | _ -> failwith "The http connect should receive exactly one argument."
  end

(** Argv *)

let argv_unix = impl @@ object
    inherit base_configurable
    method ty = Functoria_app.argv
    method name = "argv_unix"
    method module_name = "OS.Env"
    method connect _ _ _ = "OS.Env.argv ()"
  end

let argv_xen = impl @@ object
    inherit base_configurable
    method ty = Functoria_app.argv
    method name = "argv_xen"
    method module_name = "Bootvar"
    method packages = Key.pure [ "mirage-bootvar-xen" ]
    method libraries = Key.pure [ "mirage-bootvar" ]
    method connect _ _ _ = "Bootvar.argv ()"
  end

let argv_solo5 = impl @@ object
    inherit base_configurable
    method ty = Functoria_app.argv
    method name = "argv_solo5"
    method module_name = "Bootvar"
    method packages = Key.pure [ "mirage-bootvar-solo5" ]
    method libraries = Key.pure [ "mirage-bootvar" ]
    method connect _ _ _ = "Bootvar.argv ()"
  end

let no_argv = impl @@ object
    inherit base_configurable
    method ty = Functoria_app.argv
    method name = "argv_empty"
    method module_name = "Mirage_runtime"
    method connect _ _ _ = "Lwt.return [|\"\"|]"
  end

let default_argv =
  match_impl Key.(value target) [
    `Xen, argv_xen;
    `Virtio, argv_solo5;
    `Ukvm, argv_solo5
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
    method packages = Key.pure ["mirage-logs"]
    method libraries = Key.pure ["mirage-logs"]
    method keys = [ Key.abstract logs ]
    method connect _ modname = function
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
    | _ -> failwith "The Pclock connect should receive exactly one argument."
  end

let default_reporter
    ?(clock=default_posix_clock) ?ring_size ?(level=Logs.Info) () =
  mirage_log ?ring_size ~default:level $ clock

let no_reporter = impl @@ object
    inherit base_configurable
    method ty = reporter
    method name = "no_reporter"
    method module_name = "Mirage_runtime"
    method connect _ _ _ = "assert false"
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
    method keys = [ Key.abstract key ]
    method packages = Key.pure ["mirage-profile"]
    method libraries =
      Key.match_ Key.(value target) @@function
      | `Xen | `Virtio | `Ukvm -> ["mirage-profile.xen"]
      | `Unix | `MacOSX -> ["mirage-profile.unix"]

    method configure _ =
      if Sys.command "ocamlfind query lwt.tracing 2>/dev/null" = 0
      then R.ok ()
      else begin
        flush stdout;
        Log.error
          "lwt.tracing module not found. Hint:\n\
           opam pin add lwt 'https://github.com/mirage/lwt.git#tracing'"
      end

    method connect i _ _ = match Key.(get (Info.context i) target) with
      | `Unix | `MacOSX ->
        Fmt.strf
          "Lwt.return ())@.\
           let () = (@ \
             @[<v 2>  let buffer = MProf_unix.mmap_buffer ~size:%a %S in@ \
             let trace_config = MProf.Trace.Control.make buffer MProf_unix.timestamper in@ \
             MProf.Trace.Control.start trace_config@]"
          Key.serialize_call (Key.abstract key)
          unix_trace_file;
      | `Xen | `Virtio | `Ukvm ->
        Fmt.strf
          "Lwt.return ())@.\
           let () = (@ \
             @[<v 2>  let trace_pages = MProf_xen.make_shared_buffer ~size:%a in@ \
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
  let file = root / name ^ "_libvirt.xml" in
  Cmd.with_file file @@ fun fmt ->
  append fmt "<!-- %s -->" (generated_header ());
  append fmt "<domain type='xen'>";
  append fmt "    <name>%s</name>" name;
  append fmt "    <memory unit='KiB'>262144</memory>";
  append fmt "    <currentMemory unit='KiB'>262144</currentMemory>";
  append fmt "    <vcpu placement='static'>1</vcpu>";
  append fmt "    <os>";
  append fmt "        <type arch='armv7l' machine='xenpv'>linux</type>";
  append fmt "        <kernel>%s/mir-%s.xen</kernel>" root name;
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
  ()

let clean_main_libvirt_xml ~root ~name =
  Cmd.remove (root / name ^ "_libvirt.xml")

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
  match List.fold_left (fun sofar x -> match sofar with
      | None ->
        (* This is Linux-specific *)
        if Sys.file_exists (Printf.sprintf "/sys/class/net/%s0" x)
        then Some x
        else None
      | Some x -> Some x
    ) None [ "xenbr"; "br"; "virbr" ] with
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
    | Block b -> Printf.sprintf "@BLOCK:%s@" b.filename
    | Network n -> Printf.sprintf "@NETWORK:%s@" n

  let lookup ts v =
    if List.mem_assoc v ts
    then List.assoc v ts
    else string_of_v v

  let defaults i =
    let blocks = List.map (fun b ->
        Block b, Filename.concat (Info.root i) b.filename
      ) (Hashtbl.fold (fun _ v acc -> v :: acc) all_blocks []) in
    let networks = List.mapi (fun i n ->
        Network n, Printf.sprintf "%s%d" detected_bridge_name i
      ) !all_networks in [
      Name, (Info.name i);
      Kernel, Printf.sprintf "%s/mir-%s.xen" (Info.root i) (Info.name i);
      Memory, "256";
    ] @ blocks @ networks

end

let configure_main_xl ?substitutions ext i =
  let open Substitutions in
  let substitutions = match substitutions with
    | Some x -> x
    | None -> defaults i in
  let file = Info.root i / Info.name i ^ ext in
  let open Codegen in
  Cmd.with_file file @@ fun fmt ->
  append fmt "# %s" (generated_header ()) ;
  newline fmt;
  append fmt "name = '%s'" (lookup substitutions Name);
  append fmt "kernel = '%s'" (lookup substitutions Kernel);
  append fmt "builder = 'linux'";
  append fmt "memory = %s" (lookup substitutions Memory);
  append fmt "on_crash = 'preserve'";
  newline fmt;
  let blocks = List.map (fun b ->
      (* We need the Linux version of the block number (this is a
         strange historical artifact) Taken from
         https://github.com/mirage/mirage-block-xen/blob/
         a64d152586c7ebc1d23c5adaa4ddd440b45a3a83/lib/device_number.ml#L128 *)
      let rec string_of_int26 x =
        let (/) = Pervasives.(/) in
        let high, low = x / 26 - 1, x mod 26 + 1 in
        let high' = if high = -1 then "" else string_of_int26 high in
        let low' =
          String.v 1 (fun _ -> char_of_int (low + (int_of_char 'a') - 1))
        in
        high' ^ low' in
      let vdev = Printf.sprintf "xvd%s" (string_of_int26 b.number) in
      let path = lookup substitutions (Block b) in
      Printf.sprintf "'format=raw, vdev=%s, access=rw, target=%s'" vdev path
    ) (Hashtbl.fold (fun _ v acc -> v :: acc) all_blocks []) in
  append fmt "disk = [ %s ]" (String.concat ~sep:", " blocks);
  newline fmt;
  let networks = List.map (fun n ->
      Printf.sprintf "'bridge=%s'" (lookup substitutions (Network n))
    ) !all_networks in
  append fmt "# if your system uses openvswitch then either edit \
              /etc/xen/xl.conf and set";
  append fmt "#     vif.default.script=\"vif-openvswitch\"";
  append fmt "# or add \"script=vif-openvswitch,\" before the \"bridge=\" \
              below:";
  append fmt "vif = [ %s ]" (String.concat ~sep:", " networks);
  ()

let clean_main_xl ~root ~name ext = Cmd.remove (root / name ^ ext)

let configure_main_xe ~root ~name =
  let open Codegen in
  let file = root / name ^ ".xe" in
  Cmd.with_file file @@ fun fmt ->
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
  append fmt "VDI=$(xe-unikernel-upload --path %s/mir-%s.xen)" root name;
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
      append fmt "xe vbd-param-set uuid=$VBD other-config:owner=true";
    ) (Hashtbl.fold (fun _ v acc -> v :: acc) all_blocks []);
  append fmt "echo Starting VM";
  append fmt "xe vm-start uuid=$VM";
  Unix.chmod file 0o755

let clean_main_xe ~root ~name = Cmd.remove (root / name ^ ".xe")

(* Implement something similar to the @name/file extended names of findlib. *)
let rec expand_name ~lib param =
  match String.cut param ~sep:"@" with
  | None -> param
  | Some (prefix, name) -> match String.cut name ~sep:"/" with
    | None              -> prefix ^ lib / name
    | Some (name, rest) -> prefix ^ lib / name / expand_name ~lib rest

(* Get the linker flags for any extra C objects we depend on.
 * This is needed when building a Xen/Solo5 image as we do the link manually. *)
let get_extra_ld_flags target pkgs =
  Cmd.read "opam config var lib" >>= fun s ->
  let lib = String.trim s in
  Cmd.read
    "ocamlfind query -r -format '%%d\t%%(%s_linkopts)' -predicates native %s"
    target (String.concat ~sep:" " pkgs) >>| fun output ->
  String.cuts output ~sep:"\n"
  |> List.fold_left (fun acc line ->
      match String.cut line ~sep:"\t" with
      | None -> acc
      | Some (dir, ldflags) ->
        if ldflags <> "" then
          let ldflags = String.cuts ldflags ~sep:" " in
          let ldflags = List.map (expand_name ~lib) ldflags in
          let ldflags = String.concat ~sep:" " ldflags in
          Printf.sprintf "-L%s %s" dir ldflags :: acc
        else
          acc
    ) []

let configure_myocamlbuild_ml ~root =
  let minor, major = Cmd.ocaml_version () in
  if minor < 4 || major < 1 then (
    (* Previous ocamlbuild versions weren't able to understand the
       --output-obj rules *)
    let file = root / "myocamlbuild.ml" in
    Cmd.with_file file @@ fun fmt ->
    Codegen.append fmt "(* %s *)" (Codegen.generated_header ());
    Codegen.newline fmt;
    Codegen.append fmt
      "open Ocamlbuild_pack;;\n\
       open Ocamlbuild_plugin;;\n\
       open Ocaml_compiler;;\n\
       \n\
       let native_link_gen linker =\n\
      \  link_gen \"cmx\" \"cmxa\" !Options.ext_lib [!Options.ext_obj; \"cmi\"\
       ] linker;;\n\
       \n\
       let native_output_obj x = native_link_gen ocamlopt_link_prog\n\
      \  (fun tags -> tags++\"ocaml\"++\"link\"++\"native\"++\"output_obj\") \
       x;;\n\
       \n\
       rule \"ocaml: cmx* & o* -> native.o\"\n\
      \  ~tags:[\"ocaml\"; \"native\"; \"output_obj\" ]\n\
      \  ~prod:\"%%.native.o\" ~deps:[\"%%.cmx\"; \"%%.o\"]\n\
      \  (native_output_obj \"%%.cmx\" \"%%.native.o\");;\n\
       \n\
       \n\
       let byte_link_gen = link_gen \"cmo\" \"cma\" \"cma\" [\"cmo\"; \"cmi\"\
       ];;\n\
       let byte_output_obj = byte_link_gen ocamlc_link_prog\n\
      \  (fun tags -> tags++\"ocaml\"++\"link\"++\"byte\"++\"output_obj\");;\n\
       \n\
       rule \"ocaml: cmo* -> byte.o\"\n\
      \  ~tags:[\"ocaml\"; \"byte\"; \"link\"; \"output_obj\" ]\n\
       ~prod:\"%%.byte.o\" ~dep:\"%%.cmo\"\n\
      \  (byte_output_obj \"%%.cmo\" \"%%.byte.o\");;";
  )

let clean_myocamlbuild_ml ~root = Cmd.remove (root / "myocamlbuild.ml")

module S = Set.Make(String)

let configure_makefile ~target ~root ~name ~warn_error info =
  let open Codegen in
  let file = root / "Makefile" in
  let libs = Info.libraries info in
  let libraries =
    match libs with
    | [] -> ""
    | l -> Fmt.(strf "-pkgs %a" (list ~sep:(unit ",") string)) l
  in
  let packages =
    Fmt.(strf "%a" (list ~sep:(unit " ") string)) @@ Info.packages info
  in
  Cmd.with_file file @@ fun fmt ->
  append fmt "# %s" (generated_header ());
  newline fmt;
  append fmt "LIBS   = %s" libraries;
  append fmt "PKGS   = %s" packages;
  let default_tags =
    (if warn_error then "warn_error(+1..49)," else "") ^
    "warn(A-4-41-44),debug,bin_annot,\
     strict_sequence,principal,safe_string"
  in
  begin match target with
    | `Xen ->
      append fmt "SYNTAX = -tags \"%s\"\n" default_tags;
      append fmt "FLAGS  = -r -cflag -g -lflags -g,-linkpkg,-dontlink,unix\n";
      append fmt "XENLIB = $(shell ocamlfind query mirage-xen)\n"
    | `Virtio | `Ukvm ->
      append fmt "SYNTAX = -tags \"%s\"\n" default_tags;
      append fmt "FLAGS  = -cflag -g -lflags -g,-linkpkg,-dontlink,unix\n";
      append fmt "XENLIB = $(shell ocamlfind query mirage-solo5)\n"
    | `Unix ->
      append fmt "SYNTAX = -tags \"%s\"\n" default_tags;
      append fmt "FLAGS  = -r -cflag -g -lflags -g,-linkpkg\n"
    | `MacOSX ->
      append fmt "SYNTAX = -tags \"thread,%s\"\n" default_tags;
      append fmt "FLAGS  = -r -cflag -g -lflags -g,-linkpkg\n"
  end;
  append fmt "TAGS = \"predicate(%s)\""
    (match target with
      `Unix | `MacOSX -> "unix" | `Xen -> "xen" | `Virtio | `Ukvm -> "solo5" );
  append fmt "SYNTAX += -tag-line \"<static*.*>: warn(-32-34)\"\n";
  append fmt "LD?=ld";
  append fmt "BUILD  = ocamlbuild -use-ocamlfind -tags $(TAGS) $(LIBS) $(SYNTAX) $(FLAGS)\n\
              OPAM   = opam\n\n\
              export PKG_CONFIG_PATH=$(shell opam config var prefix)\
              /lib/pkgconfig\n\n\
              export OPAMVERBOSE=1\n\
              export OPAMYES=1";
  newline fmt;
  let pkg_config_deps =
    match target with
    | `Xen -> "mirage-xen"
    | `Virtio -> "mirage-solo5 ocaml-freestanding"
    | `Ukvm -> "mirage-solo5 ocaml-freestanding"
    | `MacOSX | `Unix -> ""
  in
  let extra_ld_flags archives =
    let archives = S.elements (S.of_list archives) in
    let extra_c_archives = String.concat ~sep:" \\\n\t  " archives in
    append fmt "EXTRA_LD_FLAGS = %s\n" extra_c_archives;
    append fmt "EXTRA_LD_FLAGS += $$(pkg-config --static --libs %s)\n" pkg_config_deps
  in
  let pre_ld_flags x =
    append fmt "PRE_LD_FLAGS = $$(pkg-config --variable=ldflags %s)\n" x
  in
  begin match target with
    | `Xen ->
      get_extra_ld_flags "xen" libs >>= fun archives ->
      extra_ld_flags archives;
      R.ok ()
    | `Virtio ->
      get_extra_ld_flags "freestanding" libs >>= fun archives ->
      extra_ld_flags archives;
      pre_ld_flags "solo5-kernel-virtio" ;
      R.ok ()
    | `Ukvm ->
      get_extra_ld_flags "freestanding" libs >>= fun archives ->
      extra_ld_flags archives;
      pre_ld_flags "solo5-kernel-ukvm" ;
      R.ok ()
    | `Unix | `MacOSX ->
      R.ok ()
  end >>= fun () ->
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

  (* On ARM:
     - we must convert the ELF image to an ARM boot executable zImage,
       while on x86 we leave it as it is.
     - we need to link libgcc.a (otherwise we get undefined references to:
       __aeabi_dcmpge, __aeabi_dadd, ...)
 *)
  let generate_image =
    let is_arm =
      match Cmd.uname_m () with
      | Some machine ->
        String.length machine > 2 && String.is_prefix ~affix:"arm" machine
      | None -> failwith "uname -m failed; can't determine target machine type!"
    in
    if is_arm then (
      Printf.sprintf "\t  $(shell gcc -print-libgcc-file-name) \\\n\
                      \t  -o mir-%s.elf\n\
                      \tobjcopy -O binary mir-%s.elf mir-%s.xen"
        name name name
    ) else (
      Printf.sprintf "\t  -o mir-%s.xen" name
    ) in
  begin match target with
    | `Xen ->
      append fmt "build:: main.native.o";
      append fmt "\tpkg-config --print-errors --exists %s" pkg_config_deps;
      append fmt "\t$(LD) -d -static -nostdlib \\\n\
                  \t  _build/main.native.o \\\n\
                  \t  $(EXTRA_LD_FLAGS) \\\n\
                  %s"
        generate_image ;
      append fmt "\t@@echo Build succeeded";
      newline fmt;
      append fmt "clean::\n\
                  \tocamlbuild -clean";
      R.ok ()
    | `Virtio ->
      append fmt "build:: main.native.o";
      append fmt "\tpkg-config --print-errors --exists %s" pkg_config_deps;
      append fmt "\t$(LD) $(PRE_LD_FLAGS) \\\n\
                  \t  _build/main.native.o \\\n\
                  \t  $(EXTRA_LD_FLAGS) \\\n\
                  \t  -o mir-%s.virtio"
        name ;
      append fmt "\t@@echo Build succeeded";
      newline fmt;
      append fmt "clean::\n\
                  \tocamlbuild -clean";
      R.ok ()
    | `Ukvm ->
      let ukvm_mods =
        let ukvm_filter = function
          | "mirage-net-solo5" -> "net"
          | "mirage-block-solo5" -> "blk"
          | _ -> ""
        in
        String.concat ~sep:" " (List.map ukvm_filter libs)
      in
      append fmt "UKVM_MODULES=%s" ukvm_mods;
      append fmt "Makefile.ukvm:";
      append fmt "\t ukvm-configure $$(pkg-config --variable=libdir solo5-kernel-ukvm)/src/ukvm $(UKVM_MODULES)";
      newline fmt;
      append fmt "include Makefile.ukvm";
      append fmt "build:: main.native.o ukvm-bin";
      append fmt "\tpkg-config --print-errors --exists %s" pkg_config_deps;
      append fmt "\t$(LD) $(PRE_LD_FLAGS) \\\n\
                  \t  _build/main.native.o \\\n\
                  \t  $(EXTRA_LD_FLAGS) \\\n\
                  \t  -o mir-%s.ukvm"
        name ;
      append fmt "\t@@echo Build succeeded";
      newline fmt;
      append fmt "clean:: ukvm-clean\n\
                  \tocamlbuild -clean\n\
                  \t$(RM) Makefile.ukvm";
      R.ok ()
    | `Unix | `MacOSX ->
      append fmt "build: main.native";
      append fmt "\tln -nfs _build/main.native mir-%s" name;
      newline fmt;
      append fmt "clean::\n\
                  \tocamlbuild -clean";
      R.ok ()
  end >>= fun () ->
  newline fmt;
  append fmt "-include Makefile.user";
  R.ok ()

let clean_makefile ~root = Cmd.remove (root / "Makefile")

let check_ocaml_version () =
  (* Similar to [Functoria_app.Cmd.ocaml_version] but with the patch number *)
  let ocaml_version =
    let version =
      let v = Sys.ocaml_version in
      match String.cut v ~sep:"+" with None -> v | Some (v, _) -> v
    in
    match String.cuts version ~sep:"." with
    | [major; minor; patch] ->
      begin
        try int_of_string major, int_of_string minor, int_of_string patch
        with _ -> 0, 0, 0
      end
    | _ -> 0, 0, 0
  in
  let major, minor, patch = ocaml_version in
  if major < 4 ||
     (major = 4 && minor < 2) ||
     (major = 4 && minor = 2 && patch < 3)
  then (
    Log.error
      "Your version of OCaml (%d.%02d.%d) is not supported. Please upgrade to\n\
       at least OCaml 4.02.3 or use `--no-ocaml-version-check`."
      major minor patch
  ) else
    R.ok ()

let configure i =
  let name = Info.name i in
  let root = Info.root i in
  let ctx = Info.context i in
  let target = Key.(get ctx target) in
  let ocaml_check = not Key.(get ctx no_ocaml_check) in
  let warn_error = Key.(get ctx warn_error) in
  begin
    if ocaml_check then check_ocaml_version ()
    else R.ok ()
  end >>= fun () ->
  check_entropy @@ Info.libraries i >>= fun () ->
  Log.info "%a %a" Log.blue "Configuring for target:" Key.pp_target target ;
  Cmd.in_dir root (fun () ->
      configure_main_xl ".xl" i;
      configure_main_xl ~substitutions:[] ".xl.in" i;
      configure_main_xe ~root ~name;
      configure_main_libvirt_xml ~root ~name;
      configure_myocamlbuild_ml ~root;
      configure_makefile ~target ~root ~name ~warn_error i;
    )

let clean i =
  let name = Info.name i in
  let root = Info.root i in
  Cmd.in_dir root (fun () ->
      clean_main_xl ~root ~name ".xl";
      clean_main_xl ~root ~name ".xl.in";
      clean_main_xe ~root ~name;
      clean_main_libvirt_xml ~root ~name;
      clean_myocamlbuild_ml ~root;
      clean_makefile ~root;
      Cmd.run "rm -rf %s/mir-%s" root name;
    )

module Project = struct
  let name = "mirage"
  let version = "%%VERSION%%"
  let prelude =
    "open Lwt.Infix\n\
     let return = Lwt.return\n\
     let run = OS.Main.run"

  let create jobs = impl @@ object
      inherit base_configurable
      method ty = job
      method name = "mirage"
      method module_name = "Mirage_runtime"
      method keys = [
        Key.(abstract target);
        Key.(abstract no_ocaml_check);
        Key.(abstract warn_error);
      ]

      method packages =
        let l = [ "lwt"; "mirage-types"; "mirage-types-lwt" ] in
        Key.match_ Key.(value target) @@ function
        | `Xen -> "mirage-xen" :: l
        | `Virtio -> "solo5-kernel-virtio" :: "mirage-solo5" :: l
        | `Ukvm -> "solo5-kernel-ukvm" :: "mirage-solo5" :: l
        | `Unix | `MacOSX -> "mirage-unix" :: l

      method libraries =
        let l = [ "mirage.runtime"; "mirage-types.lwt" ] in
        Key.match_ Key.(value target) @@ function
        | `Xen -> "mirage-xen" :: l
        | `Virtio | `Ukvm -> "mirage-solo5" :: l
        | `Unix | `MacOSX -> "mirage-unix" :: l

      method configure = configure
      method clean = clean
      method connect _ _mod _names = "Lwt.return_unit"
      method deps = List.map abstract jobs
    end

end

include Functoria_app.Make (Project)

(** {Custom registration} *)

let (++) acc x = match acc, x with
  | _       , None   -> acc
  | None    , Some x -> Some [x]
  | Some acc, Some x -> Some (acc @ [x])

let register
    ?(argv=default_argv) ?tracing ?(reporter=default_reporter ())
    ?keys ?(libraries=[]) ?(packages=[])
    name jobs =
  let argv = Some (Functoria_app.keys argv) in
  let reporter = if reporter == no_reporter then None else Some reporter in
  let init = None ++ argv ++ reporter ++ tracing in
  register ?keys ~libraries ~packages ?init name jobs
