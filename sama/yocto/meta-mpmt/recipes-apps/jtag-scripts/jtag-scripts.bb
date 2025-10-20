SUMMARY = "MPMT JTAG scripts"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"
SRC_URI = "file://ft2232h.cfg \
           file://ft232h.cfg \
           file://functions.cfg \
           file://init.cfg \
           file://load-u-boot.cfg \
           file://ps7_init.tcl \
           file://system.bit \
           file://u-boot-dtb.elf \
           file://uEnv.txt \
           file://xilinx-tcl.cfg \
           file://zynq-mpmt.cfg \
           file://boot-zynq.sh \
          "
RDEPENDS:${PN} = "openocd bash"

S = "${WORKDIR}"

do_install() {
   install -d ${D}/opt/jtag-scripts

   install -m 0644 ${S}/ft2232h.cfg ${D}/opt/jtag-scripts
   install -m 0644 ${S}/ft232h.cfg ${D}/opt/jtag-scripts
   install -m 0644 ${S}/functions.cfg ${D}/opt/jtag-scripts
   install -m 0644 ${S}/init.cfg ${D}/opt/jtag-scripts
   install -m 0644 ${S}/load-u-boot.cfg ${D}/opt/jtag-scripts
   install -m 0644 ${S}/ps7_init.tcl ${D}/opt/jtag-scripts
   install -m 0644 ${S}/uEnv.txt ${D}/opt/jtag-scripts
   install -m 0644 ${S}/xilinx-tcl.cfg ${D}/opt/jtag-scripts
   install -m 0644 ${S}/zynq-mpmt.cfg ${D}/opt/jtag-scripts

   install -m 0644 ${S}/system.bit ${D}/opt/jtag-scripts
   install -m 0644 ${S}/u-boot-dtb.elf ${D}/opt/jtag-scripts

   install -m 0755 ${S}/boot-zynq.sh ${D}/opt/jtag-scripts
}

FILES:${PN} = "/"

