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
	[ -f "$1" ] || return 1
	printf '%s\n' "$1"
}

require_package()
{
	find_package "$1" || {
		echo "Package not found for $1. Run ./build.sh first." >&2
		exit 1
	}
}

package_installed()
{
	pkgman search -i "$1" 2>/dev/null | grep -qw "$1"
}

QEMU=$(require_package qemu)
QEMU_ARCH=$(require_package "$ARCH_PACKAGE")

# QEMU links against GLib forwards-compatibly, so a newer glib2_x86 already on
# the system is fine. Never push the local 2.57.1 build over it: that would
# downgrade the GLib WebPositive and HaikuWebKit use.
if package_installed glib2_x86; then
	echo "Keeping the glib2_x86 already installed on this system."
	GLIB_PACKAGES=""
elif GLIB=$(find_package glib2_x86) && GLIB_DEVEL=$(find_package glib2_x86_devel); then
	echo "Installing the locally built GLib packages."
	GLIB_PACKAGES="$GLIB $GLIB_DEVEL"
else
	echo "Installing glib2_x86 from the package repository."
	GLIB_PACKAGES="glib2_x86 glib2_x86_devel"
fi

yes | pkgman install $GLIB_PACKAGES "$QEMU" "$QEMU_ARCH"

if [ "$FLAVOR" = x86 ]; then
	qemu-system-x86_64 --version
else
	qemu-system-ppc --version
fi
qemu-img --version

echo "Browser packages retained:"
pkgman search -i webpositive_x86
pkgman search -i haikuwebkit_x86
