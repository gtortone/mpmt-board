SUMMARY = "MPMT board Linux scripts"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"
SRC_URI = "file://dot-bashrc \
           file://gpio.sh\
           file://firstboot.sh\
           file://firstboot\
          "

inherit update-rc.d

S = "${WORKDIR}"

INITSCRIPT_NAME = "firstboot.sh"
INITSCRIPT_PARAMS = "defaults 90 10"

do_install() {
   install -d ${D}/home/root
   install -m 0644 ${S}/dot-bashrc ${D}/home/root/.profile
   install -d ${D}/usr/bin
   install -m 0644 ${S}/gpio.sh ${D}/usr/bin
   install -m 0644 ${S}/firstboot ${D}/
   install -d ${D}/etc/init.d
   install -m 0755 ${S}/firstboot.sh ${D}/etc/init.d
}

FILES:${PN} = "/"
