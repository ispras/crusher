#!/bin/bash

if [[ "$#" -ne 1 ]]; then
    echo "Usage: ./fuzz.sh <path/to/fuzz_manager>"
    exit 1
fi

FUZZ_MAN=$1

$FUZZ_MAN --start 1 -t 1500 -i ../in -o out -F -I QemuLuaFull -T QemuIntegration --lua ./test.lua -- \
	-hda ../app/image.qcow2 -loadvm lua_test -m 12G --nographic
