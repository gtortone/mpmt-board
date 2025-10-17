SUMMARY = "setup-scripts"
SECTION = "PETALINUX/apps"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://run_tasks \
	   file://runtasks \
	   file://functions.sh \
	   file://deploy_emmc_rootfs \
	   file://deploy_qspi_bootbin \
	   file://deploy_qspi_fitimage \
	   file://deploy_qspi_userdata \
	   file://config.env \
"

inherit update-rc.d

S = "${WORKDIR}"

INITSCRIPT_NAME = "runtasks"
INITSCRIPT_PARAMS = "defaults 90 10"

do_install() {
   install -d ${D}/opt/setup-scripts
   install -m 0755 run_tasks ${D}/opt/setup-scripts
   install -m 0644 functions.sh ${D}/opt/setup-scripts
   install -m 0755 deploy_emmc_rootfs ${D}/opt/setup-scripts
   install -m 0755 deploy_qspi_bootbin ${D}/opt/setup-scripts
   install -m 0755 deploy_qspi_fitimage ${D}/opt/setup-scripts
   install -m 0755 deploy_qspi_userdata ${D}/opt/setup-scripts
   install -d ${D}/etc/init.d
   install -m 0755 runtasks ${D}/etc/init.d
}

FILES:${PN} = "/"
