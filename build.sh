#!/bin/sh
set -eu

ROOT=${QEMU_HAIKU_ROOT:-/boot/home/qemu-haiku-build}
JOBS=${BUILD_JOBS:-1}
GLIB_SOURCE=${GLIB_SOURCE:-auto}
PROJECT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
CONFIG="$ROOT/haikuports.conf"

# Version of the GLib recipe bundled in ports/. It matches the glib2_x86 that
# R1/beta6 x86_gcc2 ships, which is why the local build is a usable fallback.
BUNDLED_GLIB_VERSION=2.57.1
QEMU_VERSION=8.2.2
QEMU_RECIPE="$ROOT/app-emulation/qemu/qemu-$QEMU_VERSION.recipe"

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

# "2.57.1-4" -> "2.57.1". haikuporter matches requirements on the version only.
strip_revision()
{
	printf '%s\n' "${1%-*}"
}

installed_version()
{
	strip_revision "$(pkgman search -i -D "$1" 2>/dev/null |
		awk -v name="$1" '$1 == "<system>" && $2 == name { print $3; exit }')"
}

repository_version()
{
	strip_revision "$(pkgman search -D "$1" 2>/dev/null |
		awk -v name="$1" '$1 != "<system>" && $2 == name { print $3; exit }')"
}

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
	gcc_x86_syslibs_devel \
	gettext_x86 \
	gettext_x86_libintl_devel \
	haiku_x86_devel \
	meson \
	ninja_x86 \
	pkgconfig_x86

# QEMU needs a glib2_x86 and a glib2_x86_devel of the *same* version. beta6
# x86_gcc2 ships glib2_x86 2.57.1 without the devel package, and HaikuPorts has
# since moved glib2_x86 to 2.88.1, so the repository can no longer supply a
# matching devel. Decide which GLib to use, then pin the QEMU recipe to it:
# left unversioned, haikuporter picks whatever provider it finds newest and the
# build dies on the version mismatch.
glibInstalled=$(installed_version glib2_x86)
glibDevelInstalled=$(installed_version glib2_x86_devel)
glibDevelRepository=$(repository_version glib2_x86_devel)

case "$GLIB_SOURCE" in
	auto)
		if [ -n "$glibDevelInstalled" ] && [ "$glibDevelInstalled" = "$glibInstalled" ]; then
			GLIB_SOURCE=installed
		elif [ -n "$glibDevelRepository" ] &&
			[ "$glibDevelRepository" = "${glibInstalled:-$glibDevelRepository}" ]; then
			GLIB_SOURCE=repository
		else
			GLIB_SOURCE=local
		fi
		;;
	installed|repository|local)
		;;
	*)
		echo "GLIB_SOURCE must be auto, installed, repository or local." >&2
		exit 2
		;;
esac

case "$GLIB_SOURCE" in
	installed)
		glibVersion=$glibInstalled
		echo "Using the glib2_x86 $glibVersion already installed."
		;;
	repository)
		glibVersion=${glibInstalled:-$glibDevelRepository}
		echo "Installing glib2_x86 $glibVersion from the package repository..."
		yes | pkgman install glib2_x86 glib2_x86_devel
		;;
	local)
		glibVersion=$BUNDLED_GLIB_VERSION
		if [ -n "$glibInstalled" ] && [ "$glibInstalled" != "$glibVersion" ]; then
			echo "Warning: glib2_x86 $glibInstalled is installed but GLib" \
				"$glibVersion will be built and installed over it." >&2
			echo "Warning: use GLIB_SOURCE=repository to keep the installed" \
				"GLib instead." >&2
		fi
		;;
esac

if [ "$GLIB_SOURCE" != local ]; then
	# Keep the bundled recipe out of the tree, otherwise haikuporter prefers it
	# over the package that is already there and rebuilds GLib for nothing.
	rm -rf "$ROOT/dev-libs/glib"
fi

sed -i "s|^[[:space:]]*devel:libglib_2\.0_x86[[:space:]]*\$|\tglib2_x86_devel == $glibVersion|" \
	"$QEMU_RECIPE"

cd "$ROOT"

if [ "$GLIB_SOURCE" = local ]; then
	echo "Building the compatible x86 GLib $glibVersion packages..."
	haikuporter --config="$CONFIG" --repository-update glib2_x86
	haikuporter --config="$CONFIG" --no-repository-update \
		-j"$JOBS" --no-source-packages glib2_x86
fi

echo "Building QEMU and all architecture subpackages..."
haikuporter --config="$CONFIG" --repository-update qemu
haikuporter --config="$CONFIG" --no-repository-update \
	-j"$JOBS" --no-source-packages qemu

echo "Build complete. Packages:"
ls -lh "$ROOT"/packages/qemu*.hpkg
