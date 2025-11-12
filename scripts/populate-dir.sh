#!/bin/bash

## change here tftp and support directories
TFTPDIR="/srv/tftp"
SUPPORTDIR="/opt/support"
##

if [ $# -eq 0 ]; then
   echo "E: specify release number as argument"
   exit
fi

release=$1

echo "Populate $TFTPDIR and $SUPPORTDIR with mpmt-board release $release"

mkdir -p $SUPPORTDIR/sama 2>/dev/null
mkdir -p $TFTPDIR/mpmt 2>/dev/null
mkdir -p $TFTPDIR/mpmt/zynq/default/led $TFTPDIR/mpmt/zynq/default/plain $TFTPDIR/mpmt/zynq/rfs-images 2>/dev/null
mkdir -p $TFTPDIR/mpmt/sama 2>/dev/null

baseurl="https://github.com/gtortone/mpmt-board/releases/download/$release/"

# ZYNQ

zynq_files=(
"image.ub"
"BOOT.BIN"
)

zynq_rfs_files=(
"zynq-mpmt-debian.tar.gz"
"zynq-mpmt-debian.tar.lz4"
)

for filename in ${zynq_files[@]}; do
   echo -n "copying $filename in $TFTPDIR/mpmt/zynq/default..."
   /usr/bin/wget -O $TFTPDIR/mpmt/zynq/default/$filename $baseurl/$filename 2>/dev/null 
   if [ $? -eq 0 ]; then
      echo " DONE"
   else 
      echo " FAIL!"
      rm $TFTPDIR/mpmt/zynq/default/$filename
   fi
done

for filename in ${zynq_rfs_files[@]}; do
   echo -n "copying $filename in $TFTPDIR/mpmt/zynq/rfs-images..."
   /usr/bin/wget -O $TFTPDIR/mpmt/zynq/rfs-images/$filename $baseurl/$filename 2>/dev/null 
   if [ $? -eq 0 ]; then
      echo " DONE"
   else 
      echo " FAIL!"
      rm $TFTPDIR/mpmt/zynq/rfs-images/$filename
   fi
done

# SAMA

sama_tftp_files=(
"at91-sama5d27_som1_ek.dtb"
"at91-sama5d27-zImage"
"sama-mpmt-image-sama5d27-som1-ek-sd.rootfs.cpio.gz.u-boot"
)

sama_support_files_1=(
"at91bootstrap.bin"
"at91-sama5d27-u-boot.bin"
)

sama_support_files_2=(
"at91-sama5d27-rootfs.wic"
)

for filename in ${sama_tftp_files[@]}; do
   echo -n "copying $filename in $TFTPDIR/mpmt/sama..."
   localfilename=`echo $filename | sed s/"\.u-boot"// | sed s/"at91-sama5d27-"// | sed s/"sama-mpmt-image-sama5d27-som1-ek-sd."//` 
   /usr/bin/wget -O $TFTPDIR/mpmt/sama/$localfilename $baseurl/$filename 2>/dev/null 
   if [ $? -eq 0 ]; then
      echo " DONE"
   else 
      echo " FAIL!"
      rm $TFTPDIR/mpmt/sama/$filename
   fi
done 

for filename in ${sama_support_files_1[@]}; do
   echo -n "copying $filename in $SUPPORTDIR/sama..."
   localfilename=`echo $filename | sed s/"\.u-boot"// | sed s/"at91-sama5d27-"//` 
   /usr/bin/wget -O $SUPPORTDIR/sama/$localfilename $baseurl/$filename 2>/dev/null 
   if [ $? -eq 0 ]; then
      echo " DONE"
   else 
      echo " FAIL!"
      rm $SUPPORTDIR/sama/$filename
   fi
done 

for filename in ${sama_support_files_2[@]}; do
   echo -n "copying $filename in $SUPPORTDIR/sama..."
   /usr/bin/wget -O $SUPPORTDIR/sama/$filename $baseurl/$filename 2>/dev/null 
   if [ $? -eq 0 ]; then
      echo " DONE"
   else 
      echo " FAIL!"
      rm $SUPPORTDIR/sama/$filename
   fi
done 

