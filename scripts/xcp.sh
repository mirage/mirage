#!/bin/bash
# Build a mirage VM on Xen Cloud Platform

set -e

function usage () {
    echo "Usage:"
    echo "   `basename $0` [-x <xenserver host>] [-s <sr-uuid to place vdi>] <kernel name>"
}

function on_exit () {
    echo " *** Caught an error! Cleaning up."
    if [ -n "${VBD}" ]; then
        echo "Destroying VBD ${VBD}"
        ${SUDO} umount ${MNT}
        ${XE} vbd-unplug uuid=${VBD}
        ${XE} vbd-destroy uuid=${VBD}
    fi
    if [ -n "${VDI}" ]; then
        echo "Destroying VDI ${VDI}"
        ${XE} vdi-destroy uuid=${VDI}
    fi
    if [ -n "${MIRAGE_VM}" ]; then
        echo "Destroying mirage VM ${MIRAGE_VM}"
        ${XE} vm-destroy uuid=${MIRAGE_VM}
    fi
    if [ -e "${MENU_LST}" ]; then
        echo "Removing ${MENU_LST}"
        rm ${MENU_LST}
    fi
    if [ -e "${KERNEL_PATH}.gz" ]; then
        echo "Uncompressing ${KERNEL_PATH}"
        gunzip "${KERNEL_PATH}.gz"
    fi
    echo "Quitting"
}

while getopts ":x:u:s:" option
do
    case $option in
        x ) DOM0_HOST=${OPTARG} ;;
        s ) SR_UUID=${OPTARG} ;;
        : ) usage
            echo "Option -${OPTARG} requires an argument."
            exit 1;;
        '?' ) usage
            echo "Invalid option -${OPTARG}."
            exit 1 ;;
    esac
done

# Kernel name will be first unprocessed arguement remaining
ARGS=($@)
KERNEL_PATH=${ARGS[${OPTIND}-1]}

# Required args: kernel name, and (if -x then also -u)
if [ -z ${KERNEL_PATH} ]; then
    usage
    echo 'Missing kernel name.'
    exit 1
fi

KERNEL_NAME=$(basename ${KERNEL_PATH})
MNT='/mnt'
SUDO='sudo'
MENU_LST='menu.lst'

# Set XE command depending on whether we're in dom0 or domU
if [ -z "${DOM0_HOST}" ]; then
    XE="xe"
else
    XE="xe -s ${DOM0_HOST}"
    if [ ! -e ${HOME}/.xe ]; then
	echo Please add username= and password= lines to ${HOME}/.xe
	exit 1
    fi
fi

MY_VM=$(xenstore-read vm | cut -f 3 -d /)

echo "Using xe command '${XE}', this VM's uuid is ${MY_VM}"

# Default to local SR
if [ -z "${SR_UUID}" ]; then
    SR_UUID=$(${XE} sr-list name-label="Local storage" --minimal)
fi
echo "Using SR ${SR_UUID}"

# Set error handler trap to clean up after an error
trap on_exit EXIT

# Write grub conf to disk
echo "default 0" > ${MENU_LST}
echo "timeout 1" >> ${MENU_LST}
echo "title Mirage" >> ${MENU_LST}
echo " root (hd0)" >> ${MENU_LST}
echo " kernel /boot/${KERNEL_NAME}.gz" >> ${MENU_LST}

# Gzip kernel image
gzip ${KERNEL_PATH}

# Calculate necessary size of VDI
SIZE=0
for i in $(ls -s -1 -k ${KERNEL_PATH}.gz ${MENU_LST} | awk '{print $1}')
do
    SIZE=$((i + SIZE))
done
SIZE=${SIZE}KiB

echo "VDI size will be ${SIZE}"

# Create VDI
VDI=$(${XE} vdi-create name-label="${KERNEL_NAME}-vdi" sharable=true \
   type=user virtual-size=${SIZE} sr-uuid=${SR_UUID})
echo "Created VDI ${VDI}"

# Create VBD (with vdi and this vm)
VBD_DEV=$(${XE} vm-param-get uuid=${MY_VM} \
    param-name=allowed-VBD-devices | cut -f 1 -d \;)
VBD=$(${XE} vbd-create vm-uuid=${MY_VM} vdi-uuid=$VDI device=${VBD_DEV} type=Disk)
echo "Created VBD ${VBD} as virtual device number ${VBD_DEV}"

# Plug VBD
${XE} vbd-plug uuid=${VBD}

# Mount vdi disk
XVD=(a b c d e f g h i j k l m n)
XVD_="xvd${XVD[${VBD_DEV}]}"
echo "Making ext3 filesystem on /dev/${XVD_}"
mke2fs -q -j /dev/${XVD_}
echo "Mounting /dev/${XVD_} at ${MNT}"
${SUDO} mount -t ext3 /dev/${XVD_} ${MNT}

# Copy grub conf to vdi disk
${SUDO} mkdir -p ${MNT}/boot/grub
${SUDO} mv ${MENU_LST} ${MNT}/boot/grub/${MENU_LST}

# Copy kernel image to vdi disk
${SUDO} cp ${KERNEL_PATH}.gz ${MNT}/boot/${KERNEL_NAME}.gz
gunzip ${KERNEL_PATH}

echo "Wrote ${MENU_LST} and copied kernel to ${MNT}/boot"

# Unmount and unplug vbd
${SUDO} umount ${MNT}
${XE} vbd-unplug uuid=${VBD}
${XE} vbd-destroy uuid=${VBD}

echo "Unmounted /dev/${XVD_} and destroyed VBD ${VBD}."

# Create mirage vm
MIRAGE_VM=$(${XE} vm-install template="Other install media" new-name-label="${KERNEL_NAME}")
${XE} vm-param-set uuid=${MIRAGE_VM} PV-bootloader=pygrub
${XE} vm-param-set uuid=${MIRAGE_VM} HVM-boot-policy=
${XE} vm-param-clear uuid=${MIRAGE_VM} param-name=HVM-boot-params

# Attach vdi to mirage vm and make bootable
VBD_DEV=$(${XE} vm-param-get uuid=${MIRAGE_VM} \
    param-name=allowed-VBD-devices | cut -f 1 -d \;)
VBD=$(${XE} vbd-create vm-uuid=${MIRAGE_VM} vdi-uuid=${VDI} device=${VBD_DEV} type=Disk)
${XE} vbd-param-set uuid=$VBD bootable=true

# Turn off error handling
trap - EXIT

echo "Created VM ${KERNEL_NAME}: ${MIRAGE_VM}"
