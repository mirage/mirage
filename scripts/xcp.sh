#!/bin/bash
# Build an XCP VM disk and run it

# Make the XS hostname optional. If it's not present, then assume
# localhost is dom0 and don't do ssh. Otherwise, prepend 'ssh
# ${DOM0_HOST}' to the ${XE} command. Now in the rest of the script,
# we can call ${XE} and it'll automagically run on ssh! Just need to
# make sure we have ssh public keys on dom0.

function usage () {
    echo "Usage:"
    echo "   `basename $0` -k <kernel name> [-x <xenserver host> -u <name of this domU vm>] [-s <sr-uuid to place vdi>]"
    #XSexit 1
}

while getopts "x:k:u:s:" option
do
    case $option in
        x ) DOM0_HOST=${OPTARG} ;;
        k ) KERNEL_PATH=${OPTARG} ;;
        u ) MY_VM_NAME=${OPTARG} ;;
        s ) SR_UUID=${OPTARG} ;;
        * ) usage ; exit 1 ;;
    esac
done

# required args: k, (if x then also u)
if [ -z ${KERNEL_PATH} ]; then
    usage
    echo 'Missing kernel name.'
    exit 1
fi

KERNEL_NAME=$(basename ${KERNEL_PATH})
MNT='/mnt'
SUDO='sudo'
SIZE='10MiB' # TODO: figure this out based on compressed kernel size plus some offset.

# Set XE command depending on whether we're in dom0 or domU
if [ -z "${DOM0_HOST}" ]; then
    XE="xe"
    MY_VM=$(xenstore-read /local/domain/0/vm | cut -f 3 -d /)
else
    SSH="ssh root@${DOM0_HOST}"
    XE="${SSH} xe"
    # if we're not in dom0, then we need the domU vm name
    if [ -z ${MY_VM_NAME} ]; then
        usage
        echo "If we aren't running in dom0, then you need to specify your domU's VM name (not hostname)."
        exit 1
    else
        MY_VM=$(${XE} vm-list name-label=${MY_VM_NAME} --minimal)
    fi
fi

if [ -z "${SR_UUID}" ]; then
    SR_UUID=$(${XE} sr-list name-label=Local\\ storage --minimal)
fi

# Create VDI
VDI=$(${XE} vdi-create name-label=${KERNEL_NAME}-vdi sharable=true \
   type=user virtual-size=${SIZE} sr-uuid=${SR_UUID})

# Create VBD (with vdi and this vm)
VBD_DEV=$(${XE} vm-param-get uuid=${MY_VM} \
    param-name=allowed-VBD-devices | cut -f 1 -d \;)
VBD=$(${XE} vbd-create vm-uuid=${MY_VM} vdi-uuid=$VDI device=${VBD_DEV} type=Disk)

# Plug VBD
${XE} vbd-plug uuid=${VBD}

# mount vdi disk
XVD=('' a b c d e f g h i j k l m n)
XVD_='xvd${XVD[${VBD_DEV}]}'
${SUDO} mke2fs -j /dev/${XVD_}
${SUDO} mount /dev/${XVD_} -t ext3 ${MNT}

# write grub.conf to vdi disk
${SUDO} mkdir -p ${MNT}/boot/grub
echo default 0 > menu.lst
echo timeout 1 >> menu.lst
echo title Mirage >> menu.lst
echo " root (hd0)" >> menu.lst
echo " kernel /boot/${KERNEL_NAME}.gz" >> menu.lst
${SUDO} mv menu.lst ${MNT}/boot/grub/menu.lst

# copy kernel image to vdi disk
gzip ${KERNEL_PATH}
${SUDO} cp ${KERNEL_PATH}.gz ${MNT}/boot/${KERNEL_NAME}.gz

# unmount and unplug vbd
${SUDO} umount ${MNT}
${XE} vbd-unplug uuid=${VBD}
${XE} vbd-destroy uuid=${VBD}

# create mirage vm
MIRAGE_VM=$(xe vm-install template=Other\\ install\\ media new-name-label=${KERNEL_NAME})
xe vm-param-set uuid=${MIRAGE_VM} PV-bootloader=pygrub
xe vm-param-set uuid=${MIRAGE_VM} HVM-boot-policy=
xe vm-param-clear uuid=${MIRAGE_VM} param-name=HVM-boot-params

# attach vdi to mirage vm and make bootable
VBD_DEV=$(${XE} vm-param-get uuid=${MIRAGE_VM} \
    param-name=allowed-VBD-devices | cut -f 1 -d \;)
VBD=$(${XE} vbd-create vm-uuid=${MIRAGE_VM} vdi-uuid=${VDI} device=${VBD_DEV} type=Disk)
xe vbd-param-set uuid=$VBD bootable=true

echo ${MIRAGE_VM}