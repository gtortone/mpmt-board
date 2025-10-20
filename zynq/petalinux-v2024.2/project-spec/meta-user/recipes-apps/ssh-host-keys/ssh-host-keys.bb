SUMMARY = "ssh-host-keys"
SECTION = "PETALINUX/apps"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI += " \
   file://ssh_host_ecdsa_key \
   file://ssh_host_ecdsa_key.pub \
   file://ssh_host_ed25519_key \
   file://ssh_host_ed25519_key.pub \
   file://ssh_host_rsa_key \
   file://ssh_host_rsa_key.pub \
   file://authorized_keys \
"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

S = "${WORKDIR}"

do_install() {
   install -d ${D}${sysconfdir}/ssh
   install -m 0600 ${WORKDIR}/ssh_host_ecdsa_key ${D}${sysconfdir}/ssh
   install -m 0600 ${WORKDIR}/ssh_host_ed25519_key ${D}${sysconfdir}/ssh
   install -m 0600 ${WORKDIR}/ssh_host_rsa_key ${D}${sysconfdir}/ssh
   install -m 0644 ${WORKDIR}/ssh_host_ecdsa_key.pub ${D}${sysconfdir}/ssh
   install -m 0644 ${WORKDIR}/ssh_host_ed25519_key.pub ${D}${sysconfdir}/ssh
   install -m 0644 ${WORKDIR}/ssh_host_rsa_key.pub ${D}${sysconfdir}/ssh

   install -d ${D}/home/root/.ssh
   install -m 0644 ${WORKDIR}/authorized_keys ${D}/home/root/.ssh
}

FILES:${PN} = "/"
FILES:${PN} += "/home/root"
FILES:${PN} += "/home/root/.ssh"
FILES:${PN} += "/home/root/.ssh/authorized_keys"
