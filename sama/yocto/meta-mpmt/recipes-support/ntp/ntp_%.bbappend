FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://ntp.conf"

do_install:append() {
   install -m 644 ${WORKDIR}/ntp.conf ${D}${sysconfdir}
}
