open Astring
open Functoria_app.Codegen

let rec string_of_int26 x =
  let high, low = x / 26 - 1, x mod 26 + 1 in
  let high' = if high = -1 then "" else string_of_int26 high in
  let low' =
    String.v ~len:1
      (fun _ -> char_of_int (low + (int_of_char 'a') - 1))
  in
  high' ^ low'

(* We need the Linux version of the block number (this is a
   strange historical artifact) Taken from
   https://github.com/mirage/mirage-block-xen/blob/
   a64d152586c7ebc1d23c5adaa4ddd440b45a3a83/lib/device_number.ml#L128 *)
let vdev number =
  Fmt.strf "xvd%s" (string_of_int26 number)

let output_main_xl fmt ~name ~kernel ~memory ~blocks ~networks =
  let block_strings =
    List.map
      (fun (number, path) ->
        Fmt.strf "'format=raw, vdev=%s, access=rw, target=%s'" (vdev number) path)
      blocks
  in
  let network_strings =
    List.map
    (fun n -> Fmt.strf "'bridge=%s'" n)
    networks
  in
  append fmt "# %s" (generated_header ()) ;
  newline fmt;
  append fmt "name = '%s'" name;
  append fmt "kernel = '%s'" kernel;
  append fmt "builder = 'linux'";
  append fmt "memory = %s" memory;
  append fmt "on_crash = 'preserve'";
  newline fmt;
  append fmt "disk = [ %s ]" (String.concat ~sep:", " block_strings);
  newline fmt;
  append fmt "# if your system uses openvswitch then either edit \
              /etc/xen/xl.conf and set";
  append fmt "#     vif.default.script=\"vif-openvswitch\"";
  append fmt "# or add \"script=vif-openvswitch,\" before the \"bridge=\" \
              below:";
  append fmt "vif = [ %s ]" (String.concat ~sep:", " network_strings)

let output_main_xe fmt ~root ~name ~blocks =
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
  List.iter
    (fun (filename, number) ->
      append fmt "echo Uploading data VDI %s" filename;
      append fmt "echo VDI=$VDI";
      append fmt "SIZE=$(stat --format '%%s' %s/%s)" root filename;
      append fmt "POOL=$(xe pool-list params=uuid --minimal)";
      append fmt "SR=$(xe pool-list uuid=$POOL params=default-SR --minimal)";
      append fmt "VDI=$(xe vdi-create type=user name-label='%s' \
                  virtual-size=$SIZE sr-uuid=$SR)" filename;
      append fmt "xe vdi-import uuid=$VDI filename=%s/%s" root filename;
      append fmt "VBD=$(xe vbd-create vm-uuid=$VM vdi-uuid=$VDI device=%d)" number;
      append fmt "xe vbd-param-set uuid=$VBD other-config:owner=true")
    blocks;
  append fmt "echo Starting VM";
  append fmt "xe vm-start uuid=$VM"

let output_main_libvirt_xml fmt ~root ~name =
  let open Functoria_app.Codegen in
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
  append fmt "</domain>"

let output_virtio_libvirt_xml fmt ~root ~name =
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
  append fmt "</domain>"

let output_opam fmt ~name ~info =
  append fmt "# %s" (generated_header ());
  Functoria.Info.opam ~name fmt info;
  append fmt "maintainer: \"dummy\"";
  append fmt "authors: \"dummy\"";
  append fmt "homepage: \"dummy\"";
  append fmt "bug-reports: \"dummy\"";
  append fmt "build: [ \"mirage\" \"build\" ]"

let output_fat fmt ~block_file ~root ~dir ~regexp =
  append fmt "#!/bin/sh";
  append fmt "";
  append fmt "echo This uses the 'fat' command-line tool to \
              build a simple FAT";
  append fmt "echo filesystem image.";
  append fmt "";
  append fmt "FAT=$(which fat)";
  append fmt "if [ ! -x \"${FAT}\" ]; then";
  append fmt "  echo I couldn\\'t find the 'fat' command-line \
              tool.";
  append fmt "  echo Try running 'opam install fat-filesystem'";
  append fmt "  exit 1";
  append fmt "fi";
  append fmt "";
  append fmt "IMG=$(pwd)/%s" block_file;
  append fmt "rm -f ${IMG}";
  append fmt "cd %a" Fpath.pp (Fpath.append root dir);
  append fmt "SIZE=$(du -s . | cut -f 1)";
  append fmt "${FAT} create ${IMG} ${SIZE}KiB";
  append fmt "${FAT} add ${IMG} %s" regexp;
  append fmt "echo Created '%s'" block_file

let output_makefile fmt ~opam_name =
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
    opam_name opam_name opam_name opam_name

let string_of_expr e =
  let open Migrate_parsetree in
  let migrate = Versions.migrate (module OCaml_404) (module OCaml_current) in
  Format.asprintf "%a" Pprintast.expression @@
  migrate.Versions.copy_expression e

let ident lid =
  Ast_404.Ast_helper.Exp.ident @@
  Location.mknoloc lid

let in_module ~modname s =
  ident @@
  Longident.Ldot (Lident modname, s)

let qrexec_qubes_connect ~modname =
  string_of_expr
  [%expr
     [%e in_module ~modname "connect"] ~domid:0 () >>= fun qrexec ->
     Lwt.async (fun () ->
         OS.Lifecycle.await_shutdown_request () >>= fun _ ->
         [%e in_module ~modname "disconnect"] qrexec);
     Lwt.return (`Ok qrexec)
  ]

let gui_qubes_connect ~modname =
  string_of_expr
  [%expr
     [%e in_module ~modname "connect"] ~domid:0 () >>= fun gui ->
     Lwt.async (fun () -> [%e in_module ~modname "listen"] gui);
     Lwt.return (`Ok gui)
  ]

let conduit_with_connectors_connect ~connectors =
  let bind x f = [%expr [%e x] >>= [%e f]] in
  let init = [%expr fun t -> Lwt.return t] in
  let go connector acc = bind (ident (Longident.Lident connector)) acc in
  string_of_expr @@
  bind [%expr Lwt.return Conduit_mirage.empty] @@
  List.fold_right go connectors init

let resolver_dns_conf_connect ~ns ~ns_port ~modname ~stack =
  let meta_ipv4 ppf s = Fmt.pf ppf "(Ipaddr.V4.of_string_exn %S)" (Ipaddr.V4.to_string s) in
  let meta_ns = Fmt.Dump.option meta_ipv4 in
  let meta_port = Fmt.(Dump.option int) in
  Fmt.strf
    "let ns = %a in@;\
     let ns_port = %a in@;\
     let res = %s.R.init ?ns ?ns_port ~stack:%s () in@;\
     Lwt.return res@;"
    meta_ns ns meta_port ns_port modname stack
