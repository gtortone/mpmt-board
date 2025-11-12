
## Introduction

A deployment server is required to serve useful files on network in order to bring-up mPMT board. 
These files will be available on network using TFTP and HTTP protocols.

## Architecture

The deployment server can also be used for [NAT](https://www.wikipedia.org/wiki/Network_address_translation)
so it can map mPMT board private addresses to a single public IP address. It can be also used for [DHCP](https://en.wikipedia.org/wiki/Dynamic_Host_Configuration_Protocol) and [DNS](https://en.wikipedia.org/wiki/Domain_Name_System) services.

``` mermaid
graph LR
  subgraph hosts["private IP LAN"]
    A[mPMT board #1]
    C[mPMT board #2]
  end
  A[mPMT board #1] <--> B[Deployment Server];
  C[mPMT board #2] <--> B[Deployment Server];
  B[Deployment Server] <--> D[Internet]
```

## TFTP server setup

A quick and simple option to install and configure a TFTP server is [dnsmasq](https://thekelleys.org.uk/dnsmasq/doc.html). Dnsmasq provides network infrastructure for small networks: DNS, DHCP and TFTP.

Dnsmasq has a single configuration file where user can set home directory of TFTP and DHCP server options.

In this configuration file example dnsmasq runs DHCP and TFTP server. TFTP server has `/srv/tftp` as home 
directory for files while DHCP server is configured to refuse MAC addresses not defined as static leases.
DHCP server is also configured to provide DNS server and default gateway to clients.

```
# only operate on eth0
interface=eth0

# set default gateway
dhcp-option=3,10.1.1.254

# set default DNS server
dhcp-option=6,10.1.3.3

# activate DHCP server with IP range
dhcp-range=10.1.1.31,10.1.1.38,255.255.0.0,6h

# ignore unknown clients
dhcp-ignore=tag:!known

# set static leases
dhcp-host=00:04:a3:48:bb:85,zynq,10.1.1.34,infinite
dhcp-host=80:34:28:28:52:BA,sama,10.1.1.35,infinite

# enable TFTP server
enable-tftp
tftp-root=/srv/tftp
```

## HTTP server setup

HTTP protocol is used on deployment server to provide a reliable network channel for data transfer.
TFTP is based on UDP and is suitable for small data transfer, on the other side HTTP is based on
TCP and is reliable for big data transfer like root file system images that can reach gigabytes in size.

A very simple and reliable HTTP server is [http-server](https://github.com/http-party/http-server), it is a node.js application and its installation is provided with npm or npx tool.

Usage is quite intuitive because it runs by default on port 8080 and accept as first parameter
the home directory to serve on HTTP.

### HTTP server startup at boot

[Supervisord](https://supervisord.org) can be used to configure automatic startup of http-server at boot.

A configuration file for http-server is needed in `/etc/supervisor/conf.d` directory:

```
[program:http-server]
command=/usr/bin/http-server /srv/tftp
stdout_logfile=/var/log/http-server-stdout.log
stdout_logfile_maxbytes=1MB
stdout_logfile_backups=5
stderr_logfile=/var/log/http-server-stderr.log
stderr_ogfile_maxbytes=1MB
stderr_logfile_backups=5
```

Supervisord daemon must be started at Linux boot:

```
systemctl enable --now supervisord.service
```

## Directories organization

!!! note
    In order to effectively manage boot files it is recommended to configure both HTTP server and TFTP server 
    on same home directory (e.g. `/srv/tftp`).

Assuming that defined home directory is `/srv/tftp` for both TFTP and HTTP servers, mPMT board setup
scripts follow this directories schema to fetch files (each item is a directory):

```
/mpmt

    /sama

    /zynq

        /rfs-images

        /<MAC address>

        /default/plain

        /default/led

        /default
```

* The first directory `/mpmt` is the base for all mPMT board files so you can use same deployment server to 
handle boot files for other boards.

* `/mpmt/sama` and `/mpmt/zynq` contains boot files and/or configuration files respectively for SAMA (SAMA5D27) or for Zynq 7000 SoC.

* `/mpmt/zynq/rfs-images` contains Linux root file system compressed files for Zynq 7000 SoC.

* `/mpmt/zynq/<MAC address>` can contains boot files or configuration files related to a specific
Zynq identified by its network adapter MAC address. MAC address must have following format: `00-11-22-33-44-55` using dash character instead of colon character. 

* `/mpmt/zynq/default/plain` and `/mpmt/zynq/default/led` contains FPGA bitstream
for standard mPMT board (plain) or 'led equipped' mPMT board (led).

* `/mpmt/zynq/default` contains boot files and/or configuration files common to all mPMT board types.

## Configuration

While SAMA installation is done using SAM-BA tool, Zynq installation is a quite complex task and it
requires a properly configuration of deployment server.

A script is available in mpmt-board repository (`scripts/populate-dir.sh`) to populate TFTP server home directory
and SAMA support directory. User can set directories location changing `$TFTPDIR` and `$SUPPORTDIR` defined
in the script.

SAMA support directory can be used with SAM-BA to bring-up SAMA.

All required files to copy on deployment server directories are available on mPMT board 
[release page](https://github.com/gtortone/mpmt-board/releases/latest).

!!! note 
    For the sake of simplicity also SAMA boot files are included in deployment server directories,
    but they are not fetched by network during SAMA installation.

Release files must be copied using following schema respecting path and names:

| release file                          | deployment file                        | description                                       |
|---------------------------------------|----------------------------------------|---------------------------------------------------| 
|  at91bootstrap.bin                    | `$TFTPDIR/mpmt/sama/at91bootstrap.bin`         | SAMA first stage bootloader                       |
|  at91-sama5d27-u-boot.bin             | `$TFTPDIR/mpmt/sama/u-boot.bin`                | SAMA U-Boot                                       |
|  at91-sama5d27_som1_ek.dtb            | `$TFTPDIR/mpmt/sama/at91-sama5d27_som1_ek.dtb` | SAMA device tree                                  |
|  at91-sama5d27-zImage                 | `$TFTPDIR/mpmt/sama/zImage`                    | SAMA Linux kernel image                           |
|  sama-mpmt-image-sama5d27-som1-ek-sd.rootfs.cpio.gz.u-boot | `$TFTPDIR/mpmt/sama/rootfs.cpio.gz` | SAMA minimal root filesystem image |
|  BOOT.BIN                             | `$TFTPDIR/mpmt/zynq/default/BOOT.BIN`          | Zynq FPGA bitstream, FSBL and U-Boot              |
|  image.ub                             | `$TFTPDIR/mpmt/zynq/default/image.ub`          | Zynq Linux kernel, device tree and minimal rootfs |
|  zynq-mpmt-debian.tar.lz4             | `$TFTPDIR/mpmt/zynq/rfs-images/zynq-mpmt-debian.tar.lz4` | Zynq Linux root filesystem image        |
|  at91bootstrap.bin                    | `$SUPPORTDIR/sama/at91bootstrap.bin`           | SAMA first stage bootloader                       |
|  at91-sama5d27-u-boot.bin             | `$SUPPORTDIR/sama/u-boot.bin`                  | SAMA U-Boot                                       |
|  at91-sama5d27-rootfs.wic             | `$SUPPORTDIR/sama/at91-sama5d27-rootfs.wic`                  | SAMA root filesystem image                        |

!!! warning
    This initial configuration of deployment server does not take into account different FPGA bitstream (led / plain) as at time of
    writing this guide they are still in development. It also does not take into account mPMT board customization using MAC address.


