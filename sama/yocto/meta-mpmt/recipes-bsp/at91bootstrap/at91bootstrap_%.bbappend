LOCALDIR := "${THISDIR}"

do_configure:prepend() {
   cp "${LOCALDIR}/files/defconfig" "${B}/.config"
}
