SUMMARY = "MPMT board Linux scripts"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"
SRC_URI = "file://dot-bashrc \
           file://gpio.sh\
          "

S = "${WORKDIR}"

do_install() {
   install -d ${D}/home/root
   install -m 0644 ${S}/dot-bashrc ${D}/home/root/.profile
   install -d ${D}/usr/bin
   install -m 0644 ${S}/gpio.sh ${D}/usr/bin
}

FILES:${PN} = "/"
