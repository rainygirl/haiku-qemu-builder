# QEMU for HaikuOS x86_gcc2

한국어 버전은 [`README.ko.md`](README.ko.md) 참고 / For Korean, see [`README.ko.md`](README.ko.md).

This project builds QEMU 8.2.2 from source on HaikuOS R1/beta6 x86_gcc2
without removing WebPositive or HaikuWebKit. It packages the result as HPKG
files and can install the common QEMU tools and x86 system emulators.

The build was developed and debugged on a real HaikuOS system. Claude Sonnet
was used during the development and debugging of this project.

## Why this exists

The repository QEMU package may require a newer `libxml2_x86` provider whose
installation conflicts with the WebPositive/HaikuWebKit packages shipped by
some beta6 images. This build uses a compatible local GLib build and does not
replace either browser package.

It also fixes a HaikuOS-specific startup failure where QEMU treats a missing
relocated `qemu.conf` as fatal, and a `pthread_cond_timedwait()` status
mismatch that can abort a running virtual machine.

## Requirements

- HaikuOS R1/beta6 on an x86_gcc2 hybrid installation
- Internet access
- At least 5 GB of free disk space
- Several hours on older hardware

## Build and install

```sh
chmod +x build.sh install.sh
./build.sh
./install.sh
```

If you are using an already-built package that predates this project's
missing-configuration patch, run:

```sh
./fix-installed-qemu.sh
```

The default work tree is `/boot/home/qemu-haiku-build`. Override it with:

```sh
QEMU_HAIKU_ROOT=/boot/home/my-qemu-build ./build.sh
```

The build uses one Ninja job by default to reduce memory pressure. Set
`BUILD_JOBS` if the machine can handle more:

```sh
BUILD_JOBS=2 ./build.sh
```

Re-running `build.sh` resumes the preserved Ninja build. It does not
reconfigure QEMU when `build/build.ninja` already exists.

## Output

HPKG files are placed in:

```text
/boot/home/qemu-haiku-build/packages/
```

`install.sh` installs the locally built GLib compatibility packages, QEMU
common package, and `qemu_x86`. It verifies that WebPositive and HaikuWebKit
remain installed.

## Mac OS 9

After installing `qemu_ppc`, use `run-macos9.sh` with Mac OS 9 media:

```sh
./install.sh ppc
./run-macos9.sh /path/to/macos9.iso
```

The script creates a 4 GB QCOW2 disk on first run and boots a `mac99` Power
Mac. You must supply installation media that you are legally entitled to use.
Some Mac OS 9 installer ISOs stop in OpenBIOS at `Trying cd:,\\:tbxi`; this is
an upstream firmware/media compatibility issue, not a HaikuOS package failure.
A pre-installed, bootable HFS disk image may be required.

## License

The scripts and project-specific patches are licensed under the MIT License.
QEMU, GLib, HaikuPorts recipes, and downloaded source archives retain their
respective upstream licenses.
