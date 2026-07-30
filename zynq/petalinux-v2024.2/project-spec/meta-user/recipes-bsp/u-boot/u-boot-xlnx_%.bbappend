FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " file://platform-top.h file://bsp.cfg file://default.env"

do_configure:prepend() {
    cp ${WORKDIR}/default.env ${S}/default.env
}
