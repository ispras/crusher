#!/bin/bash

if [[ "$#" -ne 1 ]]; then
    echo "Usage: ./fuzz.sh <path/to/fuzz_manager>"
    exit 1
fi

FUZZ_MAN=$1

$FUZZ_MAN --start 10 -F -i in -o out -I PyInst -- target/pdfquery/load/testpdf.py @@

