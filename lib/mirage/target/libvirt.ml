open Functoria

let filename ~name = Fpath.(v (name ^ "_libvirt") + "xml")
let append fmt s = Fmt.pf fmt (s ^^ "@.")

let configure_main ~name =
  Action.with_output ~path:(filename ~name) ~purpose:"libvirt.xml" (fun fmt ->
      append fmt "<domain type='xen'>";
      append fmt "    <name>%s</name>" name;
      append fmt "    <memory unit='KiB'>262144</memory>";
      append fmt "    <currentMemory unit='KiB'>262144</currentMemory>";
      append fmt "    <vcpu placement='static'>1</vcpu>";
      append fmt "    <os>";
      append fmt "        <type arch='armv7l' machine='xenpv'>linux</type>";
      append fmt "        <kernel>%s.xen</kernel>" name;
      append fmt "        <cmdline> </cmdline>";
      (* the libxl driver currently needs an empty cmdline to be able to
           start the domain on arm - due to this?
           http://lists.xen.org/archives/html/xen-devel/2014-02/msg02375.html *)
      append fmt "    </os>";
      append fmt "    <clock offset='utc' adjustment='reset'/>";
      append fmt "    <on_crash>preserve</on_crash>";
      append fmt "    <!-- ";
      append fmt "    You must define network and block interfaces manually.";
      append fmt
        "    See http://libvirt.org/drvxen.html for information about \
         converting .xl-files to libvirt xml automatically.";
      append fmt "    -->";
      append fmt "    <devices>";
      append fmt "        <!--";
      append fmt "        The disk configuration is defined here:";
      append fmt "        http://libvirt.org/formatstorage.html.";
      append fmt "        An example would look like:";
      append fmt "         <disk type='block' device='disk'>";
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
      append fmt "</domain>")

let configure_virtio ~name =
  Action.with_output ~path:(filename ~name) ~purpose:"libvirt.xml" (fun fmt ->
      append fmt "<domain type='kvm'>";
      append fmt "    <name>%s</name>" name;
      append fmt "    <memory unit='KiB'>262144</memory>";
      append fmt "    <currentMemory unit='KiB'>262144</currentMemory>";
      append fmt "    <vcpu placement='static'>1</vcpu>";
      append fmt "    <os>";
      append fmt "        <type arch='x86_64' machine='pc'>hvm</type>";
      append fmt "        <kernel>%s.virtio</kernel>" name;
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
      append fmt
        "        This example uses a raw file on the host as a block in the \
         guest:";
      append fmt "        <disk type='file' device='disk'>";
      append fmt "            <driver name='qemu' type='raw'/>";
      append fmt "            <source file='/var/lib/libvirt/images/%s.img'/>"
        name;
      append fmt "            <target dev='vda' bus='virtio'/>";
      append fmt "        </disk>";
      append fmt "        -->";
      append fmt "        <!-- ";
      append fmt "        Network configuration reference is here:";
      append fmt "        https://libvirt.org/formatdomain.html#elementsNICS";
      append fmt
        "        This example adds a device in the 'default' libvirt bridge:";
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
      append fmt "</domain>")
