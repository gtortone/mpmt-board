DESCRIPTION = "A Linux image for SAMA5D2 module on MPMT board."
LICENSE = "MIT"
PR = "r1"

IMAGE_FEATURES += " ssh-server-dropbear"

MACHINE_FEATURES:remove = "touchscreen"
MACHINE_FEATURES:remove = "apm"
MACHINE_FEATURES:remove = "alsa"

IMAGE_LINGUAS = "en-us"
GLIBC_GENERATE_LOCALES = "en_US.UTF-8"

IMAGE_FSTYPES = "ext3 tar.gz cpio.gz cpio.gz.u-boot wic"
WKS_FILE = "sdimage-bootpart.wks"

IMAGE_BOOT_FILES = "zImage at91-sama5d27_som1_ek.dtb"

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
    jtag-scripts \
    xc3sprog \
    xvc-adaptive \
    mtd-utils \
    openocd \
    util-linux-sfdisk \
    e2fsprogs-resize2fs \
    netcat \
    parted \
    ntp \
    iperf3 \
    ${CORE_IMAGE_EXTRA_INSTALL} \
    "

inherit core-image
