#!/bin/bash

if [ $# -eq 0 ]; then
   echo "E: specify release number as argument"
   exit
fi

release=$1

echo "Populate /srv/tftp with mpmt-board release $release"

mkdir -p /srv/tftp/mpmt /srv/tftp/mpmt/zynq /srv/tftp/mpmt/sama 2>/dev/null

baseurl="https://github.com/gtortone/mpmt-board/releases/download/$release/"

samafiles=(
"at91-sama5d27_som1_ek.dtb"
"at91-sama5d27-zImage"
"at91-sama5d27-rootfs.cpio.gz.u-boot"
)

zynqfiles=(
"BOOT.BIN"
"system.dtb"
"uImage"
"zImage"
"rootfs.cpio.gz.u-boot"
)

for filename in ${zynqfiles[@]}; do
   echo -n "copying $filename in /srv/tftp/mpmt/zynq..."
   localfilename=`echo $filename | sed s/".u-boot"//`
   /usr/bin/wget -O /srv/tftp/mpmt/zynq/$localfilename $baseurl/$filename 2>/dev/null 
   if [ $? -eq 0 ]; then
      echo " DONE"
   else 
      echo " FAIL!"
      rm /srv/tftp/mpmt/zynq/$filename
   fi
done

for filename in ${samafiles[@]}; do
   echo -n "copying $filename in /srv/tftp/mpmt/sama..."
   localfilename=`echo $filename | sed s/".u-boot"// | sed s/"at91-sama5d27-"//` 
   /usr/bin/wget -O /srv/tftp/mpmt/sama/$localfilename $baseurl/$filename 2>/dev/null 
   if [ $? -eq 0 ]; then
      echo " DONE"
   else 
      echo " FAIL!"
      rm /srv/tftp/mpmt/sama/$filename
   fi
done 


