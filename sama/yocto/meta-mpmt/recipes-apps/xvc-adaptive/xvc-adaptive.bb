SUMMARY = "Xilinx XVC server with JTAG adaptive features"
LICENSE = "GPL-3.0-or-later"
LIC_FILES_CHKSUM = "file://LICENSE;md5=1ebbd3e34237af26da5dc08a4e440464"

DEPENDS = "libusb-compat libftdi"
RDEPENDS:${PN} = "libusb1 libftdi"

SRC_URI = "git://github.com/gtortone/xvc-adaptive.git;protocol=http;branch=main"
SRCREV = "2b188fe7fb423b6fff748b466173125f2a69f53e"

S = "${WORKDIR}/git"

do_install() {
   install -d ${D}${bindir} ${D}/etc/xvc-adaptive
   install -m 0755 ${S}/bin/xvcServer ${D}${bindir}
   install -m 0644 ${S}/db/devlist.txt ${D}/etc/xvc-adaptive
}


