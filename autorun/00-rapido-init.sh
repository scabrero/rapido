#
# Copyright (C) SUSE LLC 2020, all rights reserved.
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

# This script runs as the first Dracut entry point during /init.
# $DRACUT_SYSTEMD is set when run via systemd.

echo "Rapido: starting autorun script..."

_ctty=console
while [ -f /sys/class/tty/$_ctty/active ]; do
	_ctty=$(cat /sys/class/tty/$_ctty/active)
	_ctty=${_ctty##* } # last one in the list
done
_ctty=/dev/$_ctty
[ -c "$_ctty" ] || _ctty=/dev/tty1
setsid --ctty /bin/sh -i -l 0<>$_ctty 1<>$_ctty 2<>$_ctty

# shut down when rapido autorun / shell exits...
echo 1 > /proc/sys/kernel/sysrq && echo o > /proc/sysrq-trigger
sleep 20
