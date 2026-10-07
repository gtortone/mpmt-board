#!/bin/sh
# Prepare the inactive RAUC rootfs slot as a staging area mounted on /stage.
#
# Safety rules:
#  - never touch the booted slot
#  - never touch a slot that is the next boot target (pending update)
#  - mark the slot bad before formatting it, so the bootloader can never
#    fall back to a slot that no longer contains a rootfs
set -eu

MOUNTPOINT=/stage
FS_LABEL=stage
SLOT_CLASS=rootfs
MOUNT_OPTS=noatime,nodev,nosuid,noexec

log() { echo "stage-setup: $*" >&2; }

# Import RAUC_* variables describing system and slots
eval "$(rauc status --output-format=shell)"

target_dev=""
target_bootname=""
for i in $RAUC_SLOTS; do
    eval class=\$RAUC_SLOT_CLASS_$i
    eval state=\$RAUC_SLOT_STATE_$i
    eval dev=\$RAUC_SLOT_DEVICE_$i
    eval bootname=\${RAUC_SLOT_BOOTNAME_$i:-}

    [ "$class" = "$SLOT_CLASS" ] || continue
    [ "$state" = "booted" ] && continue

    target_dev=$dev
    target_bootname=$bootname
done

if [ -z "$target_dev" ]; then
    log "no inactive $SLOT_CLASS slot found, nothing to do"
    exit 0
fi

# An installed-but-not-yet-booted update must not be destroyed
if [ -n "$target_bootname" ] && [ "${RAUC_BOOT_PRIMARY:-}" = "$target_bootname" ]; then
    log "slot $target_dev is the next boot target, leaving it untouched"
    exit 0
fi

current_label=$(blkid -o value -s LABEL "$target_dev" 2>/dev/null || true)

if [ "$current_label" != "$FS_LABEL" ]; then
    log "converting $target_dev into staging area (previous rootfs is lost)"
    rauc status mark-bad other
    mkfs.ext4 -F -q -L "$FS_LABEL" "$target_dev"
fi

mkdir -p "$MOUNTPOINT"
if ! mountpoint -q "$MOUNTPOINT"; then
    mount -t ext4 -o "$MOUNT_OPTS" "$target_dev" "$MOUNTPOINT"
fi
log "$target_dev mounted on $MOUNTPOINT"
