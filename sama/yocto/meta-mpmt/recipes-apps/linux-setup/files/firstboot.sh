#!/bin/sh
#
# SPDX-License-Identifier: GPL-2.0-only
#

### BEGIN INIT INFO
# Provides:          firstboot
# Required-Start:    $remote_fs $all
# Required-Stop:
# Default-Start:     2 3 4 5
# Default-Stop:
# Short-Description: Expand root partition to full space
# Description:       This script expands root partition (/) to full space
### END INIT INFO

if test -f /firstboot
then

   echo "- +" | /usr/sbin/sfdisk -N 2 /dev/mmcblk0 --force --no-reread
   /usr/sbin/partprobe
   /sbin/resize2fs /dev/mmcblk0p2
   rm /firstboot

fi

: exit 0
