#!/bin/bash

echo core >/proc/sys/kernel/core_pattern
export ISP_PRELOAD=$WORK_DIR/custom_lib/custom_lib.so

/opt/crusher/bin_x86-64/fuzz -I StaticForkSrv --peach-pit ClientHello.xml \
                             -i in -o out-1 -F -- $WORK_DIR/openssl-1.1.0a/apps/openssl s_server -cert $WORK_DIR/keys/cert.pem -key $WORK_DIR/keys/key.pem -accept 2000 -www -naccept 1
