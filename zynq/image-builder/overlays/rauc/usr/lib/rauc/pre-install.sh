#!/bin/sh
# RAUC pre-install handler: release /stage so the inactive slot can be
# overwritten by the update. Services using /stage should declare
# BindsTo=stage-setup.service so they are stopped together with it.
set -eu

if systemctl is-active --quiet stage-setup.service; then
    systemctl stop stage-setup.service
fi

# Abort the installation if the slot is still mounted for any reason
if mountpoint -q /stage; then
    echo "pre-install: /stage still mounted, aborting update" >&2
    exit 1
fi
