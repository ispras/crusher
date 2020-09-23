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
    rm -f -r Out_tmp
}

# Test jasper

echo ""
echo "jasper analysis"
echo ""
clean_result

COMMAND="$FUZZMANAGER --start $CORES -i in -o out --dse-force 5000 -- ./jasper -f @@ -t mif -F Out_tmp -T mif"
echo $COMMAND
$COMMAND


