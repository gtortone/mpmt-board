#!/bin/sh

mkdir -p /etc/motd.d

NEW_ORDER=$(fw_printenv -n BOOT_ORDER 2>/dev/null || echo "unknown")

cat > /etc/motd.d/20-slot-outdated <<EOF

*** OUTDATED FIRMWARE ***

This slot was superseded on $(date -Is).

  booted slot     : ${RAUC_CURRENT_BOOTNAME:-unknown}
  boot order now  : ${NEW_ORDER}

You are running the PREVIOUS firmware. If this was not intentional,
check "rauc status" and reboot.

EOF
