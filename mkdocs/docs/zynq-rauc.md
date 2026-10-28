# Zynq software update (RAUC)

## Requirements

- [Zynq](zynq-bringup.md) installed with Debian root filesystem on eMMC
- [Deployment server](deployment-server.md) configured and running 

## What is RAUC

[RAUC](https://rauc.io) (Robust Auto-Update Controller) is an open-source framework to safely update the software of embedded Linux
devices in the field. Its main features are:

* **Signed bundles**: the update is distributed as a single file, the *bundle* (`.raucb`), that contains root filesystem image and
  a manifest. Every bundle is signed and RAUC refuses to install a bundle whose signature does not match the certificate installed
  on the board (`/etc/rauc/ca.cert.pem`).
* **Compatibility check**: the bundle carries a `compatible` string that must match the one of the board (`mpmt-board`), so a bundle
  built for a different hardware cannot be installed by mistake.
* **Streaming installation**: bundles in `verity` format can be installed directly from an HTTP(S) URL, without saving a copy
  of the bundle on the board first.
* **Bootloader integration**: RAUC does not boot the system itself, it tells the bootloader (U-Boot) which slot must be started
  next using a few variables stored in the U-Boot environment.

### Glossary

| term | meaning |
|------|---------|
| slot | a partition that can hold a root filesystem (`rootfs.0` = A, `rootfs.1` = B) |
| booted slot | the slot the running system was started from |
| inactive slot | the other slot, target of the next update |
| bundle | signed file (`.raucb`) with root filesystem image and manifest |
| boot status | `good` or `bad`, set by RAUC in U-Boot environment for each slot |

## Partitioning schema

### eMMC

The eMMC is partitioned during [Zynq bring-up](zynq-bringup.md) with a GPT table made of three partitions:

| partition | size | label | mount point | description |
|-----------|------|-------|-------------|-------------|
| `/dev/mmcblk0p1` | ~50% eMMC size | `rootfs-a` | `/` or `/stage` | RAUC slot A (`rootfs.0`) |
| `/dev/mmcblk0p2` | ~50% eMMC size  | `rootfs-b` | `/` or `/stage` | RAUC slot B (`rootfs.1`) |
| `/dev/mmcblk0p3` | 50 MB | `data` | `/data` | persistent data, never touched by updates |

The two slots split evenly the eMMC space left after `data` partition. Only one slot at a time contains the running root filesystem;
the other one is reused as [staging area](#staging-area-stage) and mounted on `/stage`. The `data` partition holds the RAUC
status file (`/data/rauc`) and any data that must survive updates.

Example on a board booted from slot A:

```
root@zynq:~# lsblk -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINT /dev/mmcblk0
NAME         SIZE FSTYPE LABEL    MOUNTPOINT
mmcblk0     29.6G
├─mmcblk0p1 14.8G ext4   rootfs-a /
├─mmcblk0p2 14.8G ext4   stage    /stage
└─mmcblk0p3   50M ext4   data     /data
```

### QSPI

The variables used by RAUC to select the boot slot are stored in the same QSPI partition used for board identification
(`mtd:userdata`, see [QSPI partitioning schema](zynq-bringup.md#partitioning-schema)):

| variable | description |
|----------|-------------|
| `mpmtsn`, `mpmttype` | mPMT board serial number and type (written during bring-up) |
| `BOOT_ORDER` | list of slots in boot priority order (e.g. `A B`) |
| `BOOT_A_LEFT`, `BOOT_B_LEFT` | remaining boot attempts of each slot |

From Linux these variables are accessed with `fw_printenv` / `fw_setenv` (configuration in `/etc/fw_env.config`, QSPI device
`/dev/mtd2`). At U-Boot prompt the command `run raucinfo` shows the current values and the slot that would be booted.

!!! warning
    Do not write `mtd:userdata` partition with tools other than `fw_setenv` or RAUC: the same block holds board serial number and type.

### Boot sequence

U-Boot (`bootcmd=run bootrauc`) loads RAUC variables from QSPI and boots the first slot listed in `BOOT_ORDER`: it loads
`/boot/image.ub` from the selected eMMC partition and passes to Linux the root partition and the slot name:

```
root=/dev/mmcblk0p<1|2> rootwait rw rauc.slot=<A|B>
```

If `BOOT_ORDER` is not defined (first boot after bring-up) U-Boot sets `BOOT_ORDER="A B"` and saves it on QSPI.

### Configuration files

| file | description |
|------|-------------|
| `/etc/rauc/system.conf` | RAUC system configuration: compatible string, bootloader, slots, handlers |
| `/etc/rauc/ca.cert.pem` | certificate used to verify bundle signature |
| `/etc/fw_env.config` | location of U-Boot environment on QSPI |
| `/usr/lib/rauc/pre-install.sh` | handler executed before writing the slot (releases `/stage`) |
| `/usr/lib/rauc/post-install.sh` | handler executed after a successful installation (adds an *outdated firmware* notice to login message) |
| `/etc/systemd/system/rauc-mark-good.service` | marks the booted slot as `good` at the end of boot |
| `/etc/systemd/system/stage-setup.service` | prepares and mounts the staging area on `/stage` |
| `/etc/profile.d/rauc-stage.sh` | shell wrapper that releases `/stage` before `rauc install` |

`/etc/rauc/system.conf`:

```
[system]
compatible=mpmt-board
bootloader=uboot
data-directory=/data/rauc
max-bundle-download-size=5000000000

[keyring]
path=/etc/rauc/ca.cert.pem

[slot.rootfs.0]
device=/dev/mmcblk0p1
type=ext4
bootname=A

[slot.rootfs.1]
device=/dev/mmcblk0p2
type=ext4
bootname=B

[handlers]
pre-install=/usr/lib/rauc/pre-install.sh
post-install=/usr/lib/rauc/post-install.sh
```

### Staging area (`/stage`)

To avoid wasting half of the eMMC, the inactive slot is used as a general purpose staging area mounted on `/stage`.
At every boot `stage-setup.service` runs **after** the booted slot has been marked `good` (`rauc-mark-good.service`) and:

1. looks for the rootfs slot that is not booted;
1. leaves it untouched if it is the next boot target (an update installed but not yet rebooted);
1. if the slot does not have filesystem label `stage` yet, marks it `bad` (so U-Boot can never boot it) and formats it as ext4 with label `stage`;
1. mounts it on `/stage` (options `noatime,nodev,nosuid,noexec`).

Formatting happens only once, at first boot after an update; next boots find label `stage` and just mount the partition.

``` mermaid
sequenceDiagram
  participant A as slot A
  participant B as slot B
  Note over A,B: running from A, B mounted on /stage
  B->>B: rauc install writes new rootfs on B
  Note over A,B: reboot: U-Boot starts B
  B->>B: rauc-mark-good marks B good
  A->>A: stage-setup marks A bad, formats it, mounts it on /stage
  Note over A,B: running from B, A mounted on /stage
```

!!! danger
    **Content of `/stage` is lost at every update**: the staging area is overwritten by the new root filesystem, and after reboot
    the previous root filesystem is formatted as new staging area. Data that must survive updates belong to `/data`.

!!! warning
    Using the inactive slot as staging area means that **the previous root filesystem is not kept as fallback**: once the updated
    slot has booted and has been marked `good`, the previous slot is erased. Rollback is only possible before rebooting
    (see [Cancel an installed update](#cancel-an-installed-update)).

## Upgrade procedure

### Publish bundle

The bundle must be reachable by the board through HTTP.

* copy bundle on [deployment server](deployment-server.md) HTTP home directory (e.g. `/srv/tftp/mpmt/zynq/rfs-images/mpmt-3.2.0.raucb`,
  available at `http://10.1.3.3:8080/mpmt/zynq/rfs-images/mpmt-3.2.0.raucb`).

### Install bundle

Log in on Zynq (SSH or serial console) and check current status:

```
root@zynq:~# rauc status
=== System Info ===
Compatible:  mpmt-board
Variant:
Booted from: rootfs.0 (A)

=== Bootloader ===
Activated: rootfs.0 (A)

=== Slot States ===
○ [rootfs.1] (/dev/mmcblk0p2, ext4, inactive)
      bootname: B
      mounted: /stage
      boot status: bad

⏺ [rootfs.0] (/dev/mmcblk0p1, ext4, booted)
      bootname: A
      mounted: /
      boot status: good
```

Start installation passing bundle URL:

```
rauc install http://10.1.3.3:8080/mpmt/zynq/rfs-images/mpmt-3.2.0.raucb
```

RAUC downloads and verifies the bundle, writes the root filesystem on the inactive slot and sets it as next boot target.
Installation progress is shown on terminal; it ends with:

```
Installing `http://10.1.3.3:8080/mpmt/zynq/rfs-images/mpmt-3.2.0.raucb` succeeded
```

!!! note
    RAUC refuses to write a slot that is mounted when installation starts, so `/stage` must be unmounted **before** running
    `rauc install` (RAUC handlers are executed too late for this). In login shells this is done automatically by a wrapper
    defined in `/etc/profile.d/rauc-stage.sh`, that stops `stage-setup.service` before calling RAUC and restores `/stage` if
    installation fails. When `rauc install` is started from a script, a non-login shell or D-Bus, release `/stage` manually first:

        systemctl stop stage-setup.service

!!! warning
    Stop every process that uses `/stage` before installation. If `/stage` is busy it cannot be unmounted and installation is
    aborted (no data is written on the slot).

### Activate update

Reboot the board to start the updated slot:

```
reboot
```

After reboot verify that the board is running from the updated slot and that it has been marked `good`:

```
root@zynq:~# rauc status
...
Booted from: rootfs.1 (B)
...
⏺ [rootfs.1] (/dev/mmcblk0p2, ext4, booted)
      bootname: B
      mounted: /
      boot status: good
```

The previous slot is now the new staging area mounted on `/stage`.

### Cancel an installed update

Between installation and reboot the previous root filesystem is still intact. To discard the installed update and keep running the
current slot at next boot:

```
rauc status mark-active booted
systemctl start stage-setup.service
```

The first command sets the booted slot as next boot target again, the second one restores the staging area on `/stage`
(the slot is formatted again because it now contains the discarded update).

### Troubleshooting

| error | cause | solution |
|-------|-------|----------|
| `Destination device '/dev/mmcblk0p<n>' already mounted` | `/stage` was mounted when installation started | `systemctl stop stage-setup.service` and run `rauc install` again |
| `umount: /stage: target is busy` or `pre-install: /stage still mounted, aborting update` | a process is using `/stage` | stop the process (`fuser -vm /stage` shows it) and retry |
| `Compatible mismatch` | bundle built for a different system | check `compatible` in bundle manifest |
| signature verification failed | bundle signed with a key not issued by board CA | sign bundle with correct certificate and key |
| `/stage` not mounted after update | updated slot not marked `good` yet | check `systemctl status rauc-mark-good.service stage-setup.service` |
