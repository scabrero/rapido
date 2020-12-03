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

_vm_ar_env_check || exit 1

_vm_ar_dyn_debug_enable
_vm_ar_hosts_create

#[ -n "$CIFS_DOMAIN" ] && echo "domain=${CIFS_DOMAIN}" >> $creds_path
#[ -n "$CIFS_USER" ] && echo "username=${CIFS_USER}" >> $creds_path
#[ -n "$CIFS_PW" ] && echo "password=${CIFS_PW}" >> $creds_path

cat > /etc/krb5.conf << EOF
[libdefaults]
	default_realm = FOVER.AD
	default_ccache_name = /tmp/krb5cc_%{uid}
	dns_canonicalize_hostname = false
	rdns = false

[domain_realm]
	.fover.ad = FOVER.AD
	fover.ad = FOVER.AD

[realms]
	FOVER.AD = {
		kdc = 192.168.103.51
		admin_server = 192.168.103.51
	}
EOF

cat > /etc/request-key.conf << EOF
create  dns_resolver *          *               /usr/sbin/cifs.upcall -E %k
create  cifs.spnego     *       *               /usr/sbin/cifs.upcall -E %k
EOF

echo "$CIFS_PW" | kinit $CIFS_USER@FOVER.AD || _fatal "kinit failed"

mount_args="-osec=krb5,witness"
[ -n "$CIFS_MOUNT_OPTS" ] && mount_args="${mount_args},${CIFS_MOUNT_OPTS}"
set -x

export PATH="${CIFS_UTILS_SRC}:${SAMBA_SRC}/bin:${SAMBA_SRC}/sbin:${PATH}"

# Create samba config file, necessary for swnd
SAMBA_CONFIGFILE="$(smbd -b | grep -Po 'CONFIGFILE: \K.*$')"
SAMBA_CONFIGDIR="$(dirname ${SAMBA_CONFIGFILE})"

mkdir -p ${SAMBA_CONFIGDIR}
cat > ${SAMBA_CONFIGFILE} << EOF
[global]
	netbios name = $(cat /proc/sys/kernel/hostname)
	workgroup = ${CIFS_DOMAIN}
	realm = FOVER.AD
	witness : client version = 2
EOF

# Load cifs and enable debug
modprobe cifs || _fatal "failed to load cifs"
echo 'module cifs +p' > /sys/kernel/debug/dynamic_debug/control
echo 'file fs/cifs/* +p' > /sys/kernel/debug/dynamic_debug/control
echo 7 > /proc/fs/cifs/cifsFYI

# Setup RAM disk
modprobe zram num_devices="1" || _fatal "failed to load zram module"
echo "1G" > /sys/block/zram0/disksize || _fatal "failed to set zram disksize"
filesystem="btrfs"
mkfs.${filesystem} /dev/zram0 || _fatal "mkfs failed"
mkdir -p /mnt/zram
mount -t $filesystem /dev/zram0 /mnt/zram || _fatal

dd if=/dev/zero of=/mnt/zram/1G.bin bs=1M count=512

# Start systemd-journald, swnd logs to system journal
ps -eo args | grep -v grep | grep /usr/lib/systemd/systemd-journald \
	|| /usr/lib/systemd/systemd-journald &

# Start swnd, the witness service user-space daemon
swnd -d10 &

mkdir -p /mnt/cifs
mount -t cifs //${CIFS_SERVER}/${CIFS_SHARE} /mnt/cifs \
	"$mount_args"

set +x
