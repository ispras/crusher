#!/bin/bash

CRUSHER_DIR=/opt/crusher

echo core >/proc/sys/kernel/core_pattern

# --mod-client-runs <num>
cmd="$CRUSHER_DIR/bin_x86-64/fuzz \
      --config-file config.json --port 2000 \
      -i in -o out-1 -F \
      --delay 50 --timeout 250 \
      --pstate state-vars:no-handler,send:no-handler \
      -- $PWD/server/openssl-fuzz s_server \
      -cert $PWD/server/keys/cert.pem -key $PWD/server/keys/key.pem \
      -accept 2000 -naccept 1 -legacy_renegotiation"
echo "$cmd"
$cmd
