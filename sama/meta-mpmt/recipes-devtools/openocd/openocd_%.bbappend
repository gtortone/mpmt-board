LICENSE = "GPL-2.0-or-later"
LIC_FILES_CHKSUM = "file://LICENSES/license-rules.txt;md5=8edf9c2b4a8d27750a1fe0ac1b2bd407"

SRCREV_openocd = "9ea7f3d647c8ecf6b0f1424002dfc3f4504a162c"
PV = "0.12+gitr${SRCPV}"

# remove script files

do_install() {
    oe_runmake DESTDIR=${D} install
    if [ -e "${D}${infodir}" ]; then
      rm -Rf ${D}${infodir}
    fi
    if [ -e "${D}${mandir}" ]; then
      rm -Rf ${D}${mandir}
    fi
    if [ -e "${D}${bindir}/.debug" ]; then
      rm -Rf ${D}${bindir}/.debug
    fi
    if [ -e "${D}${datadir}" ]; then
      rm -Rf ${D}${datadir}
    fi

}

FILES:${PN} = " \
  ${bindir}/openocd \
  "
