#!/bin/sh

docker run --rm -v $ARTIFACTDIR/overlays/staging:/staging ghcr.io/gtortone/debian-cross-arm:$1 \
sh -c '
cd /opt
git clone https://github.com/gtortone/libToolDAQ.git
cd libToolDAQ

TFC_REPO_TAG=ed687ea
TDF_REPO_TAG=ca5d429
TDI_REPO_TAG=9983067

cmake -B build-arm -DCMAKE_TOOLCHAIN_FILE=cmake/toolchain-arm-linux-gnueabihf.cmake \
   -DTFC_REPO_TAG=$TFC_REPO_TAG -DTDF_REPO_TAG=$TDF_REPO_TAG -DTDI_REPO_TAG=$TDI_REPO_TAG \
   -DCMAKE_INSTALL_PREFIX=/ -DCMAKE_INSTALL_LIBDIR=/lib
make -j -C build-arm
make -C build-arm DESTDIR=/staging install

rm -rf build-arm

cmake -B build-arm -DCMAKE_TOOLCHAIN_FILE=cmake/toolchain-arm-linux-gnueabihf.cmake \
   -DTFC_REPO_TAG=$TFC_REPO_TAG -DTDF_REPO_TAG=$TDF_REPO_TAG -DTDI_REPO_TAG=$TDI_REPO_TAG
make -j -C build-arm
make -C build-arm install

mkdir -p /staging/opt
cd /staging/opt
git clone https://git.hyperk.org/hyperk-online/mpmt/m-pmt-daq-interface.git
cd m-pmt-daq-interface

cmake -B build-arm -DCMAKE_TOOLCHAIN_FILE=/opt/libToolDAQ/cmake/toolchain-arm-linux-gnueabihf.cmake
make -j -C build-arm
'
