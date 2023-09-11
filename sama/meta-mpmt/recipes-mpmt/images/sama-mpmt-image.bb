DESCRIPTION = "A Linux image for SAMA5D2 module on MPMT board."
LICENSE = "MIT"
PR = "r1"

IMAGE_FEATURES += " ssh-server-dropbear"

MACHINE_FEATURES:remove = "touchscreen"
MACHINE_FEATURES:remove = "apm"
MACHINE_FEATURES:remove = "alsa"

IMAGE_LINGUAS = "en-us"
GLIBC_GENERATE_LOCALES = "en_US.UTF-8"

PACKAGE_EXCLUDE = "kernel-image-zimage-*"

IMAGE_FSTYPES = "ext3 tar.gz cpio.gz"

IMAGE_INSTALL = "\
    packagegroup-core-boot \
    ssh-pregen-hostkeys \
    socat \
    ser2net \
    minicom \
    screen \
    openocd \
    libusb1 \
    libftdi \
    usbutils \
    linux-setup \
    xc3sprog \
    xvc-adaptive \
    ${CORE_IMAGE_EXTRA_INSTALL} \
    "

inherit core-image
