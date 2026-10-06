#!/bin/bash

systemctl set-default multi-user.target

systemctl disable e2scrub_reap.service e2scrub_all.timer 
systemctl disable apt-daily.timer apt-daily-upgrade.timer man-db.timer
systemctl disable dhcpcd.service
systemctl disable networking.service
systemctl mask ifupdown-pre.service

systemctl mask rpcbind.service rpcbind.socket
systemctl mask nfs-client.target rpc-statd.service rpc-statd-notify.service
systemctl mask rpc-gssd.service rpc-svcgssd.service run-rpc_pipefs.mount
systemctl mask haveged.service

systemctl mask modprobe@efi_pstore.service modprobe@drm.service
systemctl mask modprobe@fuse.service

systemctl enable systemd-networkd

# useless generators
mkdir -p /etc/systemd/system-generators
for g in systemd-gpt-auto-generator systemd-ssh-generator systemd-hibernate-resume-generator \
         systemd-tpm2-generator systemd-system-update-generator systemd-debug-generator \
         systemd-run-generator rpc-pipefs-generator; do
  ln -sf /dev/null /etc/systemd/system-generators/$g
done

