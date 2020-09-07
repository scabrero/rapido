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

creds_path="/tmp/cifs_creds"
[ -n "$CIFS_DOMAIN" ] && echo "domain=${CIFS_DOMAIN}" >> $creds_path
[ -n "$CIFS_USER" ] && echo "username=${CIFS_USER}" >> $creds_path
[ -n "$CIFS_PW" ] && echo "password=${CIFS_PW}" >> $creds_path
mount_args="-ocredentials=${creds_path}"
[ -n "$CIFS_MOUNT_OPTS" ] && mount_args="${mount_args},${CIFS_MOUNT_OPTS}"
set -x

systemctl start systemd-journald.service

ip route add default via 192.168.155.1

echo "192.168.101.200 fs.fover.ad" >> /etc/hosts

export PATH="${CIFS_UTILS_SRC}:${SAMBA_SRC}/bin:${PATH}"

#SAMBA_CONFIGFILE="$(smbd -b | grep -Po 'CONFIGFILE: \K.*$')"
SAMBA_CONFIGFILE="/home/scabrero/workspace/samba/witness4cifs/deploy/etc/smb.conf"
SAMBA_CONFIGDIR="$(dirname ${SAMBA_CONFIGFILE})"

mkdir -p ${SAMBA_CONFIGDIR}
cat > ${SAMBA_CONFIGFILE} << EOF
[global]
	workgroup = ${CIFS_DOMAIN}
	witness : client version = 2
EOF

modprobe cifs || _fatal "failed to load cifs"

swnd &

mkdir -p /mnt/cifs
mount -t cifs //${CIFS_SERVER}/${CIFS_SHARE} /mnt/cifs \
	"$mount_args" || _fatal
cd /mnt/cifs || _fatal
set +x
