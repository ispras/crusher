#!/bin/bash

sudo -E chroot rootfs/ /qemu/qemu-static /usr/bin/gzip -d -c < in/seed.zip
