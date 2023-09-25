LOCALDIR := "${THISDIR}"

do_configure:prepend() {
   cp "${LOCALDIR}/files/default-uEnv.txt" "${B}"
   cp "${LOCALDIR}/files/sama5d27_som1_ek_mmc_defconfig" "${B}/configs"
}

