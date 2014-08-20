#!/usr/bin/env bash
# Build an EC2 bundle and upload/register it to Amazon.


NAME=mirage
BUCKET=mirage-deployment
REGION=us-west-2
while getopts "hn:b:r:k:" arg; do
 case $arg in
 h)
   echo "usage: $0 [-h] [-n <name>] [-b <bucket>] [-r <region>] -k <unikernel> " 
   echo ""
   echo "<unikernel>: Name of the kernel file (e.g. mir-www.xen)"
   echo "<name>: the application name to use (default: ${NAME})"
   echo "<bucket>: the S3 bucket to upload to (default: ${BUCKET})"
   echo "<region>: the EC2 region to register AMI in (default: ${REGION})"
  
   echo Remember to set each of the following environment variables in your
   echo environment before running this script:
   echo EC2_ACCESS, EC2_ACCESS_SECRET, EC2_CERT, EC2_PRIVATE_KEY
   exit 1 ;;
 n) NAME=$OPTARG ;;
 b) BUCKET=$OPTARG ;;
 r) REGION=$OPTARG ;;
 k) APP=$OPTARG ;;
 esac
done

if [ ! -e "$APP" ]; then
  echo "Must specify a unikernel file with the [-k] flag."
  echo "Run '$0 -h' for full option list."
  exit 1
fi

# Make name unique to avoid registration clashes
NAME=${NAME}-`date +%s`
MNT=/tmp/mirage-ec2
SUDO=sudo
IMG=${NAME}.img

echo Name  : ${NAME}
echo Bucket: ${BUCKET}
echo Region: ${REGION}

set -e
# KERNEL is ec2-describe-images -o amazon --region ${REGION} -F "manifest-location=*pv-grub-hd0*" -F "architecture=x86_64" | tail -1 | cut -f2
# Also obtained from http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/UserProvidedKernels.html
KERNEL=aki-fc8f11cc  #us-west-2

${SUDO} mkdir -p ${MNT}
rm -f ${IMG}
dd if=/dev/zero of=${IMG} bs=1M count=5
${SUDO} mke2fs -F -j ${IMG}
${SUDO} mount -o loop ${IMG} ${MNT}

${SUDO} mkdir -p ${MNT}/boot/grub
echo default 0 > menu.lst
echo timeout 1 >> menu.lst
echo title Mirage >> menu.lst
echo " root (hd0)" >> menu.lst
echo " kernel /boot/mirage-os.gz" >> menu.lst
${SUDO} mv menu.lst ${MNT}/boot/grub/menu.lst
${SUDO} sh -c "gzip -c $APP > ${MNT}/boot/mirage-os.gz"
${SUDO} umount -d ${MNT}

rm -rf ec2_tmp
mkdir ec2_tmp

echo Bundling image...
ec2-bundle-image -i ${IMG} -k ${EC2_PRIVATE_KEY} -c ${EC2_CERT} -u ${EC2_USER} -d ec2_tmp -r x86_64 --kernel ${KERNEL}
echo Uploading image...
ec2-upload-bundle -b ${BUCKET} -m ec2_tmp/${IMG}.manifest.xml -a ${EC2_ACCESS} -s ${EC2_ACCESS_SECRET} --location ${REGION}
echo Registering image...
id=`ec2-register ${BUCKET}/${IMG}.manifest.xml -n ${NAME} --region ${REGION} | awk '{print $2}'`
rm -rf ec2_tmp
rm -f ${IMG}

echo You can now start this instance via:
echo ec2-run-instances --region ${REGION} $id
echo ""
echo Don\'t forget to customise this with a security group, as the
echo default one won\'t let any inbound traffic in.
