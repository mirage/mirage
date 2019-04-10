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
open Sexplib

module Key = Mirage_key
module Name = Functoria_app.Name
module Codegen = Functoria_app.Codegen

module Log = Mirage_impl_misc.Log
open Mirage_impl_misc

include Functoria

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

let fn = Fpath.(v "dune")

let terminal () =
  let dumb = try Sys.getenv "TERM" = "dumb" with Not_found -> true in
  let isatty = try Unix.(isatty (descr_of_out_channel Pervasives.stdout)) with
    | Unix.Unix_error _ -> false
  in
  not dumb && isatty

let ignore_dirs = ["_build-solo5-hvt"; "_build-ukvm"]

let custom_runtime = function
  | `Xen | `Qubes -> Some "xen"
  | `Virtio | `Hvt | `Muen | `Genode  -> None
  | _ -> None

let variant_of_target = function
  | `Xen | `Qubes -> "xen"
  | `Virtio | `Hvt | `Muen | `Genode  -> "freestanding"
  | _ -> "unix"

let sxp_of_fmt fmt = Fmt.kstrf Sexp.of_string fmt

let config_unix ~name ~binary_location ~target =
  let target_name = Fmt.strf "%a" Key.pp_target target in
  let alias = sxp_of_fmt {|
    (alias
      (name %s)
      (deps %s))
    |} target_name name
  in
  let rule = sxp_of_fmt {|
    (rule
      (targets %s)
      (deps %s)
      (mode promote)
      (action (run ln -nfs %s %s)))
  |} name binary_location binary_location name
  in
  Ok [alias; rule]


(* On ARM:
        - we must convert the ELF image to an ARM boot executable zImage,
          while on x86 we leave it as it is.
        - we need to link libgcc.a (otherwise we get undefined references to:
          __aeabi_dcmpge, __aeabi_dadd, ...) *)
let config_xen_arm ~out ~linker_command ~binary_location =
  let elf = out ^ ".elf" in
  let libgcc_cmd = Bos.Cmd.(v "gcc" % "-print-libgcc-file-name") in
  Bos.OS.Cmd.(run_out libgcc_cmd |> out_string) >>= fun (libgcc, _) ->
  let rule_link = sxp_of_fmt {|
    (rule
      (targets %s)
      (deps %s)
      (action (run %s %s -o %s)))
    |} elf binary_location linker_command libgcc elf
  and rule_obj_copy = sxp_of_fmt {|
    (rule
      (mode promote)
      (targets %s)
      (deps %s)
      (action (run objcopy -O binary %s %s)))
  |} out elf elf out
  in
  Ok [rule_link; rule_obj_copy]

let config_xen_default ~out ~linker_command ~binary_location =
  let rule = sxp_of_fmt {|
    (rule
      (mode promote)
      (targets %s)
      (deps %s)
      (action (run %s -o %s)))
  |} out binary_location linker_command out
  in
  Ok [rule]

let config_xen ~name ~binary_location ~target =
  let target_name = Fmt.strf "%a" Key.pp_target target in
  let out = name ^ ".xen" in
  let alias = sxp_of_fmt {|
    (alias
      (name %s)
      (deps %s))
  |} target_name out
  in
  let linker_command = "ld -d -static -nostdlib "^binary_location
  in
  let uname_cmd = Bos.Cmd.(v "uname" % "-m") in
  Bos.OS.Cmd.(run_out uname_cmd |> out_string) >>= fun (machine, _) ->
  match String.is_prefix ~affix:"arm" machine with
  | true -> config_xen_arm ~out ~linker_command ~binary_location
  | false -> config_xen_default ~out ~linker_command ~binary_location
  >>= fun rules ->
  let rule_libs = sxp_of_fmt "(rule (copy %%{lib:mirage-xen-ocaml:libs} libs))"
  in
  Ok (rule_libs::alias::rules)

let solo5_pkg = function
  | `Virtio -> "solo5-bindings-virtio", ".virtio"
  | `Muen -> "solo5-bindings-muen", ".muen"
  | `Hvt -> "solo5-bindings-hvt", ".hvt"
  | `Genode -> "solo5-bindings-genode", ".genode"
  | `Unix | `MacOSX | `Xen | `Qubes ->
    invalid_arg "solo5_kernel only defined for solo5 targets"

let config_solo5_hvt i ~name ~binary_location =
  let _, post = solo5_pkg `Hvt in
  (* Generate target alias *)
  let out = name ^ post in
  let alias = sxp_of_fmt {|
    (alias
      (name hvt)
      (deps solo5-hvt %s))
  |} out
  in
  (* Generate solo5-hvt rules*)
  let ctx = Info.context i in
  let libs = Info.libraries i in
  let target_debug = Key.(get ctx target_debug) in
  let tender_mods =
    List.fold_left (fun acc -> function
        | "mirage-net-solo5" -> "net" :: acc
        | "mirage-block-solo5" -> "blk" :: acc
        | _ -> acc)
      [] libs @ (if target_debug then ["gdb"] else [])
  in
  let tender_mods = String.concat ~sep:" " tender_mods in
  let rule_solo5_makefile = sxp_of_fmt {|
      (rule
        (targets Makefile.solo5-hvt)
        (action (run solo5-hvt-configure %%{read:libdir} %s)))
    |} tender_mods
  in
  let rule_solo5_hvt = sxp_of_fmt {|
    (rule
      (targets solo5-hvt)
      (deps Makefile.solo5-hvt)
      (mode promote)
      (action (run make -f Makefile.solo5-hvt solo5-hvt)))
  |}
  in
  (* Generate unikernel linking rule*)
  let rule_unikernel = sxp_of_fmt {|
    (rule
      (targets %s)
      (mode promote)
      (deps %s)
      (action (run %%{read-lines:ld} %%{read-lines:ldflags} %s -o %s)))
  |} out
     binary_location
     binary_location out
  in
  Ok [alias; rule_solo5_makefile; rule_solo5_hvt; rule_unikernel]

let config_solo5_default ~name ~binary_location ~target =
  let _, post = solo5_pkg target in
  (* Generate target alias *)
  let out = name ^ post in
  let alias = sxp_of_fmt {|
    (alias
      (name %a)
      (deps %s))
  |} Key.pp_target target
     out
  in
  (* Generate unikernel linking rule*)
  let rule_unikernel = sxp_of_fmt {|
    (rule
      (targets %s)
      (mode promote)
      (deps %s)
      (action (run %%{read-lines:ld} %%{read-lines:ldflags} %s -o %s)))
  |} out
     binary_location
     binary_location out
  in
  Ok [alias; rule_unikernel]

let config_solo5 i ~name ~binary_location ~target =
  (match target with
  | `Hvt -> config_solo5_hvt i ~name ~binary_location
  | _ -> config_solo5_default ~name ~binary_location ~target)
  >>= fun base_rules ->
  let rule_libs = sxp_of_fmt "(rule (copy %%{lib:ocaml-freestanding:libs} libs))" in
  let rule_ldflags = sxp_of_fmt "(rule (copy %%{lib:ocaml-freestanding:ldflags} ldflags))" in
  let rule_ld = sxp_of_fmt "(rule (copy %%{lib:ocaml-freestanding:ld} ld))" in
  let rule_libdir = sxp_of_fmt "(rule (copy %%{lib:ocaml-freestanding:libdir} libdir))"
  in
  Ok (rule_ldflags::rule_libs::rule_libdir::rule_ld::base_rules)

let configure_postbuild_rules i ~name ~binary_location ~target =
  match target with
  | `Unix | `MacOSX -> config_unix ~name ~binary_location ~target
  | `Xen | `Qubes -> config_xen ~name ~binary_location ~target
  | `Virtio | `Muen | `Hvt | `Genode -> config_solo5 i ~name ~binary_location ~target

let target_file = function
  | `Unix | `MacOSX -> "main.exe"
  | _ -> "main.exe.o"

let configure_dune i =
  let ctx = Info.context i in
  let warn_error = Key.(get ctx warn_error) in
  let target = Key.(get ctx target) in
  let custom_runtime = custom_runtime target in
  let libs = Info.libraries i in
  let name = Info.name i in
  let binary_location = target_file target in
  let cflags = [
      "-g";
      "-w";
      "+A-4-41-42-44";
      "-bin-annot";
      "-strict-sequence";
      "-principal";
      "-safe-string" ] @
      (if warn_error then ["-warn-error"; "+1..49"] else []) @
      (match target with `MacOSX | `Unix -> ["-thread"] | _ -> []) @
      (if terminal () then ["-color"; "always"] else []) @
      (match custom_runtime with Some runtime -> ["-runtime-variant"; runtime] | _ -> [])
  and lflags = "-g"::(match target with
    | `Xen | `Qubes | `Virtio | `Muen | `Hvt | `Genode -> ["(:include libs)"]
    | _ -> [])
  in
  let s_output_mode = match target with
    | `Unix | `MacOSX -> "(native exe)"
    | _ -> "(native object)"
  in
  let s_libraries = String.concat ~sep:" " libs in
  let s_link_flags = String.concat ~sep:" " lflags in
  let s_compilation_flags = String.concat ~sep:" " cflags in
  let s_variants = variant_of_target target
  in
  let config = sxp_of_fmt {|
    (executable
      (name main)
      (modes %s)
      (libraries %s)
      (link_flags %s)
      (flags %s)
      (variants %s))
  |} s_output_mode
     s_libraries
     s_link_flags
     s_compilation_flags
     s_variants
  in
  configure_postbuild_rules i ~name ~binary_location ~target >>= fun rules ->
  let rules = config::rules in
  Bos.OS.File.write_lines
    fn
    (List.map (fun x -> (Sexp.to_string_hum x)^"\n") rules)


(* we made it, so we should clean it up *)
let clean_dune () = Bos.OS.File.delete fn

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
  configure_dune i >>= fun () ->
  configure_opam ~name:opam_name i >>= fun () ->
  let no_depext = Key.(get ctx no_depext) in
  configure_makefile ~no_depext ~opam_name >>= fun () ->
  match target with
  | `Xen ->
    configure_main_xl "xl" i >>= fun () ->
    configure_main_xl ~substitutions:[] "xl.in" i >>= fun () ->
    configure_main_xe ~root ~name >>= fun () ->
    configure_main_libvirt_xml ~root ~name
  | `Virtio ->
    configure_virtio_libvirt_xml ~root ~name
  | _ -> R.ok ()

let cross_compile = function
  | _ -> None

let compile target =
  let target_name = Fmt.strf "%a" Key.pp_target target in
  let cmd = match cross_compile target with
  | None ->         Bos.Cmd.(v "dune" % "build" % ("@"^target_name) )
  | Some backend -> Bos.Cmd.(v "dune" % "build" % ("@"^target_name) % "-x" % backend)
  in
  Log.info (fun m -> m "executing %a" Bos.Cmd.pp cmd);
  Bos.OS.Cmd.run cmd


let link _info _name _target _target_debug = Ok ()
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


let build i =
  let name = Info.name i in
  let ctx = Info.context i in
  let target = Key.(get ctx target) in
  let libs = Info.libraries i in
  let target_debug = Key.(get ctx target_debug) in
  check_entropy libs >>= fun () ->
  compile target >>= fun () ->
  link i name target target_debug >>| fun () ->
  Log.info (fun m -> m "Build succeeded")

let clean i =
  let name = Info.name i in
  clean_main_xl ~name "xl" >>= fun () ->
  clean_main_xl ~name "xl.in" >>= fun () ->
  clean_main_xe ~name >>= fun () ->
  clean_main_libvirt_xml ~name >>= fun () ->
  clean_dune () >>= fun () ->
  Bos.OS.File.delete Fpath.(v "Makefile") >>= fun () ->
  Bos.OS.File.delete (opam_file (unikernel_opam_name name `Hvt)) >>= fun () ->
  Bos.OS.File.delete (opam_file (unikernel_opam_name name `Unix)) >>= fun () ->
  Bos.OS.File.delete (opam_file (unikernel_opam_name name `Xen)) >>= fun () ->
  Bos.OS.File.delete (opam_file (unikernel_opam_name name `Qubes)) >>= fun () ->
  Bos.OS.File.delete (opam_file (unikernel_opam_name name `Muen)) >>= fun () ->
  Bos.OS.File.delete (opam_file (unikernel_opam_name name `MacOSX)) >>= fun () ->
  Bos.OS.File.delete (opam_file (unikernel_opam_name name `Genode)) >>= fun () ->
  Bos.OS.File.delete Fpath.(v "main.native.o") >>= fun () ->
  Bos.OS.File.delete Fpath.(v "main.native") >>= fun () ->
  Bos.OS.File.delete Fpath.(v name) >>= fun () ->
  Bos.OS.File.delete Fpath.(v name + "xen") >>= fun () ->
  Bos.OS.File.delete Fpath.(v name + "elf") >>= fun () ->
  Bos.OS.File.delete Fpath.(v name + "virtio") >>= fun () ->
  Bos.OS.File.delete Fpath.(v name + "muen") >>= fun () ->
  Bos.OS.File.delete Fpath.(v name + "hvt") >>= fun () ->
  Bos.OS.File.delete Fpath.(v name + "genode") >>= fun () ->
  Bos.OS.File.delete Fpath.(v "Makefile.solo5-hvt") >>= fun () ->
  Bos.OS.Dir.delete ~recurse:true Fpath.(v "_build-solo5-hvt") >>= fun () ->
  Bos.OS.File.delete Fpath.(v "solo5-hvt") >>= fun () ->
  (* The following deprecated names are kept here to allow "mirage clean" to
   * continue to work after an upgrade. *)
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
          package ~build:true ~min:"4.04.2" "ocaml";
          package "lwt";
          package ~min ~max "mirage-types-lwt";
          package ~min ~max "mirage-types";
          package ~min ~max "mirage-runtime" ;
          package ~build:true ~min ~max "mirage" ;
          package ~build:true "ocamlfind" ;
          package ~build:true "dune" ;
        ] in
        Key.match_ Key.(value target) @@ function
        | `Unix | `MacOSX ->
          package ~min:"3.1.0" ~max:"4.0.0" "mirage-unix" :: common
        | `Xen | `Qubes ->
          package ~min:"3.1.0" ~max:"4.0.0" "mirage-xen" :: common
        | `Virtio | `Hvt | `Muen | `Genode as tgt ->
          package ~min:"0.4.0" ~max:"0.5.0" ~ocamlfind:[] (fst (solo5_pkg tgt)) ::
          package ~min:"0.5.0" ~max:"0.6.0" "mirage-solo5" ::
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

(* TODO: ideally we'd combine these *)
let qrexec_init = match_impl Key.(value target) [
  `Qubes, Mirage_impl_qrexec.qrexec_qubes;
] ~default:Functoria_app.noop

let gui_init = match_impl Key.(value target) [
  `Qubes, Mirage_impl_gui.gui_qubes;
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
