#!/bin/sh
set -eu

ROOT=${QEMU_HAIKU_ROOT:-/boot/home/qemu-haiku-build}
JOBS=${BUILD_JOBS:-1}
PROJECT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
CONFIG="$ROOT/haikuports.conf"

if [ "$(uname)" != "Haiku" ]; then
	echo "This script must run on Haiku." >&2
	exit 1
fi

for command in pkgman haikuporter gcc-x86; do
	if ! command -v "$command" >/dev/null 2>&1; then
		echo "Required command not found: $command" >&2
		exit 1
	fi
done

mkdir -p "$ROOT"
cp -R "$PROJECT_DIR/ports/." "$ROOT/"

if [ ! -f "$ROOT/FormatVersions" ]; then
	printf 'RecipeFormatVersion=1\nPackageInfoFormatVersion=1\n' > "$ROOT/FormatVersions"
fi

cat > "$CONFIG" <<EOF
SECONDARY_TARGET_ARCHITECTURES="x86"
PACKAGER="QEMU Haiku Builder <builder@localhost>"
TREE_PATH="$ROOT"
EOF

echo "Installing build prerequisites..."
yes | pkgman install \
	gettext_x86 \
	gettext_x86_libintl_devel \
	haiku_x86_devel \
	meson \
	ninja_x86 \
	pkgconfig_x86

echo "Building the compatible x86 GLib packages..."
cd "$ROOT"
haikuporter --config="$CONFIG" --repository-update glib2_x86
haikuporter --config="$CONFIG" --no-repository-update \
	-j"$JOBS" --no-source-packages glib2_x86

echo "Building QEMU and all architecture subpackages..."
haikuporter --config="$CONFIG" --repository-update qemu
haikuporter --config="$CONFIG" --no-repository-update \
	-j"$JOBS" --no-source-packages qemu

echo "Build complete. Packages:"
ls -lh "$ROOT"/packages/qemu*.hpkg
