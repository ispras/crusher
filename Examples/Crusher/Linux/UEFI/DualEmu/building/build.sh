#!/bin/bash

set -x

BASE=/building # assuming running here

chmod 0777 /tmp || exit 1
apt update -y || exit 1
apt install -y gcc build-essential uuid-dev iasl nasm python-is-python3 \
    vim git file qemu-system ovmf dosfstools grub-efi-amd64 \
    autoconf automake autopoint pkg-config m4 libtool flex bison gawk pev \
    || exit 1

git clone https://github.com/tianocore/edk2 || exit 1
cd edk2 || exit 1
git checkout edk2-stable202311  || exit 1
git submodule update --recursive --init || exit 1
make -C BaseTools || exit 1
source ./edksetup.sh || exit 1
cp $BASE/edk2_config.txt Conf/target.txt || exit 1
build || exit 1
cp ./Build/OvmfX64/DEBUG_GCC/FV/OVMF.fd $BASE/ovmf.fd || exit 1
cd ..

git clone https://git.savannah.gnu.org/git/grub.git || exit 1
cd grub || exit 1
git checkout 8719cc2040 || exit 1
./bootstrap || exit 1
mkdir inst || exit 1
./configure --prefix=$(realpath inst) --with-platform=efi || exit 1
patch -p1 < $BASE/grub_emu_patch.txt || exit 1
make -j && make install || exit 1
./inst/bin/grub-mkstandalone -O x86_64-efi -o grub.efi || exit 1
cd ..

dd if=/dev/zero of=$BASE/boot.img bs=1M count=512 || exit 1
mkfs.vfat $BASE/boot.img || exit 1
mkdir $BASE/mnt || exit 1
mount $BASE/boot.img $BASE/mnt || exit 1
mkdir -p $BASE/mnt/efi/boot/ || exit 1
cp $BASE/grub/grub.efi $BASE/mnt/efi/boot/bootx64.efi || exit 1
umount $BASE/mnt || exit 1

echo "OK"

