#!/bin/bash

# called by dracut
check() {
    [[ $mount_needs ]] && return 1

    if ! dracut_module_included "systemd"; then
        derror "systemd-journald needs systemd in the initramfs"
        return 1
    fi

    return 255
}

# called by dracut
depends() {
    echo "systemd"
}

installkernel() {
    return 0
}

# called by dracut
install() {
    inst_multiple -o \
        $systemdsystemunitdir/systemd-journald.service \
        $systemdsystemunitdir/systemd-journald.socket \
        journalctl

    for i in \
        systemd-journald.service \
        systemd-journald.socket
    do
        systemctl -q --root "$initdir" enable "$i"
    done
}
