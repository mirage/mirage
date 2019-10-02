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

module Log = Mirage_impl_misc.Log
open Mirage_impl_misc

include Functoria

(** {2 OCamlfind predicates} *)

(* Mirage implementation backing the target. *)
let backend_predicate = function
  | #Mirage_key.mode_xen -> "mirage_xen"
  | #Mirage_key.mode_solo5 -> "mirage_solo5"
  | #Mirage_key.mode_unix -> "mirage_unix"

(** {2 Devices} *)

type qubesdb = Mirage_impl_qubesdb.qubesdb
let qubesdb = Mirage_impl_qubesdb.qubesdb
let default_qubesdb = Mirage_impl_qubesdb.default_qubesdb

type time = Mirage_impl_time.time
let time = Mirage_impl_time.time
let default_time = Mirage_impl_time.default_time

type pclock = Mirage_impl_pclock.pclock
let pclock = Mirage_impl_pclock.pclock
let default_posix_clock = Mirage_impl_pclock.default_posix_clock

type mclock = Mirage_impl_mclock.mclock
let mclock = Mirage_impl_mclock.mclock
let default_monotonic_clock = Mirage_impl_mclock.default_monotonic_clock

type random = Mirage_impl_random.random
let random = Mirage_impl_random.random
let stdlib_random = Mirage_impl_random.stdlib_random
let default_random = Mirage_impl_random.default_random
let nocrypto = Mirage_impl_random.nocrypto
let nocrypto_random = Mirage_impl_random.nocrypto_random

type console = Mirage_impl_console.console
let console = Mirage_impl_console.console
let default_console = Mirage_impl_console.default_console
let custom_console = Mirage_impl_console.custom_console

type kv_ro = Mirage_impl_kv.ro
let kv_ro = Mirage_impl_kv.ro
let direct_kv_ro = Mirage_impl_kv.direct_kv_ro
let crunch = Mirage_impl_kv.crunch

type kv_rw = Mirage_impl_kv.rw
let kv_rw = Mirage_impl_kv.rw
let direct_kv_rw = Mirage_impl_kv.direct_kv_rw
let kv_rw_mem = Mirage_impl_kv.mem_kv_rw

type block = Mirage_impl_block.block
let block = Mirage_impl_block.block
let archive_of_files = Mirage_impl_block.archive_of_files
let archive = Mirage_impl_block.archive
let generic_block = Mirage_impl_block.generic_block
let ramdisk = Mirage_impl_block.ramdisk
let block_of_xenstore_id = Mirage_impl_block.block_of_xenstore_id
let block_of_file = Mirage_impl_block.block_of_file

type fs = Mirage_impl_fs.t
let fs = Mirage_impl_fs.typ
let fat = Mirage_impl_fs.fat
let fat_of_files = Mirage_impl_fs.fat_of_files
let generic_kv_ro = Mirage_impl_fs.generic_kv_ro
let kv_ro_of_fs = Mirage_impl_fs.kv_ro_of_fs

type network = Mirage_impl_network.network
let network = Mirage_impl_network.network
let netif = Mirage_impl_network.netif
let default_network = Mirage_impl_network.default_network

type ethernet = Mirage_impl_ethernet.ethernet
let ethernet = Mirage_impl_ethernet.ethernet
let etif = Mirage_impl_ethernet.etif

type arpv4 = Mirage_impl_arpv4.arpv4
let arpv4 = Mirage_impl_arpv4.arpv4
let arp = Mirage_impl_arpv4.arp

type v4 = Mirage_impl_ip.v4
type v6 = Mirage_impl_ip.v6
type 'a ip = 'a Mirage_impl_ip.ip
type ipv4 = Mirage_impl_ip.ipv4
type ipv6 = Mirage_impl_ip.ipv6
let ipv4 = Mirage_impl_ip.ipv4
let ipv6 = Mirage_impl_ip.ipv6
let ipv4_qubes = Mirage_impl_ip.ipv4_qubes
let create_ipv4 = Mirage_impl_ip.create_ipv4
let create_ipv6 = Mirage_impl_ip.create_ipv6
type ipv4_config = Mirage_impl_ip.ipv4_config = {
  network : Ipaddr.V4.Prefix.t * Ipaddr.V4.t;
  gateway : Ipaddr.V4.t option;
}
type ipv6_config = Mirage_impl_ip.ipv6_config = {
  addresses : Ipaddr.V6.t list;
  netmasks  : Ipaddr.V6.Prefix.t list;
  gateways  : Ipaddr.V6.t list;
}

type 'a udp = 'a Mirage_impl_udp.udp
let udp = Mirage_impl_udp.udp
type udpv4 = Mirage_impl_udp.udpv4
type udpv6 = Mirage_impl_udp.udpv6
let udpv4 = Mirage_impl_udp.udpv4
let udpv6 = Mirage_impl_udp.udpv6
let direct_udp = Mirage_impl_udp.direct_udp
let socket_udpv4 = Mirage_impl_udp.socket_udpv4

type 'a tcp = 'a Mirage_impl_tcp.tcp
let tcp = Mirage_impl_tcp.tcp
type tcpv4 = Mirage_impl_tcp.tcpv4
type tcpv6 = Mirage_impl_tcp.tcpv6
let tcpv4 = Mirage_impl_tcp.tcpv4
let tcpv6 = Mirage_impl_tcp.tcpv6
let direct_tcp = Mirage_impl_tcp.direct_tcp
let socket_tcpv4 = Mirage_impl_tcp.socket_tcpv4

type stackv4 = Mirage_impl_stackv4.stackv4
let stackv4 = Mirage_impl_stackv4.stackv4
let generic_stackv4 = Mirage_impl_stackv4.generic_stackv4
let static_ipv4_stack = Mirage_impl_stackv4.static_ipv4_stack
let dhcp_ipv4_stack = Mirage_impl_stackv4.dhcp_ipv4_stack
let qubes_ipv4_stack = Mirage_impl_stackv4.qubes_ipv4_stack
let direct_stackv4 = Mirage_impl_stackv4.direct_stackv4
let socket_stackv4 = Mirage_impl_stackv4.socket_stackv4

type conduit = Mirage_impl_conduit.conduit
let conduit = Mirage_impl_conduit.conduit
let conduit_direct = Mirage_impl_conduit.conduit_direct

type resolver = Mirage_impl_resolver.resolver
let resolver = Mirage_impl_resolver.resolver
let resolver_unix_system = Mirage_impl_resolver.resolver_unix_system
let resolver_dns = Mirage_impl_resolver.resolver_dns

type syslog = Mirage_impl_syslog.syslog
let syslog = Mirage_impl_syslog.syslog
let syslog_tls = Mirage_impl_syslog.syslog_tls
let syslog_tcp = Mirage_impl_syslog.syslog_tcp
let syslog_udp = Mirage_impl_syslog.syslog_udp
type syslog_config = Mirage_impl_syslog.syslog_config =
  { hostname : string;
    server   : Ipaddr.V4.t option;
    port     : int option;
    truncate : int option;
  }
let syslog_config = Mirage_impl_syslog.syslog_config

type http = Mirage_impl_http.http
let http = Mirage_impl_http.http
let http_server = Mirage_impl_http.cohttp_server
let cohttp_server = Mirage_impl_http.cohttp_server
let httpaf_server = Mirage_impl_http.httpaf_server

let default_argv = Mirage_impl_argv.default_argv
let no_argv = Mirage_impl_argv.no_argv

type reporter = Mirage_impl_reporter.reporter
let reporter = Mirage_impl_reporter.reporter
let default_reporter = Mirage_impl_reporter.default_reporter
let no_reporter = Mirage_impl_reporter.no_reporter

type tracing = Mirage_impl_tracing.tracing
let tracing = Mirage_impl_tracing.tracing
let mprof_trace = Mirage_impl_tracing.mprof_trace

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
    | Block of Mirage_impl_block.block_t
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
      List.map
        (fun b -> Block b, Fpath.(to_string ((Info.build_dir i) / b.filename)))
        (Hashtbl.fold (fun _ v acc -> v :: acc) Mirage_impl_block.all_blocks [])
    and networks =
      List.mapi (fun i n -> Network n, Fmt.strf "%s%d" detected_bridge_name i)
        !Mirage_impl_network.all_networks
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
      let open Mirage_impl_block in
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
          !Mirage_impl_network.all_networks
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
      let open Mirage_impl_block in
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

let configure_makefile ~no_depext ~opam_name =
  let open Codegen in
  let file = Fpath.(v "Makefile") in
  with_output file (fun oc () ->
      let fmt = Format.formatter_of_out_channel oc in
      append fmt "# %s" (generated_header ());
      newline fmt;
      append fmt "-include Makefile.user";
      newline fmt;
      let depext = if no_depext then "" else "\n\t$(DEPEXT)" in
      append fmt "OPAM = opam\n\
                  DEPEXT ?= $(OPAM) pin add -k path --no-action --yes %s . &&\\\n\
                  \t$(OPAM) depext --yes --update %s ;\\\n\
                  \t$(OPAM) pin remove --no-action %s\n\
                  \n\
                  .PHONY: all depend depends clean build\n\
                  all:: build\n\
                  \n\
                  depend depends::%s\n\
                  \t$(OPAM) install -y --deps-only .\n\
                  \n\
                  build::\n\
                  \tmirage build\n\
                  \n\
                  clean::\n\
                  \tmirage clean\n"
        opam_name opam_name opam_name depext;
      R.ok ())
    "Makefile"

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

let opam_file n = Fpath.(v n + "opam")

let configure_opam ~name info =
  let open Codegen in
  let file = opam_file name in
  with_output file (fun oc () ->
      let fmt = Format.formatter_of_out_channel oc in
      append fmt "# %s" (generated_header ());
      Info.opam ~name fmt info;
      append fmt "maintainer: \"dummy\"";
      append fmt "authors: \"dummy\"";
      append fmt "homepage: \"dummy\"";
      append fmt "bug-reports: \"dummy\"";
      append fmt "build: [ \"mirage\" \"build\" ]";
      append fmt "synopsis: \"This is a dummy\"";
      R.ok ())
    "opam file"

let opam_name name target =
  String.concat ~sep:"-" ["mirage"; "unikernel"; name; target]

let unikernel_opam_name name target =
  let target_str = Fmt.strf "%a" Key.pp_target target in
  opam_name name target_str

let solo5_manifest_path = "_build/manifest.json"

let generate_manifest_json () =
  Log.info (fun m -> m "generating manifest");
  let networks = List.map (fun n -> (n, `Network))
    !Mirage_impl_network.all_networks in
  let blocks = Hashtbl.fold (fun k _v acc -> (k, `Block) :: acc)
      Mirage_impl_block.all_blocks [] in
  let to_string (name, typ) =
    Fmt.strf {json|{ "name": %S, "type": %S }|json}
      name
      (match typ with `Network -> "NET_BASIC" | `Block -> "BLOCK_BASIC") in
  let devices = List.map to_string (networks @ blocks) in
  let s = String.concat ~sep:", " devices in
  let open Codegen in
  let file = Fpath.(v solo5_manifest_path) in
  with_output file (fun oc () ->
      let fmt = Format.formatter_of_out_channel oc in
      append fmt
{json|{
  "type": "solo5.manifest",
  "version": 1,
  "devices": [ %s ]
}
|json} s;
      R.ok ())
    "Solo5 application manifest file"

let clean_manifest () =
  Bos.OS.File.delete Fpath.(v solo5_manifest_path)

let configure i =
  let name = Info.name i in
  let root = Fpath.to_string (Info.build_dir i) in
  let ctx = Info.context i in
  let target = Key.(get ctx target) in
  Log.info (fun m -> m "Configuring for target: %a" Key.pp_target target);
  let opam_name = unikernel_opam_name name target in
  let target_debug = Key.(get ctx target_debug) in
  if target_debug && target <> `Hvt then
    Log.warn (fun m -> m "-g not supported for target: %a" Key.pp_target target);
  configure_myocamlbuild () >>= fun () ->
  configure_opam ~name:opam_name i >>= fun () ->
  let no_depext = Key.(get ctx no_depext) in
  configure_makefile ~no_depext ~opam_name >>= fun () ->
  (match target with
    | #Mirage_key.mode_solo5 -> generate_manifest_json ()
    | _ -> R.ok ()) >>= fun () ->
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
  let value =
    Fmt.strf "%s/share/pkgconfig:%s/lib/pkgconfig%s"
      prefix prefix pkg_config_fallback
  in
  Bos.OS.Env.set_var var (Some value) >>= fun () ->
  let cmd = Bos.Cmd.(v "pkg-config" % pkgs %% of_list args) in
  Bos.OS.Cmd.run_out cmd |> Bos.OS.Cmd.out_string >>| fun (data, _) ->
  String.cuts ~sep:" " ~empty:false data

let solo5_pkg = function
  | `Virtio -> "solo5-bindings-virtio", ".virtio"
  | `Muen -> "solo5-bindings-muen", ".muen"
  | `Hvt -> "solo5-bindings-hvt", ".hvt"
  | `Genode -> "solo5-bindings-genode", ".genode"
  | `Spt -> "solo5-bindings-spt", ".spt"
  | _ ->
    invalid_arg "solo5 bindings only defined for solo5 targets"

let cflags pkg = pkg_config pkg ["--cflags"]

let generate_manifest_c () =
  let json = solo5_manifest_path in
  let c = "_build/manifest.c" in
  let cmd = Bos.Cmd.(v "solo5-elftool" % "gen-manifest" % json % c)
  in
  Bos.OS.Dir.create Fpath.(v "_build") >>= fun _created ->
  Log.info (fun m -> m "executing %a" Bos.Cmd.pp cmd);
  Bos.OS.Cmd.run cmd

let compile_manifest target =
  let pkg, _post = solo5_pkg target in
  let c = "_build/manifest.c" in
  let obj = "_build/manifest.o" in
  cflags pkg >>= fun cflags ->
  let cmd = Bos.Cmd.(v "cc" %% of_list cflags % "-c" % c % "-o" % obj)
  in
  Log.info (fun m -> m "executing %a" Bos.Cmd.pp cmd);
  Bos.OS.Cmd.run cmd

let compile ignore_dirs libs warn_error target =
  let tags =
    [ Fmt.strf "predicate(%s)" (backend_predicate target);
      "warn(A-4-41-42-44)";
      "debug";
      "bin_annot";
      "strict_sequence";
      "principal";
      "safe_string" ] @
    (if warn_error then ["warn_error(+1..49)"] else []) @
    (match target with `MacOSX | `Unix -> ["thread"] | _ -> []) @
    (if terminal () then ["color(always)"] else [])
  and result = match target with
    | #Mirage_key.mode_unix -> "main.native"
    | #Mirage_key.mode_xen | #Mirage_key.mode_solo5 -> "main.native.o"
  and cflags = [ "-g" ]
  and lflags =
    let dontlink =
      match target with
      | #Mirage_key.mode_xen | #Mirage_key.mode_solo5 ->
        ["unix"; "str"; "num"; "threads"]
      | #Mirage_key.mode_unix -> []
    in
    let dont = List.map (fun k -> [ "-dontlink" ; k ]) dontlink in
    "-g" :: List.flatten dont
  in
  let concat = String.concat ~sep:"," in
  let ignore_dirs = match ignore_dirs with
    | [] -> Bos.Cmd.empty
    | dirs  -> Bos.Cmd.(v "-Xs" % concat dirs)
  in
  let want_quiet_build = match Logs.level () with
  | Some Info | Some Debug -> false
  | _ -> true
  in
  let cmd = Bos.Cmd.(v "ocamlbuild" % "-use-ocamlfind" %
                     "-classic-display" %%
                     on want_quiet_build (v "-quiet") %
                     "-tags" % concat tags %
                     "-pkgs" % concat libs %
                     "-cflags" % concat cflags %
                     "-lflags" % concat lflags %
                     "-tag-line" % "<static*.*>: warn(-32-34)" %%
                     ignore_dirs %
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

let static_libs pkg_config_deps =
  pkg_config pkg_config_deps [ "--static" ; "--libs" ]

let ldflags pkg = pkg_config pkg ["--variable=ldflags"]

let ldpostflags pkg = pkg_config pkg ["--variable=ldpostflags"]

let find_ld pkg =
  match pkg_config pkg ["--variable=ld"] with
  | Ok (ld::_) ->
    Log.info (fun m -> m "using %s as ld (pkg-config %s --variable=ld)" ld pkg);
    ld
  | Ok [] ->
    Log.warn
      (fun m -> m "pkg-config %s --variable=ld returned nothing, using ld" pkg);
    "ld"
  | Error msg ->
    Log.warn (fun m -> m "error %a while pkg-config %s --variable=ld, using ld"
                 Rresult.R.pp_msg msg pkg);
    "ld"

let link info name target _target_debug =
  let libs = Info.libraries info in
  match target with
  | #Mirage_key.mode_unix ->
    let link = Bos.Cmd.(v "ln" % "-nfs" % "_build/main.native" % name) in
    Bos.OS.Cmd.run link >>= fun () ->
    Ok name
  | #Mirage_key.mode_xen ->
    extra_c_artifacts "xen" libs >>= fun c_artifacts ->
    static_libs "mirage-xen" >>= fun static_libs ->
    let linker =
      Bos.Cmd.(v "ld" % "-d" % "-static" % "-nostdlib" %
               "_build/main.native.o" %%
               of_list c_artifacts %%
               of_list static_libs)
    in
    let out = name ^ ".xen" in
    let uname_cmd = Bos.Cmd.(v "uname" % "-m") in
    Bos.OS.Cmd.(run_out uname_cmd |> out_string) >>= fun (machine, _) ->
    if String.is_prefix ~affix:"arm" machine then begin
      (* On ARM:
         - we must convert the ELF image to an ARM boot executable zImage,
           while on x86 we leave it as it is.
         - we need to link libgcc.a (otherwise we get undefined references to:
           __aeabi_dcmpge, __aeabi_dadd, ...) *)
      let libgcc_cmd = Bos.Cmd.(v "gcc" % "-print-libgcc-file-name") in
      Bos.OS.Cmd.(run_out libgcc_cmd |> out_string) >>= fun (libgcc, _) ->
      let elf = name ^ ".elf" in
      let link = Bos.Cmd.(linker % libgcc % "-o" % elf) in
      Log.info (fun m -> m "linking with %a" Bos.Cmd.pp link);
      Bos.OS.Cmd.run link >>= fun () ->
      let objcopy_cmd = Bos.Cmd.(v "objcopy" % "-O" % "binary" % elf % out) in
      Bos.OS.Cmd.run objcopy_cmd  >>= fun () ->
      Ok out
    end else begin
      let link = Bos.Cmd.(linker % "-o" % out) in
      Log.info (fun m -> m "linking with %a" Bos.Cmd.pp link);
      Bos.OS.Cmd.run link >>= fun () ->
      Ok out
    end
  | #Mirage_key.mode_solo5 ->
    let pkg, post = solo5_pkg target in
    extra_c_artifacts "freestanding" libs >>= fun c_artifacts ->
    static_libs "mirage-solo5" >>= fun static_libs ->
    ldflags pkg >>= fun ldflags ->
    ldpostflags pkg >>= fun ldpostflags ->
    let out = name ^ post in
    let ld = find_ld pkg in
    let linker =
      Bos.Cmd.(v ld %% of_list ldflags % "_build/main.native.o" %
               "_build/manifest.o" %%
               of_list c_artifacts %% of_list static_libs % "-o" % out
               %% of_list ldpostflags)
    in
    Log.info (fun m -> m "linking with %a" Bos.Cmd.pp linker);
    Bos.OS.Cmd.run linker >>= fun () ->
    Ok out

let check_entropy libs =
  query_ocamlfind ~recursive:true libs >>= fun ps ->
  if List.mem "nocrypto" ps && not (Mirage_impl_random.is_entropy_enabled ()) then
    R.error_msg
      {___|The \"nocrypto\" library is loaded but entropy is not enabled!@ \
       Please enable the entropy by adding a dependency to the nocrypto \
       device. You can do so by adding ~deps:[abstract nocrypto] \
       to the arguments of Mirage.foreign.|___}
  else
    R.ok ()

let ignore_dirs = ["_build-solo5-hvt"; "_build-ukvm"]

let build i =
  let name = Info.name i in
  let ctx = Info.context i in
  let warn_error = Key.(get ctx warn_error) in
  let target = Key.(get ctx target) in
  let libs = Info.libraries i in
  let target_debug = Key.(get ctx target_debug) in
  check_entropy libs >>= fun () ->
  compile ignore_dirs libs warn_error target >>= fun () ->
  (match target with
    | #Mirage_key.mode_solo5 ->
        generate_manifest_c () >>= fun () ->
        compile_manifest target
    | _ -> R.ok ()) >>= fun () ->
  link i name target target_debug >>| fun out ->
  Log.info (fun m -> m "Build succeeded: %s" out)

let clean_opam name target =
  Bos.OS.File.delete (opam_file (unikernel_opam_name name target))

let clean_binary name suffix =
  Bos.OS.File.delete Fpath.(v name + suffix)

let clean i =
  let rec rr_iter f l =
    match l with
    | [] -> R.ok ()
    | x :: l -> f x >>= fun () -> rr_iter f l
  in
  let name = Info.name i in
  clean_main_xl ~name "xl" >>= fun () ->
  clean_main_xl ~name "xl.in" >>= fun () ->
  clean_main_xe ~name >>= fun () ->
  clean_main_libvirt_xml ~name >>= fun () ->
  clean_myocamlbuild () >>= fun () ->
  clean_manifest () >>= fun () ->
  Bos.OS.File.delete Fpath.(v "Makefile") >>= fun () ->
  rr_iter (clean_opam name)
    [`Unix; `MacOSX; `Xen; `Qubes; `Hvt; `Spt; `Virtio; `Muen; `Genode]
  >>= fun () ->
  Bos.OS.File.delete Fpath.(v "main.native.o") >>= fun () ->
  Bos.OS.File.delete Fpath.(v "main.native") >>= fun () ->
  Bos.OS.File.delete Fpath.(v name) >>= fun () ->
  rr_iter (clean_binary name)
    ["xen"; "elf"; "hvt"; "spt"; "virtio"; "muen"; "genode"]
  >>= fun () ->
  (* The following deprecated names are kept here to allow "mirage clean" to
   * continue to work after an upgrade. *)
  Bos.OS.File.delete Fpath.(v "Makefile.solo5-hvt") >>= fun () ->
  Bos.OS.Dir.delete ~recurse:true Fpath.(v "_build-solo5-hvt") >>= fun () ->
  Bos.OS.File.delete Fpath.(v "solo5-hvt") >>= fun () ->
  Bos.OS.File.delete (opam_file (opam_name name "ukvm")) >>= fun () ->
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
  let ignore_dirs = ignore_dirs

  let create jobs = impl @@ object
      inherit base_configurable
      method ty = job
      method name = "mirage"
      method module_name = "Mirage_runtime"
      method! keys = [
        Key.(abstract target);
        Key.(abstract warn_error);
        Key.(abstract target_debug);
        Key.(abstract no_depext);
      ]
      method! packages =
        (* XXX: use %%VERSION_NUM%% here instead of hardcoding a version? *)
        let min = "3.5.0" and max = "3.6.0" in
        let common = [
          package ~build:true ~min:"4.05.0" "ocaml";
          package "lwt";
          package ~min ~max "mirage-types-lwt";
          package ~min ~max "mirage-types";
          package ~min ~max "mirage-runtime" ;
          package ~build:true ~min ~max "mirage" ;
          package ~build:true "ocamlfind" ;
          package ~build:true "ocamlbuild" ;
        ] in
        Key.match_ Key.(value target) @@ function
        | #Mirage_key.mode_unix ->
          package ~min:"3.1.0" ~max:"4.0.0" "mirage-unix" :: common
        | #Mirage_key.mode_xen ->
          package ~min:"3.1.0" ~max:"5.0.0" "mirage-xen" :: common
        | #Mirage_key.mode_solo5 as tgt ->
          package ~min:"0.6.0" ~max:"0.7.0" ~ocamlfind:[] (fst (solo5_pkg tgt)) ::
          package ~min:"0.6.0" ~max:"0.7.0" "mirage-solo5" ::
          common

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
  | _ , None -> acc
  | None, Some x -> Some [x]
  | Some acc, Some x -> Some (acc @ [x])

let register
    ?(argv=default_argv) ?tracing ?(reporter=default_reporter ())
    ?keys ?packages
    name jobs =
  let argv = Some [Functoria_app.keys argv] in
  let reporter = if reporter == no_reporter then None else Some reporter in
  let init = argv ++ reporter ++ tracing in
  register ?keys ?packages ?init name jobs
