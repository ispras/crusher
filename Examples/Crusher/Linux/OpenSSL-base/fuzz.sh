#!/bin/bash

export ISP_PRELOAD=$WORK_DIR/custom_lib/custom_lib.so

/opt/crusher/bin_x86-64/fuzz_manager --start 8 --eat-cores 2 --dse-cores 0 \
                                     -I StaticForkSrv --peach-pit ClientHello.xml \
                                     -i in -o out -- $WORK_DIR/openssl-1.1.0a/apps/openssl s_server -cert $WORK_DIR/keys/cert.pem -key $WORK_DIR/keys/key.pem -accept 2000 -www -naccept 1
