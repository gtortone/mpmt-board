#!/bin/bash

# exit at first error 
set -euo pipefail

SUITE=$1
OUTDIR_SUFFIX=images

case "$SUITE" in
   bookworm|trixie)
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

echo "start Linux Debian ${SUITE} image build..."
sudo debos \
   -t outdir:${OUTDIR} \
   -t image:zynq-mpmt-debian-${SUITE}.img \
   -t suite:${SUITE} \
   --cpus=8 \
   --disable-fakemachine debimage-zynq-mpmt.yaml

sudo losetup -D

sudo chown -R ${USER}:${USER} ${OUTDIR_SUFFIX}

echo "prepare RAUC bundle content..."
cp ${OUTDIR}/rootfs.ext4 bundle-content

echo "Bye!"
