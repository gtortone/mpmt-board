#!/bin/bash

PROJECT_BASE=~/devel/HyperK/PROD-ATSAMA5D27

echo "copy Linux kernel files..."
cp $PROJECT_BASE/linux-at91/arch/arm/boot/zImage overlays/boot
cp $PROJECT_BASE/linux-at91/arch/arm/boot/dts/at91-sama5d27_som1_ek.dtb overlays/boot
echo "start Linux image build..."
sudo debos --cpus=8 --disable-fakemachine debimage-sama5d2.yaml

sudo losetup -D
