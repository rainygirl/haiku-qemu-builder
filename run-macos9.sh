#!/bin/sh
set -eu

ISO=${1:-}
VM_DIR=${MACOS9_VM_DIR:-/boot/home/macos9-qemu}
DISK="$VM_DIR/macos9.qcow2"

if [ -z "$ISO" ] || [ ! -f "$ISO" ]; then
	echo "Usage: $0 /path/to/bootable-macos9.iso" >&2
	exit 2
fi

mkdir -p "$VM_DIR"
if [ ! -f "$DISK" ]; then
	qemu-img create -f qcow2 "$DISK" 4G
fi

exec qemu-system-ppc \
	-no-user-config \
	-M mac99,via=pmu \
	-cpu G4 \
	-m 512 \
	-boot d \
	-drive "file=$ISO,format=raw,media=cdrom,readonly=on" \
	-drive "file=$DISK,format=qcow2,media=disk" \
	-prom-env 'auto-boot?=true' \
	-prom-env 'boot-args=-v' \
	-device usb-mouse \
	-device usb-kbd \
	-device sungem,netdev=net0 \
	-netdev user,id=net0
