DESCRIPTION = "suite of utilities for programming Xilinx FPGAs, CPLDs, and EEPROMs"
LICENSE = "GPL-2.0-only"
HOMEPAGE = "http://sourceforge.net/projects/xc3sprog"
SECTION = "console/utils"
LIC_FILES_CHKSUM = "file://LICENSE;md5=a9733ac0f64cafbe8fde6926ebb70249"

DEPENDS = "libftdi libusb"
RDEPENDS:${PN} = "libftdi libusb1"

SRC_URI = "svn://svn.code.sf.net/p/xc3sprog/code;module=trunk;protocol=https"
SRCREV = "r795"

S = "${WORKDIR}/trunk"

inherit cmake pkgconfig
