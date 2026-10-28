#!/bin/sh
set -eu
# registers the qemu binfmt handlers the foreign arch containers need
# docker/setup-qemu-action is not used, it ships no ppc64 (big endian) handler
# the stock qemu entries require zero ELF pad bytes, uruntime stamps AI there
# so AppImages would fail to exec, these entries ignore osabi, pad and e_type
sudo apt-get update
# ubuntu 26.04 made qemu-user-static a virtual package, provided by
# qemu-user-binfmt, which is what has to be installed there
if ! sudo apt-get install -y --no-install-recommends qemu-user-static; then
	sudo apt-get install -y --no-install-recommends qemu-user-binfmt
fi

if [ ! -e /proc/sys/fs/binfmt_misc/register ]; then
	sudo mount -t binfmt_misc binfmt_misc /proc/sys/fs/binfmt_misc
fi

# ubuntu 26.04 dropped the wrappers and ships the binaries in /usr/bin
interp() {
	if [ -d /usr/libexec/qemu-binfmt ]; then
		printf '/usr/libexec/qemu-binfmt/%s-binfmt-P\n' "$1"
	else
		printf '/usr/bin/qemu-%s\n' "$1"
	fi
}

register() {
	sudo sh -c "echo -1 > /proc/sys/fs/binfmt_misc/qemu-$1" 2>/dev/null || true
	printf ':qemu-%s:M::%s:%s:%s:OPF\n' "$1" "$2" "$3" "$(interp "$1")" |
		sudo tee /proc/sys/fs/binfmt_misc/register
}
#                                     magic (e_machine last)                                 mask
register aarch64     '\x7f\x45\x4c\x46\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xb7\x00' '\xff\xff\xff\xff\xff\xff\xff\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xff\xff'
register riscv64     '\x7f\x45\x4c\x46\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xf3\x00' '\xff\xff\xff\xff\xff\xff\xff\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xff\xff'
register loongarch64 '\x7f\x45\x4c\x46\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x01' '\xff\xff\xff\xff\xff\xff\xff\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xff\xff'
register ppc64       '\x7f\x45\x4c\x46\x02\x02\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x15' '\xff\xff\xff\xff\xff\xff\xff\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xff\xff'
register ppc64le     '\x7f\x45\x4c\x46\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x15\x00' '\xff\xff\xff\xff\xff\xff\xff\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xff\xff'
