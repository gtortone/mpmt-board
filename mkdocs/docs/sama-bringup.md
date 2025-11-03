# SAMA bring-up

## Introduction

To bring-up SAMA with a Linux operating system user will run SAM-BA to write bootloader on QSPI flash and Linux root filesystem on external eMMC. At the end of bring-up process the default boot order will be redefined to configure SAMA to boot always from external eMMC.

## SAM-BA

SAM-BA tool is required to properly bring-up SAMA. SAM-BA software provides an open set of tools for in-system programming of internal and external memories connected to 32bit MCUs and MPUs.

SAM-BA is available on Microchip [website](https://www.microchip.com/en-us/development-tool/SAM-BA-In-system-Programmer).

!!! note
    SAM-BA can be used only if SAMA is in "SAM-BA mode", in this case SAM-BA tool can interact with board using [JSAMA1](hardware.md#on-board-connectors) micro-USB connector.

Some useful SAM-BA commands to inspect SAMA configuration:

```bash title="get current boot configuration"
sam-ba -x ./examples/sama5d2/boot-config/show-boot-config.qml
```

```shell title="get current fuses configuration"
sam-ba -x ./examples/sama5d2/fuse/sama5d2-fuse.qml
```

## Boot order

SAMA boot order is handled by 4 registers:

* BUREG0
* BUREG1
* BUREG2
* BUREG3

Register `BSCR` contains the index of `BUREG` register to apply while `FUSE#16` contains permanent boot order.

Default value of `FUSE#16` set QSPI flash as first boot device, this will be changed at the end of SAMA bring-up process.

## Hardware preparation

!!! warning
    Be sure to follow these steps before start bring-up process otherwise SAM-BA tool will not communicate with SAMA board.

1. connect USB cable on [JSAMA1](hardware.md#on-board-connectors) connector
1. move [JT3](hardware.md#on-board-jumpers) jumper to position 1-2 (external eMMC enabled)
1. move [JT4](hardware.md#on-board-jumpers) jumper to position 2-3 (QSPI disabled)
1. power-on board
1. move [JT4](hardware.md#on-board-jumpers) jumper to position 1-2 (QSPI enabled)

After last step SAM-BA bootloader is listening for commands.

## QSPI setup

Required files available from latest [mpmt-board release](https://github.com/gtortone/mpmt-board/releases/latest):

* [at91bootstrap.bin](https://github.com/gtortone/mpmt-board/releases/latest/download/at91bootstrap.bin)
* [u-boot.bin](https://github.com/gtortone/mpmt-board/releases/latest/download/at91-sama5d27-u-boot.bin)

### Installation steps

```shell title="erase QSPI flash"
sam-ba -p usb -b sama5d27-som1-ek -a qspiflash -c erase
```

```shell title="write AT91bootstrap"
sam-ba -p usb -b sama5d27-som1-ek -a qspiflash -c writeboot:at91bootstrap.bin -c verifyboot:at91bootstrap.bin
```

```shell title="write U-Boot"
sam-ba -p usb -b sama5d27-som1-ek -a qspiflash -c write:u-boot.bin:0x00040000 -c verify:u-boot.bin:0x00040000
```

## eMMC setup

Required rootfs file is available from latest [mpmt-board release](https://github.com/gtortone/mpmt-board/releases/latest):

* [at91-sama5d27-rootfs.wic](https://github.com/gtortone/mpmt-board/releases/latest/download/at91-sama5d27-rootfs.wic)

### Installation steps

```shell title="write Linux root filesystem"
sam-ba -p usb -b sama5d27-som1-ek -a sdmmc -c write:at91-sama5d27-rootfs.wic
```

## Permanent write of boot order

After QSPI setup and eMMC setup set QSPI flash as first boot device writing `FUSE#16`

```shell
sam-ba -p usb -b sama5d27-som1-ek -a bootconfig -c writecfg:fuse:0x00460ff7
```

## Post-installation steps

After QSPI and eMMC setup it is possible to use [JDEB1](hardware.md#on-board-connectors) header to connect a USB-UART adapter to view whole Linux boot process. At the end of boot a Linux login prompt is also provided on same UART.

## Applications

### Control commands

#### ftdi
* `ftdi 0`: disable FTDI controller
* `ftdi 1`: enable FTDI controller

#### jtag
* `jtag 0`: disable JTAG transceiver
* `jtag 1`: enable JTAG transceiver

#### fpga
* `fpga r`: reset FPGA

### xc3sprog: FPGA programming from SAMA

Using [JTAG bus](hardware.md#communication-bus) it is possible to reprogram FPGA using `xc3sprog` on SAMA.

xc3sprog is a suite of utilities for programming Xilinx FPGAs, CPLDs, and EEPROMs with the Xilinx Parallel Cable and other JTAG adapters under Linux.

!!! note
    In order to use JTAG tools enable FTDI adapter and JTAG bus using these [commands](sama-bringup.md#control-commands):
    ```
    ftdi 1
    jtag 1
    ```

```shell title="JTAG boundary scan"
xc3sprog -c ftdi
```

```shell title="program bitstream (.bit)"
xc3sprog -c ftdi file.bit -p 1 -v
```

```shell title="program bitstream (.bin)"
xc3sprog -c ftdi file.bin:w:w:0:BIN -p 1 -v
```

### xvc-adaptive: Xilinx Virtual Cable

[xvc-adaptive](https://github.com/gtortone/xvc-adaptive) is a Xilinx Virtual Cable (XVC) daemon with calibration features to compensate TDO propagation delay on long cables. It can also be used as general XVC service on embedded devices.

```shell title="start XVC server"
xvcServer --driver FTDI --cfreq 15000000 --interface 2
```

!!! note
    The alias `start_xvc` is also available as helper to start xvc-adaptive with default parameters.

## Advanced options

### Network operating system boot

In order to boot Linux operating system from network some files (device tree, Linux kernel image and minimal root filesystem) are needed. U-Boot can fetch during network boot these files using TFTP protocol, so a deployment server is needed to use this feature.

lonnect a USB-UART adapter on [JDEB1](hardware.md#on-board-connectors), open serial console using a terminal emulation software and power-on the board. Interrupt U-Boot autoboot hitting a key after U-Boot banner and start network boot script:

```shell
run bootnet
```

If everything goes fine a Linux login prompt will be displayed on UART console.

### SAMA upgrade in-place without using SAM-BA

If SAM-BA cannot be used (micro USB connector is not accessible) it is possible to upgrade SAMA
following these steps.

!!! note
    Make sure deployment server is up with running TFTP server and SAMA related files are in mpmt/sama
    directory.

Connect to Zynq and open SAMA UART console:

```
minicom -D /dev/ttyUL1
```

Reboot Linux and interrupt U-Boot countdown hitting a key.

Flash SAMA QSPI with AT91bootstrap and U-Boot fetching them from deployment server and reset
at end:

```
dhcp

sf probe

sf erase 0 0x800000

tftpboot 0x21100000 mpmt/sama/at91bootstrap.bin
sf write 0x21100000 0 ${filesize}

tftpboot 0x21A00000 mpmt/sama/u-boot.bin
sf write 0x21A00000 0x00040000 ${filesize}

reset
```

Interrupt U-Boot countdown hitting a key and start SAMA network boot:

```
run bootnet
```

Login to Linux and start netcat to receive root filesystem image from network:

```
nc -l -p 1234 | dd bs=16M of=/dev/mmcblk0
```

On deployment server send root filesystem image to SAMA:

```
dd bs=16M if=at91-sama5d27-rootfs.wic | nc <sama_ip_addr> 1234
```

Reboot Linux and wait for SAMA automatic boot from eMMC:

```
sync ; reboot
```

