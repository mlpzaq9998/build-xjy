#!/bin/bash

[ "$EUID" != "0" ] && echo "please run as root" && exit 1

set -e
set -o pipefail

os="ubuntu"
rootsize=850
origin="arm64"
target="xjy"

tmpdir="tmp"
output="output"
rootfs_mount_point="/mnt/${os}_rootfs"
qemu_static="./tools/qemu/qemu-aarch64-static"

cur_dir=$(pwd)
DTB=rtd-1295-xjy-2GB.dtb

chroot_prepare() {
	if [ -z "$GITHUB_ACTIONS" ]; then
		sed -i 's#http://ports.ubuntu.com#http://mirrors.ustc.edu.cn#' $rootfs_mount_point/etc/apt/sources.list
		echo "nameserver 119.29.29.29" > $rootfs_mount_point/etc/resolv.conf
	else
		echo "nameserver 8.8.8.8" > $rootfs_mount_point/etc/resolv.conf
	fi
}

ext_init_param() {
	echo "BUILD_MINIMAL=y"
}

chroot_post() {
	if [ -z "$GITHUB_ACTIONS" ]; then
		sed -i 's#http://#https://#' $rootfs_mount_point/etc/apt/sources.list
	else
		sed -i 's#http://ports.ubuntu.com#https://mirrors.ustc.edu.cn#' $rootfs_mount_point/etc/apt/sources.list
	fi
}

add_resizemmc() {
	echo "add resize mmc script"
	cp ./tools/systemd/resizemmc.service $rootfs_mount_point/lib/systemd/system/
	cp ./tools/systemd/resizemmc.sh $rootfs_mount_point/sbin/
	mkdir -p $rootfs_mount_point/etc/systemd/system/basic.target.wants
	ln -sf /lib/systemd/system/resizemmc.service $rootfs_mount_point/etc/systemd/system/basic.target.wants/resizemmc.service
	touch $rootfs_mount_point/root/.need_resize
}

gen_new_name() {
	local rootfs=$1
	echo "`basename $rootfs | sed "s/${origin}/${target}/" | sed 's/.gz$/.xz/'`"
}

source ./common.sh
