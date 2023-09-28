#!/bin/sh

echo "- +" | sfdisk -N 2 /dev/mmcblk0 --force
partprobe
resize2fs /dev/mmcblk0p1

systemctl disable firstboot.service
rm -f /etc/systemd/system/firstboot.service
rm -f /firstboot.sh
