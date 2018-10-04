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
