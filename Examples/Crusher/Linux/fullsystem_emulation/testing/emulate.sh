#!/bin/bash

if [[ "$#" -ne 1 ]]; then
    echo "Usage: ./emulate.sh <path/to/qemu>"
    exit 1
fi

QEMU=$1

${QEMU} -nographic -lua ./test.lua.FUZZ -fuzzer-config ./config.json -hda ../app/image.qcow2 \
	-loadvm lua_test -m 12G
