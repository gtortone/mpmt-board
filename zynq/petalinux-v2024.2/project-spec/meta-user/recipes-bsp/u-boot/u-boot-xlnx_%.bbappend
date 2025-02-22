FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " file://platform-top.h file://bsp.cfg file://0001-add-default-environment.patch"
SRC_URI += "file://user_2025-02-21-16-53-00.cfg"

