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

RAPIDO_DIR="$(realpath -e ${0%/*})/.."
. "${RAPIDO_DIR}/runtime.vars"

_rt_require_dracut_args "$RAPIDO_DIR/autorun/cifs_witness.sh"
_rt_require_conf_dir SAMBA_SRC
_rt_require_conf_dir CIFS_UTILS_SRC

"$DRACUT" --install "$DRACUT_RAPIDO_INSTALL \
		tail ps rmdir resize dd vim grep find df \
		mount.cifs ip ping getfacl setfacl truncate du \
		which touch cut chmod true false unlink \
		getfattr setfattr chacl attr killall sync \
		dirname seq basename fstrim chattr lsattr stat clear \
		file ldd mkfs.btrfs tc rsync reset kinit klist kdestroy \
		request-key cifs.upcall key.dns_resolver \
		/usr/lib/systemd/systemd-journald journalctl \
		${SAMBA_SRC}/sbin/smbd \
		${CIFS_UTILS_SRC}/swnd " \
	$DRACUT_RAPIDO_INCLUDES \
	--add-drivers "cifs lzo lzo-rle btrfs zram ccm gcm ctr" \
	--modules "bash base systemd systemd-initrd dracut-systemd network" \
	$DRACUT_EXTRA_ARGS \
	$DRACUT_OUT || _fail "dracut failed"

# assign more memory
_rt_xattr_vm_resources_set "$DRACUT_OUT" "2" "4096M"
