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

echo "OK"

