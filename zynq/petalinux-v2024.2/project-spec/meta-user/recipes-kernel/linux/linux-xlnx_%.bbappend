FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " file://bsp.cfg"

SRC_URI += "file://0001-xilinx-dma-decrease-timeout-used-to-stop-DMA.patch \
            "
