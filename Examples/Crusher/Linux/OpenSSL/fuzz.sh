#!/bin/bash

CRUSHER_DIR=/opt/crusher

echo core >/proc/sys/kernel/core_pattern

$CRUSHER_DIR/bin_x86-64/fuzz_manager --start 6 --eat-cores 2 \
      --config-file config.json --port __free_port \
      -i in -o out -F \
      --delay 100 --timeout 250 \
      -- $PWD/server/openssl-fuzz s_server \
      -cert $PWD/server/keys/cert.pem -key $PWD/server/keys/key.pem \
      -accept __free_port -naccept 1 -legacy_renegotiation
