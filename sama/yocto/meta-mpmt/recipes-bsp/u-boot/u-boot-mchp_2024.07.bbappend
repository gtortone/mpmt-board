FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

DEPENDS += " xxd-native"

SRC_URI += "file://0001-config-for-mPMT-board.patch"

