# Zynq bring-up

## Requirements

- [SAMA](sama-bringup.md) up and running
- [Deployment server](deployment-server.md) configured and running

## Principle of operations

Installation of Zynq starts from SAMA using [openocd](https://openocd.org) JTAG tool to 'inject' U-Boot bootloader binary in Zynq RAM.
A set of U-Boot environment variables are also injected with openocd in Zynq RAM and used as parameters for Zynq installation and configuration.
Environment variables are passed to Linux operating system using kernel command-line parameters (U-Boot environment variable `bootargs`).

## Setup environment variables

Zynq bring-up scripts are available on SAMA in `/opt/jtag-scripts` directory. Before starting Zynq bring-up user must set configuration
and installation parameters using file `/opt/jtag-scripts/uEnv.txt`.

The following table summarize meaning of `uEnv.txt` variables:

| variable | description | notes |
|----------|-------------| ----- |
| `bootmode` | if equal to `bootmode` U-Boot starts unattended Zynq installation |
| `mpmtsn` | mPMT board serial number | mPMT board serial number will be written on QSPI partition mtd:userdata during installation |
| `mpmttype` | mPMT board type (`plain` or `led`) | mPMT board type will be written on QSPI partition mtd:userdata during installation |
| `tasklist` | a list of scripts automatically executed from Zynq at Linux boot | tasks home directory is `/opt/setup-scripts`|
| `tftphost` | TFTP server hostname | if defined overrides `serverip` received by DHCP option 66 |
| `tftphome` | TFTP server mPMT board home directory | if defined overrides default value `/mpmt/zynq` |
| `httphost` | HTTP server hostname | 
| `httpport` | HTTP server port number |
| `httphome` | HTTP server mPMT board home directory |

!!! warning

    Default configuration is provided for `tasklist` so usually there is no need to change this variable. User must be sure that
    HTTP and TFTP variables reflect his own deployment server configuration.

!!! info

    User can also set in uEnv.txt file environment variables related to fixed IP configuration or other U-Boot options. A detailed list of
    U-Boot environment variables is available [here](https://docs.u-boot.org/en/latest/usage/environment.html)

### uEnv.txt example

```
#
# bootmode
#
bootmode=recovery

#
# mPMT serial number
#
mpmtsn=AABBCCDDEE112233445566

#
# mPMT type
#
mpmttype=plain

#
# settings for automatic execution at Linux boot
#
tasklist=deploy_qspi_userdata,deploy_qspi_bootbin -p http,deploy_qspi_fitimage -p http,deploy_emmc_rootfs -p http -r rfs-images/zynq-mpmt-debian.tar.lz4

#
# settings for TFTP server
#
tftphome=/mpmt/zynq/

#
# settings for HTTP server
#
httphost=10.1.3.3
httpport=8080
httphome=/mpmt/zynq
```

## Start Zynq bring-up

User can monitor whole Zynq bring-up process connecting by SSH to SAMA and opening serial console with `minicom`:

```
minicom -D /dev/ttyS1
```

Using an additional SSH session on SAMA user can start main setup script after [uEnv.txt](zynq-bringup.md#setup-environment-variables) setup:

```
cd /opt/jtag-script
./boot-zynq.sh
```

The script `boot-zynq.sh` uses openocd to inject U-Boot image and uEnv.txt to Zynq DDR. The whole bring-up process takes around 6 minutes
during which status messages are displayed on serial console. QSPI flash and eMMC are partitioned and initialized with files fetched
from deployment server using environment passed with uEnv.txt. The Linux login prompt indicates end of bring-up process.

### File fetching priority

A file fetching priority mechanism is implemented to customize mPMT board Zynq setup. If a script try to download a file called
`filename.bin` using HTTP protocol and defined `httphome` directory is `/mpmt/zynq` the following attempts are made
using defined environment variables:

1. `http://<httphost>:<httpport>/<httphome>/<mac_address>/filename.bin`
1. `http://<httphost>:<httpport>/<httphome>/default/<mpmttype>/filename.bin`
1. `http://<httphost>:<httpport>/<httphome>/default/filename.bin`

Next attempts in list will be skipped at first success.

## Advanced options

### QSPI memory

#### Partitioning schema

Zynq SoC is equipped with a 32MByte flash QSPI. During Zynq setup QSPI memory is partitioned following this schema:

| start addr | size | name | description |
|------------|------|------|-------------|
| 0x0000000 | 7MB | mtd:bootbin | BOOT.BIN |
| 0x06C0000 | 26MB | mtd:fitimage | Linux FIT image: kernel, device tree, minimal root filesystem |
| 0x1FF0000 | 64KB | mtd:userdata | mPMT board serial number and mPMT type |

#### Zynq boot using QSPI minimal root filesystem

Linux FIT image available on `mtd:fitimage` QSPI partition contains Linux kernel, device tree and minimal root filesystem
and it can be used from U-Boot to boot Zynq with a minimal root filesystem. To start QSPI boot user can open Zynq serial
console from SAMA using minicom, reboot Linux and interrupt U-Boot countdown. After these steps QSPI boot can be launched
at U-Boot prompt:

```
run bootqspi
```

#### Manual QSPI flashing (from U-Boot)

It is possible to flash `mtd:bootbin` and `mtd:fitimage` QSPI partitions using U-Boot scripts:

```
run flash_bootbin
run flash_fitimage
```

The download protocol is fixed as TFTP and environment variable used must be defined using uEnv.txt with openocd or
manually. Files will be fetched from deployment server using [file fetching priority](zynq-bringup.md#file-fetching-priority).


#### Manual QSPI flashing (from Linux)

It is possible to manually run setup scripts starting from QSPI boot. Setup scripts are located in `/opt/setup-scripts`.
Setup scripts to initialize QSPI flash partitions (`deploy_qspi_bootbin`, `deploy_qspi_fitimage`, `deploy_qspi_userdata`) 
accept following options:

```
-p <protocol>   download protocol {tftp|http}    (mandatory)
-c <filename>   configuration file               (optional)
```

The download protocol can be selected reflecting deployment server configuration, while configuration file contains
environment variables as specified for [uEnv.txt](zynq-bringup.md#setup-environment-variables). Files will be fetched
from deployment server using [file fetching priority](zynq-bringup.md#file-fetching-priority).

### eMMC memory

#### Manual eMMC flashing

Zynq eMMC is partitioned (one Linux partition) and formatted using `deploy_emmc_rootfs` setup script that accepts following options:

```
-p <protocol>   download protocol {tftp|http}              (mandatory)
-r <filename>   rootfs file (.tar.gz | .tar.lz4 | .tar)    (mandatory)
-c <filename>   configuration file                         (optional)
```

The download protocol can be selected reflecting deployment server configuration, while configuration file contains
environment variables as specified for [uEnv.txt](zynq-bringup.md#setup-environment-variables). Root filesystem image will be fetched
from deployment server using [file fetching priority](zynq-bringup.md#file-fetching-priority).


!!! note
    Due to Linux root filesystem image huge size (>1GB) usage of TFTP protocol is highly discouraged because it does not support
    'streaming mode' and takes a lot of time to setup whole eMMC. HTTP is preferred and most reliable solution for eMMC flashing.



