#!/bin/bash

# exit at first error 
set -euo pipefail

if [[ $# -eq 0 ]]; then
   echo "E: specify suite to build"
   exit 1
fi

SUITE=$1
OUTDIR_SUFFIX=images

case "$SUITE" in
   bookworm)
      VERSION=12
      ;;
   trixie)
      VERSION=13
      ;;
   *)
      echo "E: suites available: bookworm, trixie"
      exit
      ;;
esac

OUTDIR=${OUTDIR_SUFFIX}/${SUITE}

mkdir -p ${OUTDIR}

echo "suite: ${SUITE}"
echo "outdir: ${OUTDIR}"

###

PL_PROJECT_BASE=~/devel/HyperK/PROD-ZYNQ7/petalinux/pl-mpmt/images/linux
TMPDIR=$PL_PROJECT_BASE/tmp

echo "extract Linux kernel modules from PetaLinux rootfs..."
mkdir $TMPDIR
tar -C $TMPDIR -xzvf $PL_PROJECT_BASE/rootfs.tar.gz ./lib/modules
tar -C $TMPDIR -czf overlays/boot/modules.tar.gz lib 
rm -rf $TMPDIR

echo "copy PetaLinux files..."
#cp $PL_PROJECT_BASE/zImage overlays/boot
#cp $PL_PROJECT_BASE/system.dtb overlays/boot
cp $PL_PROJECT_BASE/image.ub overlays/boot

echo "clean staging directory..."
sudo rm -rf overlays/staging/*

echo "start Linux Debian ${SUITE} image build..."
sudo debos \
   -t outdir:${OUTDIR} \
   -t image:zynq-mpmt-debian-${SUITE}.img \
   -t suite:${SUITE} \
   -t version:${VERSION} \
   --cpus=8 \
   --disable-fakemachine debimage-zynq-mpmt.yaml

sudo losetup -D

sudo chown -R ${USER}:${USER} ${OUTDIR_SUFFIX}

echo "prepare RAUC bundle content..."
cp ${OUTDIR}/rootfs.ext4 bundle-content

echo "Bye!"
