#!/bin/bash
#
# Copyright (C) SUSE LINUX GmbH 2020, all rights reserved.
#
# This library is free software; you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License as published
# by the Free Software Foundation; either version 2.1 of the License, or
# (at your option) version 3.
#
# This library is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
# License for more details.

if [ ! -f /vm_autorun.env ]; then
	echo "Error: autorun scripts must be run from within an initramfs VM"
	exit 1
fi

. /vm_autorun.env

_vm_ar_dyn_debug_enable
_vm_ar_hosts_create

creds_path="/tmp/cifs_creds"
[ -n "$CIFS_DOMAIN" ] && echo "domain=${CIFS_DOMAIN}" >> $creds_path
[ -n "$CIFS_USER" ] && echo "username=${CIFS_USER}" >> $creds_path
[ -n "$CIFS_PW" ] && echo "password=${CIFS_PW}" >> $creds_path
mount_args="-ocredentials=${creds_path},witness,echo_interval=5"
[ -n "$CIFS_MOUNT_OPTS" ] && mount_args="${mount_args},${CIFS_MOUNT_OPTS}"
set -x

systemctl start systemd-journald.service

ip route add default via 192.168.155.1

echo "192.168.101.200 fs.fover.ad" >> /etc/hosts
echo "192.168.101.201 fs2.fover.ad" >> /etc/hosts
echo "192.168.101.12 sofs.fover12.ad" >> /etc/hosts
echo "192.168.101.15 fs.fover12.ad" >> /etc/hosts

export PATH="${CIFS_UTILS_SRC}:${SAMBA_SRC}/bin:${PATH}"

#SAMBA_CONFIGFILE="$(smbd -b | grep -Po 'CONFIGFILE: \K.*$')"
SAMBA_CONFIGFILE="/home/scabrero/workspace/samba/witness4cifs/deploy/etc/smb.conf"
SAMBA_CONFIGDIR="$(dirname ${SAMBA_CONFIGFILE})"

mkdir -p ${SAMBA_CONFIGDIR}
cat > ${SAMBA_CONFIGFILE} << EOF
[global]
	netbios name = RAPIDO1
	workgroup = ${CIFS_DOMAIN}
	realm = FOVER12.AD
	witness : client version = 2
EOF

modprobe cifs || _fatal "failed to load cifs"
modprobe zram num_devices="1" || _fatal "failed to load zram module"

echo 'module cifs +p' > /sys/kernel/debug/dynamic_debug/control
echo 'file fs/cifs/* +p' > /sys/kernel/debug/dynamic_debug/control
echo 7 > /proc/fs/cifs/cifsFYI

echo "2G" > /sys/block/zram0/disksize || _fatal "failed to set zram disksize"
filesystem="btrfs"
mkfs.${filesystem} /dev/zram0 || _fatal "mkfs failed"
mkdir -p /mnt/zram
mount -t $filesystem /dev/zram0 /mnt/zram || _fatal

swnd &

sleep 1

mkdir -p /mnt/fs1_share1
mount -t cifs //sofs.fover12.ad/share1 /mnt/fs1_share1 "$mount_args" || _fatal

mkdir -p /mnt/fs2_share2
mount -t cifs //fs.fover12.ad/share1 /mnt/fs2_share2 "$mount_args" || _fatal

mkdir -p /mnt/fs2_share21
mount -t cifs //fs.fover12.ad/share1 /mnt/fs2_share21 "$mount_args" || _fatal
#mount -t cifs //${CIFS_SERVER}/${CIFS_SHARE} /mnt/cifs \
#	"$mount_args" || _fatal

#sleep 3

#rsync --info=progress2 /mnt/fs1_share1/1G.bin /mnt/zram &

set +x
