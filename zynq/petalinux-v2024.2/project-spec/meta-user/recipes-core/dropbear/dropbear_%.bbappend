
SRC_URI += " \
   file://dropbear_rsa_host_key \
"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# copy default SSH key
# allow root login
do_install:append() {
   install -m 0600 ${WORKDIR}/dropbear_rsa_host_key ${D}${sysconfdir}/dropbear
   rm ${D}${sysconfdir}/default/dropbear
}
