#!/bin/sh
set -eu

BIN_DIR=/boot/home/config/non-packaged/bin
mkdir -p "$BIN_DIR"

write_wrapper()
{
	name=$1
	target="/boot/system/bin/$name"

	if [ ! -x "$target" ]; then
		echo "Skipping missing executable: $target"
		return
	fi

	{
		echo '#!/bin/sh'
		echo "exec $target -no-user-config \"\$@\""
	} > "$BIN_DIR/$name"
	chmod +x "$BIN_DIR/$name"
}

write_wrapper qemu-system-i386
write_wrapper qemu-system-x86_64
write_wrapper qemu-system-ppc

qemu-system-x86_64 --version
