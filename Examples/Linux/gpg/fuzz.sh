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

# Test faad

echo ""
echo "gpg analysis"
echo ""
clean_result

COMMAND="$FUZZMANAGER --start $CORES -i in -o out --dse-force 10000 -- ./gpg @@"
echo $COMMAND
$COMMAND


