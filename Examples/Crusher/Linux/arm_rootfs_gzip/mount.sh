#!/bin/bash

ROOTFS=$1

# /dev/random & /dev/urandom
mkdir $ROOTFS/dev
touch $ROOTFS/dev/random
touch $ROOTFS/dev/urandom
touch $ROOTFS/dev/null

sudo mount --rbind /dev/random $ROOTFS/dev/random
sudo mount --rbind /dev/urandom $ROOTFS/dev/urandom
sudo mount --rbind /dev/null $ROOTFS/dev/null

# /proc
mkdir $ROOTFS/proc
sudo mount --bind /proc $ROOTFS/proc

# /sys
#mkdir $ROOTFS/sys || echo "exists"
#sudo mount --bind /sys $ROOTFS/sys

# /tmp
mkdir $ROOTFS/tmp
