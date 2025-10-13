FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " file://platform-top.h file://bsp.cfg file://0001-add-default-environment.patch "
