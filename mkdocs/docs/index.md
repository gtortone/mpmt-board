# Introduction

The multi PhotoMultiplier (mPMT) board is a mainboard that will be used for [HyperK](https://www-sk.icrr.u-tokyo.ac.jp/en/h) experiment in Japan.

mPMT board includes several submodules and provides two embedded Linux boards:

- a supervisor (SAMA) based on [ATSAMA5D27](https://www.microchip.com/wwwproducts/en/ATSAMA5D27) processor.

- a [Zynq](https://www.amd.com/en/products/adaptive-socs-and-fpgas/soc/zynq-7000.html) 7000 SoC that integrates the software programmability of an Arm-based processor with the hardware programmability of an FPGA dedicated for acquisition and slow control tasks.

The main purpose of this documentation is to offer a guide to bring-up these two Linux systems (SAMA and ZYNQ).
