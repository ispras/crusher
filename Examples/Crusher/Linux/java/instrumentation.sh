#!/bin/bash

if [[ "$#" -ne 2 ]]; then
    echo "Usage: ./instrumentation.sh <path/to/kelinci> <path/to/javac>  "
    exit 1
fi

KELINCI=$1
JAVAC=$2

mkdir bin

echo "compile driver"
${JAVAC} -cp target/commons-math3-3.6.1.jar target/test.java -d bin

echo "instrument project and libraries"

${KELINCI}/instrument -cp_i target/commons-math3-3.6.1.jar -i ./bin -o ./bin-instr


