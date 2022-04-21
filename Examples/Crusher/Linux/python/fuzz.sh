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

# Test python

echo ""
echo "python analysis"
echo ""
clean_result

COMMAND="$FUZZMANAGER --start $CORES --eat-cores 1 --dse-cores 0 -i in -o out -t 20000 -- ./python-2.5 __DATA__"
echo $COMMAND
$COMMAND


