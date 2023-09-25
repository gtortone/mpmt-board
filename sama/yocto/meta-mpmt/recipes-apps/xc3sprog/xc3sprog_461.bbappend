FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

LOCALDIR := "${THISDIR}"

SRC_URI += "file://0001-fix-build-on-Atmel-SAMA5D27.patch"
SRC_URI += "file://cablelist.txt"
SRC_URI += "file://devlist.txt"

do_install:append() {
   install -d ${D}/etc/${PN}
   cp ${LOCALDIR}/${PN}/devlist.txt ${D}/etc/${PN}
   cp ${LOCALDIR}/${PN}/cablelist.txt ${D}/etc/${PN}
}
