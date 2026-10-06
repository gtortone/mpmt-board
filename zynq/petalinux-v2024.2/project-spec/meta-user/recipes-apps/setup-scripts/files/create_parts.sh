#!/bin/sh
#
# create_parts.sh
#
# Creates the GPT layout used by a RAUC A/B setup on eMMC:
#
#   p1  rootfs-a   ext4, RAUC slot A
#   p2  rootfs-b   ext4, RAUC slot B
#   p3  data       ext4, persistent application data (default 2 GiB)
#
# rootfs-a and rootfs-b evenly split whatever is left after data. The U-Boot
# environment block used by RAUC lives on the QSPI flash, not on the eMMC.
#
# Only sfdisk, mkfs.ext4, umount, dd and coreutils are required: everything
# else is read straight from /sys and /proc, so the script also runs on a
# minimal busybox-based rootfs without udev.
#
# WARNING: this destroys every existing partition and filesystem on the target
# device, and force-unmounts anything currently mounted from it.

set -euo pipefail

# ---------------------------------------------------------------------------
# Tunables
# ---------------------------------------------------------------------------

DATA_SIZE_MIB=1024        # 1 GiB
ALIGN_SECTORS=2048        # 1 MiB alignment (512-byte sectors)
GPT_TAIL_SECTORS=2048     # reserved for the backup GPT at the end of the device
WIPE_SECTORS=2048         # head/tail area zeroed before repartitioning

SLOT_A_LABEL="rootfs-a"
SLOT_B_LABEL="rootfs-b"
DATA_LABEL="data"

# "linux" is the sfdisk shortcut for the plain Linux filesystem type,
# 0FC63DAF-8483-4DFA-B4EF-4BAE18BE0BE5. Deliberately NOT one of the
# Discoverable Partitions Spec root types: the boot slot is chosen by U-Boot
# and passed as root= on the kernel command line, so partition auto-discovery
# must not get a say in it.
LINUX_FS_TYPE="linux"

# Disable ext4 features that older U-Boot ext4 drivers cannot handle. Adjust
# this list if your e2fsprogs does not know one of these feature names.
# reserve 1% of blocks available for disk full (-m)
EXT4_OPTS=(-m 1 -q -F -E nodiscard -O "^metadata_csum_seed,^orphan_file")

# ---------------------------------------------------------------------------
# Globals
# ---------------------------------------------------------------------------

DEVICE=""
DISK_NAME=""
SYSFS_DISK=""
ASSUME_YES=0
DO_FORMAT=1
declare -A DISK_DEVNUMS=()

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

die() {
    printf 'error: %s\n' "$*" >&2
    exit 1
}

info() {
    printf '>> %s\n' "$*"
}

usage() {
    cat <<EOF
Usage: ${0##*/} [options] <device>

Options:
  -d <MiB>   size of the data partition (default: ${DATA_SIZE_MIB})
  -n         partition only, do not create any filesystem
  -y         do not ask for confirmation
  -h         show this help

Example:
  ${0##*/} -d 2048 /dev/mmcblk0
EOF
}

# Returns the partition device node for a given partition number, handling both
# /dev/sda1 and /dev/mmcblk0p1 naming schemes.
part_dev() {
    local num="$1"
    if [[ "${DISK_NAME}" =~ [0-9]$ ]]; then
        printf '/dev/%sp%s' "${DISK_NAME}" "${num}"
    else
        printf '/dev/%s%s' "${DISK_NAME}" "${num}"
    fi
}

require_tools() {
    local tool missing=()
    for tool in sfdisk umount dd stat readlink sleep; do
        command -v "${tool}" >/dev/null 2>&1 || missing+=("${tool}")
    done
    if [[ ${DO_FORMAT} -eq 1 ]]; then
        command -v mkfs.ext4 >/dev/null 2>&1 || missing+=("mkfs.ext4")
    fi
    [[ ${#missing[@]} -eq 0 ]] || die "missing required tools: ${missing[*]}"
}

align_down() {
    printf '%s' "$(( $1 / ALIGN_SECTORS * ALIGN_SECTORS ))"
}

mib() {
    printf '%s' "$(( $1 / 2048 ))"
}

# Decodes the octal escapes /proc/self/mountinfo uses for special characters.
unescape_path() {
    local s="$1"
    s="${s//\\040/ }"
    s="${s//\\011/	}"
    s="${s//\\134/\\}"
    printf '%s' "${s}"
}

# Resolves the user-supplied path (possibly a symlink such as
# /dev/disk/by-id/...) to the kernel name of the whole disk.
resolve_disk() {
    local majmin maj min syslink

    [[ -b "${DEVICE}" ]] || die "${DEVICE} is not a block device"

    # %t and %T report the device numbers of a device node, in hex.
    majmin="$(stat -L -c '%t:%T' "${DEVICE}")" || die "cannot stat ${DEVICE}"
    maj="$(( 16#${majmin%%:*} ))"
    min="$(( 16#${majmin##*:} ))"

    syslink="/sys/dev/block/${maj}:${min}"
    [[ -d "${syslink}" ]] || die "${DEVICE} is unknown to the kernel"

    syslink="$(readlink -f "${syslink}")"
    DISK_NAME="${syslink##*/}"
    SYSFS_DISK="/sys/class/block/${DISK_NAME}"

    [[ -d "${SYSFS_DISK}" ]] || die "no sysfs entry for ${DISK_NAME}"
    [[ ! -e "${SYSFS_DISK}/partition" ]] \
        || die "${DEVICE} is a partition, pass the whole disk instead"

    # Work on the canonical node from here on, so part_dev() is predictable.
    DEVICE="/dev/${DISK_NAME}"
}

# Builds the set of major:minor numbers owned by the disk and its partitions.
collect_devnums() {
    local entry
    DISK_DEVNUMS=()
    [[ -r "${SYSFS_DISK}/dev" ]] && DISK_DEVNUMS["$(<"${SYSFS_DISK}/dev")"]=1
    for entry in "${SYSFS_DISK}/${DISK_NAME}"*; do
        [[ -r "${entry}/dev" ]] || continue
        DISK_DEVNUMS["$(<"${entry}/dev")"]=1
    done
}

# Prints the mount points currently backed by the disk, deepest paths first.
mountpoints_on_disk() {
    local mid pid majmin root mp
    while read -r mid pid majmin root mp _; do
        [[ -n "${DISK_DEVNUMS[${majmin}]+set}" ]] || continue
        printf '%s\t%s\n' "${#mp}" "$(unescape_path "${mp}")"
    done < /proc/self/mountinfo | sort -rn | cut -f2-
}

check_not_root_disk() {
    local mid pid majmin root mp
    while read -r mid pid majmin root mp _; do
        [[ "${mp}" == "/" ]] || continue
        [[ -z "${DISK_DEVNUMS[${majmin}]+set}" ]] \
            || die "${DEVICE} hosts the running root filesystem"
    done < /proc/self/mountinfo
}

# Refuses to touch a disk claimed by md, LVM or device-mapper: those cannot be
# released with a plain umount.
check_no_holders() {
    local entry holder
    for entry in "${SYSFS_DISK}" "${SYSFS_DISK}/${DISK_NAME}"*; do
        [[ -d "${entry}/holders" ]] || continue
        for holder in "${entry}/holders"/*; do
            [[ -e "${holder}" ]] || continue
            die "${entry##*/} is claimed by ${holder##*/} (md/LVM/dm), stop it first"
        done
    done
}

check_writable() {
    [[ -r "${SYSFS_DISK}/ro" && "$(<"${SYSFS_DISK}/ro")" == "1" ]] \
        && die "${DEVICE} is read-only"
    return 0
}

force_unmount() {
    local mp attempt=0 pending=0

    while read -r dev _; do
        [[ "${dev}" == "${DEVICE}"* ]] || continue
        if command -v swapoff >/dev/null 2>&1; then
            info "disabling swap on ${dev}"
            swapoff "${dev}" || die "cannot disable swap on ${dev}"
        else
            die "${dev} is in use as swap and swapoff is not available"
        fi
    done < <(tail -n +2 /proc/swaps 2>/dev/null || true)

    # Mount points can be stacked (bind mounts, overlays), so keep going until
    # nothing is left or we stop making progress.
    while [[ ${attempt} -lt 5 ]]; do
        pending=0
        while IFS= read -r mp; do
            [[ -n "${mp}" ]] || continue
            pending=1
            info "unmounting ${mp}"
            umount "${mp}" 2>/dev/null || umount -l "${mp}" 2>/dev/null || true
        done < <(mountpoints_on_disk)
        [[ ${pending} -eq 0 ]] && return 0
        attempt=$(( attempt + 1 ))
        sleep 1
    done

    [[ -z "$(mountpoints_on_disk)" ]] \
        || die "could not unmount every filesystem on ${DEVICE}"
}

# Waits for the kernel to register a partition and, on systems without devtmpfs
# or udev, creates the missing device node by hand.
wait_for_partition() {
    local node sysnode majmin i
    node="$(part_dev "$1")"
    sysnode="${SYSFS_DISK}/${node##*/}"

    for (( i = 0; i < 10; i++ )); do
        [[ -d "${sysnode}" ]] && break
        sleep 1
    done
    [[ -d "${sysnode}" ]] || die "the kernel did not register ${node}"

    for (( i = 0; i < 10; i++ )); do
        [[ -b "${node}" ]] && return 0
        sleep 1
    done

    majmin="$(<"${sysnode}/dev")"
    info "creating missing device node ${node}"
    mknod "${node}" b "${majmin%%:*}" "${majmin##*:}" \
        || die "${node} never appeared and could not be created"
}

confirm() {
    [[ ${ASSUME_YES} -eq 1 ]] && return 0
    local answer
    read -r -p "Erase ${DEVICE} and apply this layout? [yes/NO] " answer
    [[ "${answer}" == "yes" ]] || die "aborted by user"
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------

while getopts ":d:nyh" opt; do
    case "${opt}" in
        d) DATA_SIZE_MIB="${OPTARG}" ;;
        n) DO_FORMAT=0 ;;
        y) ASSUME_YES=1 ;;
        h) usage; exit 0 ;;
        :) die "option -${OPTARG} requires an argument" ;;
        *) usage >&2; exit 1 ;;
    esac
done
shift $(( OPTIND - 1 ))

[[ $# -eq 1 ]] || { usage >&2; exit 1; }
DEVICE="$1"

[[ "${DATA_SIZE_MIB}" =~ ^[0-9]+$ ]] || die "invalid data size: ${DATA_SIZE_MIB}"
[[ ${EUID} -eq 0 ]] || die "this script must be run as root"

require_tools
resolve_disk
collect_devnums
check_not_root_disk
check_no_holders
check_writable

# ---------------------------------------------------------------------------
# Layout computation (everything in 512-byte sectors)
# ---------------------------------------------------------------------------

# /sys/class/block/<disk>/size is always expressed in 512-byte units, whatever
# the logical block size of the device is.
TOTAL_SECTORS="$(<"${SYSFS_DISK}/size")"
[[ "${TOTAL_SECTORS}" -gt 0 ]] || die "cannot determine the size of ${DEVICE}"

SECTOR_SIZE="$(<"${SYSFS_DISK}/queue/logical_block_size")"
[[ "${SECTOR_SIZE}" -eq 512 ]] \
    || die "unsupported logical sector size ${SECTOR_SIZE}, this script assumes 512"

USABLE_END="$(align_down $(( TOTAL_SECTORS - GPT_TAIL_SECTORS )))"

DATA_SIZE="$(( DATA_SIZE_MIB * 2048 ))"

SLOT_A_START="${ALIGN_SECTORS}"
SLOTS_REGION="$(( USABLE_END - SLOT_A_START - DATA_SIZE ))"
[[ ${SLOTS_REGION} -ge $(( 2 * ALIGN_SECTORS )) ]] \
    || die "device too small: no room left for the rootfs slots"

SLOT_A_SIZE="$(align_down $(( SLOTS_REGION / 2 )))"
SLOT_B_START="$(( SLOT_A_START + SLOT_A_SIZE ))"
SLOT_B_SIZE="$(( SLOTS_REGION - SLOT_A_SIZE ))"

DATA_START="$(( SLOT_B_START + SLOT_B_SIZE ))"

[[ $(( DATA_START + DATA_SIZE )) -le ${USABLE_END} ]] \
    || die "internal error: computed layout overflows the device"

print_row() {
    # number, name, start, size, content
    printf '  %-3s %-10s %12s %14s %11s  %s\n' \
        "$1" "$2" "$3" "$4" "$(mib "$4")" "$5"
}

printf '\nTarget device : %s\n' "${DEVICE}"
printf 'Total size    : %s MiB (%s sectors)\n\n' \
    "$(mib "${TOTAL_SECTORS}")" "${TOTAL_SECTORS}"
printf '  %-3s %-10s %12s %14s %11s  %s\n' \
    "#" "name" "start" "sectors" "MiB" "content"
print_row 1 "${SLOT_A_LABEL}"   "${SLOT_A_START}" "${SLOT_A_SIZE}" "ext4"
print_row 2 "${SLOT_B_LABEL}"   "${SLOT_B_START}" "${SLOT_B_SIZE}" "ext4"
print_row 3 "${DATA_LABEL}"     "${DATA_START}"   "${DATA_SIZE}"   "ext4"
echo

while IFS= read -r mp; do
    [[ -n "${mp}" ]] && printf 'Currently mounted: %s (it will be unmounted)\n' "${mp}"
done < <(mountpoints_on_disk)

confirm

# ---------------------------------------------------------------------------
# Partitioning
# ---------------------------------------------------------------------------

force_unmount

# Zeroing the head and the tail of the device removes the primary GPT, the
# protective MBR, the backup GPT and any filesystem superblock that sfdisk
# would otherwise leave behind.
info "zeroing the first and last $(mib "${WIPE_SECTORS}") MiB of ${DEVICE}"
dd if=/dev/zero of="${DEVICE}" bs=512 count="${WIPE_SECTORS}" \
   conv=fsync 2>/dev/null
dd if=/dev/zero of="${DEVICE}" bs=512 count="${WIPE_SECTORS}" \
   seek="$(( TOTAL_SECTORS - WIPE_SECTORS ))" conv=fsync 2>/dev/null

info "writing GPT partition table"
sfdisk --quiet --wipe always --wipe-partitions always "${DEVICE}" <<EOF
label: gpt
unit: sectors

start=${SLOT_A_START}, size=${SLOT_A_SIZE}, type=${LINUX_FS_TYPE}, name="${SLOT_A_LABEL}"
start=${SLOT_B_START}, size=${SLOT_B_SIZE}, type=${LINUX_FS_TYPE}, name="${SLOT_B_LABEL}"
start=${DATA_START},   size=${DATA_SIZE},   type=${LINUX_FS_TYPE}, name="${DATA_LABEL}"
EOF

sync

# sfdisk already asks the kernel to re-read the table; just wait for the result.
for num in 1 2 3; do
    wait_for_partition "${num}"
done

P_ROOT_A="$(part_dev 1)"
P_ROOT_B="$(part_dev 2)"
P_DATA="$(part_dev 3)"

# ---------------------------------------------------------------------------
# Filesystems
# ---------------------------------------------------------------------------

if [[ ${DO_FORMAT} -eq 1 ]]; then
    info "creating ext4 on ${P_ROOT_A} (${SLOT_A_LABEL})"
    mkfs.ext4 "${EXT4_OPTS[@]}" -L "${SLOT_A_LABEL}" "${P_ROOT_A}"

    info "creating ext4 on ${P_ROOT_B} (${SLOT_B_LABEL})"
    mkfs.ext4 "${EXT4_OPTS[@]}" -L "${SLOT_B_LABEL}" "${P_ROOT_B}"

    info "creating ext4 on ${P_DATA} (${DATA_LABEL})"
    mkfs.ext4 "${EXT4_OPTS[@]}" -L "${DATA_LABEL}" "${P_DATA}"
else
    info "skipping filesystem creation (-n)"
fi

sync

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

echo
sfdisk --list "${DEVICE}"

