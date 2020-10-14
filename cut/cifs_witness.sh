#!/bin/bash
#
# Copyright (C) SUSE LINUX GmbH 2019, all rights reserved.
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

_rt_require_dracut_args

"$DRACUT" --install "tail ps rmdir resize dd vim grep find df \
		   mount.cifs ip ping getfacl setfacl truncate du \
		   which touch cut chmod true false unlink \
		   getfattr setfattr chacl attr killall sync \
		   dirname seq basename fstrim chattr lsattr stat \
		   file ldd mkfs.btrfs tc rsync \
		   ${SAMBA_SRC}/bin/smbd \
		   ${CIFS_UTILS_SRC}/swnd " \
	--include "$RAPIDO_DIR/autorun/cifs_witness.sh" "/.profile" \
	--include "$RAPIDO_DIR/autorun/00-rapido-init.sh" \
		  "/lib/dracut/hooks/emergency/00-rapido-init.sh" \
	--include "$RAPIDO_DIR/rapido.conf" "/rapido.conf" \
	--include "$RAPIDO_DIR/vm_autorun.env" "/vm_autorun.env" \
	--add-drivers "cifs lzo lzo-rle btrfs zram ccm gcm ctr sch_tbf sch_htb sch_sfq" \
	--modules "bash base systemd systemd-initrd dracut-systemd" \
	$DRACUT_EXTRA_ARGS \
	$DRACUT_OUT || _fail "dracut failed"

# assign more memory
_rt_xattr_vm_resources_set "$DRACUT_OUT" "2" "1024M"
