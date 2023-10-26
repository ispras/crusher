#!/bin/bash

ROOTFS=$1

# /dev/random & /dev/urandom & /dev/null
sudo umount $ROOTFS/dev/random
sudo umount $ROOTFS/dev/urandom
sudo umount $ROOTFS/dev/null

# /proc
sudo umount $ROOTFS/proc

# /sys
#sudo umount $ROOTFS/sys

#
rm -rf $ROOTFS/dev/*
rm -rf $ROOTFS/proc
