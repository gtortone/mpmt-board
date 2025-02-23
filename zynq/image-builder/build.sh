#!/bin/bash

DEBIAN_RELEASE=12
PL_PROJECT_BASE=~/devel/HyperK/PROD-ZYNQ7/petalinux/pl-mpmt/images/linux
TMPDIR=$PL_PROJECT_BASE/tmp

echo "extract Linux kernel modules from PetaLinux rootfs..."
mkdir $TMPDIR
tar -C $TMPDIR -xzvf $PL_PROJECT_BASE/rootfs.tar.gz ./lib/modules
tar -C $TMPDIR -czf overlays/boot/modules.tar.gz lib 
rm -rf $TMPDIR

echo "copy PetaLinux files..."
cp $PL_PROJECT_BASE/zImage overlays/boot
cp $PL_PROJECT_BASE/system.dtb overlays/boot

echo "start Linux image build..."
sudo debos -t image:zynq-mpmt-debian$DEBIAN_RELEASE.img --cpus=8 --disable-fakemachine debimage-zynq-mpmt.yaml

sudo losetup -D
