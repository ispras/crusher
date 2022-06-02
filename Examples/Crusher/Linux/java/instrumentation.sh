#!/bin/bash

if [[ "$#" -ne 1 ]]; then
    echo "Usage: ./instrumentation.sh <path/to/kelinci>"
    exit 1
fi

KELINCI=$1

mkdir bin
cp target/test.class bin/test.class

echo "instrument project and libraries"

${KELINCI}/instrument -cp_i target/commons-math3-3.6.1.jar -i ./bin -o ./bin-instr


