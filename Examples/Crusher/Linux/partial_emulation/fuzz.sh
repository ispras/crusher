#!/bin/bash

if [[ "$#" -ne 4 ]]; then
    echo "Error: not enough arguments"
    echo "Usage: ./fuzz.sh -f <path/to/crusher/bin_x86-64/fuzz_manager> -c <cores count>"
    exit 1
fi

FUZZMANAGER=$2
CORES=$4

clean_result () {
    rm -f -r out
}

echo ""
echo "Partial emulation fuzzing"
echo ""
clean_result

COMMAND="$FUZZMANAGER --start $CORES --eat-cores 1 --dse-cores 1 -i in -o out -I dualemu -T dualemu -- emu_script_dump.py"
echo $COMMAND
$COMMAND
