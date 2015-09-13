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
open Functoria
open Functoria_misc

module Key = Mirage_key
include (Dsl : Functoria.S with module Key := Key)


(** {2 Error handling} *)
let driver_error name =
  Printf.sprintf "fail (Failure %S)" name

(** {2 Mode} *)

let get_mode =
  let x = Key.value Key.target in
  fun () -> Key.eval x

(** {2 Devices} *)

type io_page = IO_PAGE
let io_page = Type IO_PAGE

let io_page_conf = object
  inherit base_configurable
  method ty = io_page
  method name = "io_page"
  method module_name = "Io_page"
  method libraries =
    Key.pipe Key.(value target) @@ function
    | `Xen  -> ["io-page"]
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


type clock = CLOCK
let clock = Type CLOCK

let clock_conf = object (self)
  inherit base_configurable
  method ty = clock
  method name = "clock"
  method module_name = "Clock"
  method libraries =
    Key.pipe Key.(value target) @@ function
    | `Unix | `MacOSX -> [ "mirage-clock-unix" ]
    | `Xen  -> [ "mirage-clock-xen" ]
  method packages = self#libraries
end

let default_clock = impl clock_conf


type random = RANDOM
let random = Type RANDOM

let random_conf = object
  inherit base_configurable
  method ty = random
  method name = "random"
  method module_name = "Random"
end

let default_random = impl random_conf


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
      Printf.sprintf "%s.connect %S" modname name
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
      Printf.sprintf "%s.connect %S" modname name
  end

let custom_console str =
  if_impl Key.is_xen (console_xen str) (console_unix str)

let default_console = custom_console "0"


type kv_ro = KV_RO
let kv_ro = Type KV_RO

class crunch_conf dirname =
  let name =
    Name.of_key ("static" ^ dirname) ~base:"static"
  in object
    inherit base_configurable
    method ty = kv_ro

    method name = name
    method module_name = String.capitalize name

    method packages = Key.pure [ "mirage-types"; "lwt"; "cstruct"; "crunch" ]
    method libraries = Key.pure [ "mirage-types"; "lwt"; "cstruct" ]

    method dependencies = [ hide default_io_page ]

    val ml = Printf.sprintf "%s.ml" name
    val mli = Printf.sprintf "%s.mli" name

    method connect _ modname _ =
      Fmt.strf "%s.connect ()" modname

    method configure i =
      if not (command_exists "ocaml-crunch") then
        error "ocaml-crunch not found, stopping."
      else begin
        let dir = Info.root i / dirname in
        let file = Info.root i / ml in
        if Sys.file_exists dir then (
          info "%a %s" Functoria_misc.blue "Generating:" file;
          command "ocaml-crunch -o %s %s" file dir
        ) else (
          error "The directory %s does not exist." dir
        )
      end

    method clean i =
      remove (Info.root i/ml);
      remove (Info.root i/mli);
      R.ok ()

  end

let crunch dirname = impl (new crunch_conf dirname)


let direct_kv_ro dirname = impl @@ object
  inherit crunch_conf dirname as super

  method module_name =
    match get_mode () with
    | `Xen  -> super#module_name
    | `Unix | `MacOSX -> "Kvro_fs_unix"

  method packages =
    let f p = function
      | `Xen  -> p
      | `Unix | `MacOSX -> "mirage-fs-unix" :: p
    in Key.(pure f $ super#packages $ value target)

  method libraries =
    let f l = function
    | `Xen  -> l
    | `Unix | `MacOSX -> "mirage-fs-unix" :: l
    in Key.(pure f $ super#libraries $ value target)

  method connect i modname names =
    match get_mode () with
    | `Xen  -> super#connect i modname names
    | `Unix | `MacOSX ->
      Fmt.strf "Kvro_fs_unix.connect %S" (Info.root i/dirname)

end


type block = BLOCK
let block = Type BLOCK

type block_t = {
  filename: string;
  number: int;
}

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
  let name = Name.of_key file ~base:"block" in
  object (self)
  inherit base_configurable
  method ty = block
  method name = name
  method module_name = "Block"
  method packages =
    Key.pipe Key.(value target) @@ function
    | `Unix | `MacOSX -> ["mirage-block-unix"]
    | `Xen  -> ["mirage-block-xen"]
  method libraries =
    Key.pipe Key.(value target) @@ function
    | `Unix | `MacOSX -> ["mirage-block-unix"]
    | `Xen  -> ["mirage-block-xen.front"]


  method private connect_name root =
    match get_mode () with
    | `Unix | `MacOSX -> root / b.filename (* open the file directly *)
    | `Xen ->
      (* We need the xenstore id *)
      (* Taken from https://github.com/mirage/mirage-block-xen/blob/a64d152586c7ebc1d23c5adaa4ddd440b45a3a83/lib/device_number.ml#L64 *)
      (if b. number < 16
       then (202 lsl 8) lor (b.number lsl 4)
       else (1 lsl 28)  lor (b.number lsl 8)) |> string_of_int

  method connect i s _ =
    Printf.sprintf "%s.connect %S" s (self#connect_name @@ Info.root i)

end

let block_of_file file =
  impl (new block_conf file)

let tar_block dir =
  let name = Name.of_key ("tar_block" ^ dir) ~base:"tar_block" in
  let block_file = name ^ ".img" in
  impl @@ object
    inherit block_conf block_file as super

    method configure i =
      command "tar -C %s -cvf %s ." dir block_file >>= fun () ->
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

let archive_of_files ?(dir=".") () =
  archive @@ tar_block dir



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

let fat ?(io_page=default_io_page) block =
  fat_conf $ block $ io_page


let fat_block ?(dir=".") ?(regexp="*") () =
  let name = Name.of_key (Fmt.strf "fat%s:%s" dir regexp) ~base:"fat_block" in
  let block_file = name ^ ".img" in
  impl @@ object
    inherit block_conf block_file as super

    method configure i =
      let root = Info.root i in
      let file = Printf.sprintf "make-%s-image.sh" name in
      with_file file begin fun fmt ->
        Codegen.append fmt "#!/bin/sh";
        Codegen.append fmt "";
        Codegen.append fmt "echo This uses the 'fat' command-line tool to build a simple FAT";
        Codegen.append fmt "echo filesystem image.";
        Codegen.append fmt "";
        Codegen.append fmt "FAT=$(which fat)";
        Codegen.append fmt "if [ ! -x \"${FAT}\" ]; then";
        Codegen.append fmt "  echo I couldn\\'t find the 'fat' command-line tool.";
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
      command "./make-%s-image.sh" name >>= fun () ->
      super#configure i

    method clean i =
      R.get_ok @@ command "rm -f make-%s-image.sh %s" name block_file ;
      super#clean i
  end

let fat_of_files ?dir ?regexp () =
  fat @@ fat_block ?dir ?regexp ()


let kv_ro_of_fs_conf = impl @@ object
  inherit base_configurable
  method ty = fs @-> kv_ro
  method name = "kv_ro_of_fs"
  method module_name = "Fat.KV_RO.Make"
  method packages = Key.pure [ "fat-filesystem" ]
  method libraries = Key.pure [ "fat-filesystem" ]
end

let kv_ro_of_fs x = kv_ro_of_fs_conf $ x

type network = NETWORK
let network = Type NETWORK

let network_conf (intf : string Key.key) =
  let key = Key.hide intf in
  object (self)
  inherit base_configurable

  method ty = network

  val name = Name.of_key "net" ~base:"net"
  method name = name
  method module_name = "Netif"

  method keys = [ key ]

  method packages =
    Key.pipe Key.(value target) @@ function
    | `Unix -> ["mirage-net-unix"]
    | `MacOSX -> ["mirage-net-macosx"]
    | `Xen  -> ["mirage-net-xen"]

  method libraries = self#packages

  method connect _ modname _ =
    Fmt.strf "%s.connect %a"
      modname
      Key.emit_call key

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

  method libraries =
    Key.pipe Key.(value target) @@ function
    | `Unix | `MacOSX -> [ "tcpip.ethif-unix" ]
    | `Xen  -> [ "tcpip.ethif" ]

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
  method ty = ethernet @-> clock @-> time @-> arpv4

  method name = "arpv4"
  method module_name = "Arpv4.Make"

  method packages = Key.pure ["tcpip"]
  method libraries =
    Key.pipe Key.(value target) @@ function
    | `Unix | `MacOSX -> ["tcpip.arpv4-unix"]
    | `Xen  -> ["tcpip.arpv4"]

  method connect _ modname = function
    | [ eth ; _clock ; _time ] -> Printf.sprintf "%s.connect %s" modname eth
    | _ -> failwith "The arpv4 connect should receive exactly three arguments."

end

let arp_func = impl arpv4_conf
let arp ?(clock = default_clock) ?(time = default_time) (eth : ethernet impl) =
  arp_func $ eth $ clock $ time

type ('ipaddr, 'prefix) ip_config = {
  address: 'ipaddr;
  netmask: 'prefix;
  gateways: 'ipaddr list;
}


type v4
type v6

type 'a ip = IP
let ip = Type IP

type ipv4 = v4 ip
let ipv4 : ipv4 typ = ip

type ipv6 = v6 ip
let ipv6 : ipv6 typ = ip

let pp_triple ?(sep=Fmt.cut) ppx ppy ppz fmt (x,y,z) =
  ppx fmt x ; sep fmt () ; ppy fmt y ; sep fmt () ; ppz fmt z

let meta_triple ppx ppy ppz =
  Fmt.parens @@ pp_triple ~sep:(Fmt.unit ",@ ") ppx ppy ppz

let meta_ipv4 ppf s =
  Fmt.pf ppf "Ipaddr.V4.of_string_exn %S" (Ipaddr.V4.to_string s)

type ipv4_config = (Ipaddr.V4.t, Ipaddr.V4.t) ip_config

let pp_key fmt k = Key.emit_call fmt (Key.hide k)

let opt_key s =
  Fmt.(option @@ prefix (unit ("~"^^s)) pp_key)

let (@??) x y = opt_map Key.hide x @? y

let ipv4_conf ?address ?netmask ?gateways () = impl @@ object
  inherit base_configurable

  method ty = ethernet @-> arpv4 @-> ipv4

  method name = Name.of_key "ipv4" ~base:"ipv4"
  method module_name = "Ipv4.Make"

  method packages = Key.pure [ "tcpip" ]
  method libraries =
    Key.pipe Key.(value target) @@ function
    | `Unix | `MacOSX -> [ "tcpip.ipv4-unix" ]
    | `Xen  -> [ "tcpip.ipv4" ]

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
    ?(clock = default_clock) ?(time = default_time)
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

let default_ipv4 ?group net =
  create_ipv4 ?group net default_ipv4_conf


type ipv6_config = (Ipaddr.V6.t, Ipaddr.V6.Prefix.t list) ip_config

let ipv6_conf ?address ?netmask ?gateways () = impl @@ object
  inherit base_configurable

  method ty = ethernet @-> time @-> clock @-> ipv6

  method name = Name.of_key "ipv6" ~base:"ipv6"
  method module_name = "Ipv6.Make"

  method packages = Key.pure [ "tcpip" ]
  method libraries =
    Key.pipe Key.(value target) @@ function
    | `Unix | `MacOSX -> [ "tcpip.ipv6-unix" ]
    | `Xen  -> [ "tcpip.ipv6" ]

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
    ?(clock = default_clock)
    ?group net { address ; netmask ; gateways } =
  let etif = etif net in
  let address = Key.V6.ip ?group address in
  let netmask = Key.V6.netmask ?group netmask in
  let gateways = Key.V6.gateways ?group gateways in
  ipv6_conf ~address ~netmask ~gateways () $ etif $ time $ clock


type 'a udp = UDP
let udp = Type UDP

type udpv4 = v4 udp
let udpv4 : udpv4 typ = udp

type udpv6 = v6 udp
let udpv6 : udpv6 typ = udp

(* Value restriction ... *)
let udp_direct_conf () = object
  inherit base_configurable

  method ty : ('a ip -> 'a udp) typ = ip @-> udp

  method name = "udp"
  method module_name = "Udp.Make"

  method packages = Key.pure [ "tcpip" ]
  method libraries = Key.pure [ "tcpip.udp" ]

  method connect _ modname = function
    | [ ip ] ->
      Printf.sprintf "%s.connect %s" modname ip
    | _ -> failwith "The udpv6 connect should receive exactly one argument."

end

(* Value restriction ... *)
let udp_direct_func () = impl (udp_direct_conf ())

let direct_udp ip = udp_direct_func () $ ip

let udpv4_socket_conf ipv4_key = object
  inherit base_configurable
  method ty = udpv4

  val name = Name.of_key "udpv4_socket" ~base:"udpv4_socket"
  method name = name
  method module_name = "Udpv4_socket"

  method keys = [ Key.hide ipv4_key ]

  method packages = Key.pure [ "tcpip" ]
  method libraries =
    Key.pipe Key.(value target) @@ function
    | `Unix | `MacOSX -> [ "tcpip.udpv4-socket" ]
    | `Xen  -> failwith "No socket implementation available for Xen"

  method connect _ modname _ =
    Format.asprintf "%s.connect %a" modname  pp_key ipv4_key

end

let socket_udpv4 ?group ip =
  impl (udpv4_socket_conf @@ Key.V4.socket ?group ip)


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
    (ip : 'a ip typ) @-> time @-> clock @-> random @-> (tcp : 'a tcp typ)

  method name = "tcp"
  method module_name = "Tcp.Flow.Make"

  method packages = Key.pure [ "tcpip" ]
  method libraries = Key.pure [ "tcpip.tcp" ]

  method connect _ modname = function
    | [ ip ; _time ; _clock ; _random ] ->
      Printf.sprintf "%s.connect %s" modname ip
    | _ -> failwith "The tcp connect should receive exactly four arguments."
end

(* Value restriction ... *)
let tcp_direct_func () = impl (tcp_direct_conf ())

let direct_tcp
    ?(clock=default_clock) ?(random=default_random) ?(time=default_time) ip =
  tcp_direct_func () $ ip $ time $ clock $ random


let tcpv4_socket_conf ipv4_key = object
  inherit base_configurable
  method ty = tcpv4

  val name = Name.of_key "tcpv4_socket" ~base:"tcpv4_socket"
  method name = name
  method module_name = "Tcpv4_socket"

  method keys = [ Key.hide ipv4_key ]

  method packages = Key.pure [ "tcpip" ]
  method libraries =
    Key.pipe Key.(value target) @@ function
    | `Unix | `MacOSX -> [ "tcpip.tcpv4-socket" ]
    | `Xen  -> failwith "No socket implementation available for Xen"

  method connect _ modname _ =
    Format.asprintf "%s.connect %a" modname  pp_key ipv4_key

end

let socket_tcpv4 ?group ip =
  impl (tcpv4_socket_conf @@ Key.V4.socket ?group ip)



type stackv4 = STACKV4
let stackv4 = Type STACKV4

let pp_stackv4_config fmt = function
  | `DHCP   -> Fmt.pf fmt "`DHCP"
  | `IPV4 i ->
    Fmt.pf fmt "`IPv4 %a"
      (meta_triple pp_key pp_key pp_key) i

let stackv4_direct_conf ?(group="") config = impl @@ object
  inherit base_configurable

  method ty =
    console @-> time @-> random @-> network @->
      ethernet @-> arpv4 @-> ipv4 @-> udpv4 @-> tcpv4 @->
      stackv4

  val name =
    let base = match config with
      | `DHCP -> "dhcp"
      | `IPV4 _ -> "ip"
    in suffix ("stackv4_" ^ base) ~by:group
  method name = name
  method module_name = "Tcpip_stack_direct.Make"

  method keys = match config with
    | `DHCP -> []
    | `IPV4 (addr,netm,gate) ->
      [ Key.hide addr; Key.hide netm; Key.hide gate]

  method packages = Key.pure [ "tcpip" ]
  method libraries = Key.pure [ "tcpip.stack-direct" ; "mirage.runtime" ]

  method connect _i modname = function
    | [ console; _t; _r; interface; ethif; arp; ip; udp; tcp ] ->
      Fmt.strf
        "@[<2>let config = {V1_LWT.@ \
         name = %S;@ console = %s;@ \
         interface = %s;@ mode = %a }@]@ in@ \
         %s.connect config@ %s %s %s %s %s"
        name console
        interface  pp_stackv4_config config
        modname ethif arp ip udp tcp
    | _ -> failwith "Wrong arguments to connect to tcpip direct stack."

end


let direct_stackv4_with_config
    ?(clock=default_clock)
    ?(random=default_random)
    ?(time=default_time)
    ?group
    console network config =
  let eth = etif_func $ network in
  let arp = arp ~clock ~time eth in
  let ip = ipv4_conf () $ eth $ arp in
  stackv4_direct_conf ?group config
  $ console $ time $ random $ network
  $ eth $ arp $ ip
  $ direct_udp ip
  $ direct_tcp ~clock ~random ~time ip

let direct_stackv4_with_dhcp
    ?clock ?random ?time ?group console network =
  direct_stackv4_with_config
    ?clock ?random ?time ?group console network `DHCP

let direct_stackv4_with_static_ipv4
    ?clock ?random ?time ?group console network
    {address; netmask; gateways} =
  let address = Key.V4.ip ?group address in
  let netmask = Key.V4.netmask ?group netmask in
  let gateways = Key.V4.gateways ?group gateways in
  direct_stackv4_with_config
    ?clock ?random ?time ?group console network
    (`IPV4 (address, netmask, gateways))

let direct_stackv4_with_default_ipv4
    ?clock ?random ?time ?group console network =
  direct_stackv4_with_static_ipv4
    ?clock ?random ?time ?group console network
    default_ipv4_conf


let stackv4_socket_conf ?(group="") interfaces = impl @@ object
  inherit base_configurable

  method ty = console @-> stackv4

  val name = suffix "stackv4_socket" ~by:group
  method name = name
  method module_name = "Tcpip_stack_socket.Make"

  method keys = [ Key.hide interfaces ]

  method packages = Key.pure [ "tcpip" ]
  method libraries = Key.pure [ "tcpip.stack-socket" ]

  method dependencies =
    [ hide @@ socket_udpv4 None ; hide @@ socket_tcpv4 None ]

  method connect _i modname = function
    | [ console ; udpv4 ; tcpv4 ] ->
      Fmt.strf
        "let config =@[@ \
         { V1_LWT.name = %S;@ console = %s ;@ \
         interface = %a ;@ mode = () }@] in@ \
         %s.connect config %s %s"
        name
        console  pp_key interfaces
        modname udpv4 tcpv4
    | _ -> failwith "Wrong arguments to connect to tcpip socket stack."

end

let socket_stackv4 ?group console ipv4s =
  stackv4_socket_conf ?group (Key.V4.interfaces ?group ipv4s) $ console


(** Generic stack *)

let generic_stackv4 ?group console tap =
  let dhcp_key = Key.dhcp ?group () in
  let net_key = Key.net ?group () in
  if_impl
    Key.(pure ((=) `Socket) $ value net_key)
    (socket_stackv4 console ?group [Ipaddr.V4.any])
    (if_impl
       (Key.value dhcp_key)
       (direct_stackv4_with_dhcp ?group console tap)
       (direct_stackv4_with_default_ipv4 ?group console tap)
    )

(* This is to check that entropy is a dependency if "tls" is in
   the package array. *)
let enable_entropy, is_entropy_enabled =
  let r = ref false in
  let f () = r := true in
  let g () = !r in
  (f, g)

let check_entropy libs =
  OCamlfind.query ~recursive:true (StringSet.elements libs)
  >>| List.exists ((=) "nocrypto")
  >>= fun is_needed ->
  if is_needed && not (is_entropy_enabled ()) then
    error
      "The \"nocrypto\" library is loaded but entropy is not enabled!@ \
       Please enable the entropy by adding a dependency \
       to the nocrypto device. You can do so with the ~dependency \
       argument of Mirage.foreign."
  else R.ok ()

let nocrypto = impl @@ object
  inherit base_configurable
  method ty = job
  method name = "nocrypto"
  method module_name = "Nocrypto_entropy"

  method packages =
    Key.pipe Key.(value target) @@ function
    | `Xen -> [ "mirage-entropy-xen" ]
    | _    -> []

  method libraries =
    Key.pipe Key.(value target) @@ function
    | `Xen            -> ["nocrypto.xen"]
    | `Unix | `MacOSX -> ["nocrypto.lwt"]

  method configure _ = R.ok (enable_entropy ())
  method connect _ _ _ =
    let s = match get_mode () with
      | `Xen            -> "Nocrypto_entropy_xen.initialize ()"
      | `Unix | `MacOSX -> "Nocrypto_entropy_lwt.initialize ()"
    in
    Fmt.strf "%s >|= fun x -> `Ok x" s

end

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
      Fmt.strf
        "let f = %s.connect %s in@ \
         return (`Ok f)@;"
        modname stack
    | _ -> failwith "Wrong arguments to connect to tcp conduit connector."

end

let tls_conduit_connector = impl @@ object
  inherit base_configurable
  method ty = conduit_connector

  method name = "tls_conduit_connector"
  method module_name = "Conduit_mirage"

  method packages = Key.pure [ "mirage-conduit" ; "tls" ]
  method libraries = Key.pure [ "conduit.mirage" ; "tls.mirage" ]

  method dependencies = [ hide nocrypto ]

  method connect _ _ _ =
    "return (`Ok Conduit_mirage.with_tls)"

end


type conduit = Conduit
let conduit = Type Conduit

let conduit_with_connectors connectors = impl @@ object
  inherit base_configurable
  method ty = conduit

  method name = Name.of_key "conduit" ~base:"conduit"
  method module_name = "Conduit_mirage"

  method packages = Key.pure [ "mirage-conduit" ]
  method libraries = Key.pure [ "conduit.mirage" ]

  method dependencies = List.map hide connectors

  method connect _i _ connectors =
    let pp_connector = Fmt.fmt "%s >>=@ " in
    let pp_connectors = Fmt.list ~sep:Fmt.nop pp_connector in
    Fmt.strf
      "Lwt.return Conduit_mirage.empty >>=@ \
      %a\
      fun t -> Lwt.return (`Ok t)"
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
    Key.pipe Key.(value target) @@ function
    | `Unix | `MacOSX -> [ "mirage-conduit" ]
    | `Xen -> failwith "Resolver_unix not supported on Xen"
  method libraries =
    Key.pure [ "conduit.mirage"; "conduit.lwt-unix" ]

  method connect _ _modname _ =
    "return (`Ok Resolver_lwt_unix.system)"

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
         let res = %s.init ?ns ?ns_port ~stack:%s () in@;\
         return (`Ok res)@;"
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

  method dependencies = [ hide conduit ]

  method connect _i modname = function
    | [ conduit ] ->
      Fmt.strf "%s.connect %s" modname conduit
    | _ -> failwith "The http connect should receive exactly one argument."

end


(** Argv *)

let argv_unix = impl @@ object
  inherit base_configurable
  method ty = Devices.argv
  method name = "argv_unix"
  method module_name = "OS.Env"
  method connect _ _ _ =
    "OS.Env.argv () >>= (fun x -> Lwt.return (`Ok x))"
  end

let argv_xen = impl @@ object
  inherit base_configurable
  method ty = Devices.argv
  method name = "argv_xen"
  method module_name = "Bootvar"
  method packages = Key.pure [ "mirage-bootvar-xen" ]
  method libraries = Key.pure [ "mirage-bootvar" ]
  method connect _ _ _ =
    "Bootvar.argv ()"
  end

let argv = if_impl Key.is_xen argv_xen argv_unix


(** Tracing *)

let tracing =
  let unix_trace_file = "trace.ctf" in
  impl @@ object
  inherit base_configurable

  method ty = job
  method name = "tracing"
  method module_name = "MProf"

  method keys = [ Key.hide Key.tracing ]

  method packages = Key.pure ["mirage-profile"]
  method libraries =
    Key.pipe Key.(value target) @@ function
    | `Unix | `MacOSX -> ["mirage-profile.unix"]
    | `Xen  -> ["mirage-profile.xen"]

  method configure _ =
    if Sys.command "ocamlfind query lwt.tracing 2>/dev/null" = 0
    then R.ok ()
    else begin
      flush stdout;
      error "lwt.tracing module not found. Hint:\n\
            opam pin add lwt 'https://github.com/mirage/lwt.git#tracing'"
    end

  method connect _ _ _ = match get_mode () with
    | `Unix | `MacOSX ->
      Fmt.strf
        "let buffer = MProf_unix.mmap_buffer ~size:%a %S in@ \
         let trace_config = MProf.Trace.Control.make buffer MProf_unix.timestamper in@ \
         MProf.Trace.Control.start trace_config"
        Key.emit_call Key.(hide tracing)
        unix_trace_file;
    | `Xen  ->
      Fmt.strf
        "let trace_pages = MProf_xen.make_shared_buffer ~size:%a in@ \
         let buffer = trace_pages |> Io_page.to_cstruct |> Cstruct.to_bigarray in@ \
         let trace_config = MProf.Trace.Control.make buffer MProf_xen.timestamper in@ \
         MProf.Trace.Control.start trace_config;@ \
         MProf_xen.share_with (module Gnt.Gntshr) (module OS.Xs) ~domid:0 trace_pages@ \
         |> OS.Main.run"
        Key.emit_call Key.(hide tracing)

end

let mprof_trace ~size () = size

let configure_main_libvirt_xml ~root ~name =
  let open Codegen in
  let file = root / name ^ "_libvirt.xml" in
  with_file file @@ fun fmt ->
  append fmt "<!-- %s -->" (generated_header ());
  append fmt "<domain type='xen'>";
  append fmt "    <name>%s</name>" name;
  append fmt "    <memory unit='KiB'>262144</memory>";
  append fmt "    <currentMemory unit='KiB'>262144</currentMemory>";
  append fmt "    <vcpu placement='static'>1</vcpu>";
  append fmt "    <os>";
  append fmt "        <type arch='armv7l' machine='xenpv'>linux</type>";
  append fmt "        <kernel>%s/mir-%s.xen</kernel>" root name;
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

let clean_main_libvirt_xml ~root ~name =
  remove (root / name ^ "_libvirt.xml")

let configure_main_xl ~root ~name =
  let open Codegen in
  let file = root / name ^ ".xl" in
  with_file file @@ fun fmt ->
  append fmt "# %s" (generated_header ());
  newline fmt;
  append fmt "name = '%s'" name;
  append fmt "kernel = '%s/mir-%s.xen'" root name;
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
    let path = Filename.concat root b.filename in
    Printf.sprintf "'format=raw, vdev=%s, access=rw, target=%s'" vdev path
  ) (Hashtbl.fold (fun _ v acc -> v :: acc) all_blocks []) in
  append fmt "disk = [ %s ]" (String.concat ", " blocks);
  newline fmt;
  append fmt "# The network configuration is defined here:";
  append fmt "# http://xenbits.xen.org/docs/4.3-testing/misc/xl-network-configuration.html";
  append fmt "# An example would look like:";
  append fmt "# vif = [ 'mac=c0:ff:ee:c0:ff:ee,bridge=br0' ]";
  ()

let clean_main_xl ~root ~name =
  remove (root / name ^ ".xl")

let configure_main_xe ~root ~name =
  let open Codegen in
  let file = root / name ^ ".xe" in
  with_file file @@ fun fmt ->
  append fmt "#!/bin/sh";
  append fmt "# %s" (generated_header ());
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
    append fmt "VDI=$(xe vdi-create type=user name-label='%s' virtual-size=$SIZE sr-uuid=$SR)" b.filename;
    append fmt "xe vdi-import uuid=$VDI filename=%s/%s" root b.filename;
    append fmt "VBD=$(xe vbd-create vm-uuid=$VM vdi-uuid=$VDI device=%d)" b.number;
    append fmt "xe vbd-param-set uuid=$VBD other-config:owner=true";
  ) (Hashtbl.fold (fun _ v acc -> v :: acc) all_blocks []);
  append fmt "echo Starting VM";
  append fmt "xe vm-start vm=%s" name;
  Unix.chmod file 0o755

let clean_main_xe ~root ~name =
  remove (root / name ^ ".xe")

(* Implement something similar to the @name/file extended names of findlib. *)
let rec expand_name ~lib param =
  match cut_at param '@' with
  | None -> param
  | Some (prefix, name) -> match cut_at name '/' with
    | None              -> prefix ^ lib / name
    | Some (name, rest) -> prefix ^ lib / name / expand_name ~lib rest

(* Get the linker flags for any extra C objects we depend on.
 * This is needed when building a Xen image as we do the link manually. *)
let get_extra_ld_flags pkgs =
  read_command "opam config var lib" >>= fun s ->
  let lib = strip s in
  read_command
    "ocamlfind query -r -format '%%d\t%%(xen_linkopts)' -predicates native %s"
    (String.concat " " pkgs) >>| fun output ->
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

let configure_myocamlbuild_ml ~root =
  let open Functoria_misc in
  let minor, major = ocaml_version () in
  if minor < 4 || major < 1 then (
    (* Previous ocamlbuild versions weren't able to understand the
       --output-obj rules *)
    let file = root / "myocamlbuild.ml" in
    with_file file @@ fun fmt ->
    Codegen.append fmt "(* %s *)" (generated_header ());
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

let clean_myocamlbuild_ml ~root =
  remove (root / "myocamlbuild.ml")

let configure_makefile ~root ~name info =
  let open Codegen in
  let file = root / "Makefile" in
  let libs = StringSet.elements @@ Info.libraries info in
  let libraries =
    match libs with
    | [] -> ""
    | l -> Fmt.(strf "-pkgs %a" (list ~sep:(unit ",") string)) l
  in
  let packages =
    Fmt.(strf "%a" (list ~sep:(unit " ") string)) @@
    StringSet.elements @@ Info.packages info
  in
  with_file file @@ fun fmt ->
  append fmt "# %s" (generated_header ());
  newline fmt;
  append fmt "LIBS   = %s" libraries;
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
                      name name name
    ) else (
      Printf.sprintf "\t  -o mir-%s.xen" name
    ) in

  begin match get_mode () with
    | `Xen ->
      get_extra_ld_flags libs
      >>| String.concat " \\\n\t  "
      >>= fun extra_c_archives ->
      append fmt "build:: main.native.o";
      let pkg_config_deps = "mirage-xen" in
      append fmt "\tpkg-config --print-errors --exists %s" pkg_config_deps;
      append fmt "\tld -d -static -nostdlib \\\n\
                  \t  _build/main.native.o \\\n\
                  \t  %s \\\n\
                  \t  $$(pkg-config --static --libs %s) \\\n\
                  \t  $(shell gcc -print-libgcc-file-name) \\\n\
                  %s"
        extra_c_archives pkg_config_deps generate_image ;
      R.ok ()
    | `Unix | `MacOSX ->
      append fmt "build: main.native";
      append fmt "\tln -nfs _build/main.native mir-%s" name;
      R.ok ()
  end >>= fun () ->
  newline fmt;
  append fmt "clean::\n\
              \tocamlbuild -clean";
  newline fmt;
  append fmt "-include Makefile.user";
  R.ok ()


let clean_makefile ~root =
  remove (root / "Makefile")


let configure i =
  let name = Info.name i in
  let root = Info.root i in
  check_entropy @@ Info.libraries i >>= fun () ->
  info "%a %a" blue "Configuring for target:"
    Key.pp_target (get_mode ()) ;
  in_dir root (fun () ->
    configure_main_xl ~root ~name;
    configure_main_xe ~root ~name;
    configure_main_libvirt_xml ~root ~name;
    configure_myocamlbuild_ml ~root;
    configure_makefile ~root ~name i;
  )


let clean i =
  let name = Info.name i in
  let root = Info.root i in
  in_dir root (fun () ->
      clean_main_xl ~root ~name;
      clean_main_xe ~root ~name;
      clean_main_libvirt_xml ~root ~name;
      clean_myocamlbuild_ml ~root;
      clean_makefile ~root;
      command "rm -rf %s/mir-%s" root name;
    )

module Project = struct

  let name = "mirage"

  let version = Mirage_version.current

  let prelude =
    "open Lwt\n\
     let run = OS.Main.run"

  let driver_error = driver_error

  let argv = argv

  let config jobs = impl @@ object
    inherit base_configurable
    method ty = job
    method name = "mirage"
    method module_name = "Mirage_runtime"
    method keys = [ Key.hide Key.target ]

    method packages =
      let l = [ "lwt" ; "sexplib" ] in
      Key.pipe Key.(value target) @@ function
      | `Unix | `MacOSX -> "mirage-unix" :: l
      | `Xen  -> "mirage-xen" :: l

    method libraries = Key.pure [
      "lwt.syntax" ; "mirage.runtime" ;
      "mirage-types.lwt" ; "sexplib"
    ]

    method configure = configure
    method clean = clean

    method connect _ _mod _names =
      "Lwt.return_unit"

    method dependencies = List.map hide jobs
  end


end

include Functoria.Make (Project)

let register ?tracing:t ?keys ?libraries ?packages name jobs =
  let jobs = match t with
    | None -> jobs
    | Some i ->
      Key.set Key.tracing i ;
      tracing :: jobs
  in
  register ?keys ?libraries ?packages name jobs
