#!/bin/sh
set -eu

ROOT=${QEMU_HAIKU_ROOT:-/boot/home/qemu-haiku-build}
FLAVOR=${1:-x86}

case "$FLAVOR" in
	x86) ARCH_PACKAGE=qemu_x86 ;;
	ppc) ARCH_PACKAGE=qemu_ppc ;;
	*) echo "Usage: $0 [x86|ppc]" >&2; exit 2 ;;
esac

find_package()
{
	set -- "$ROOT"/packages/"$1"-*.hpkg
	if [ ! -f "$1" ]; then
		echo "Package not found for $1. Run ./build.sh first." >&2
		exit 1
	fi
	printf '%s\n' "$1"
}

GLIB=$(find_package glib2_x86)
GLIB_DEVEL=$(find_package glib2_x86_devel)
QEMU=$(find_package qemu)
QEMU_ARCH=$(find_package "$ARCH_PACKAGE")

yes | pkgman install "$GLIB" "$GLIB_DEVEL" "$QEMU" "$QEMU_ARCH"

if [ "$FLAVOR" = x86 ]; then
	qemu-system-x86_64 --version
else
	qemu-system-ppc --version
fi
qemu-img --version

echo "Browser packages retained:"
pkgman search -i webpositive_x86
pkgman search -i haikuwebkit_x86
