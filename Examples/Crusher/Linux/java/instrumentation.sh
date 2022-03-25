#!/bin/bash

if [[ "$#" -ne 1 ]]; then
    echo "Usage: ./instrumentation.sh <path/to/kelinci.jar>"
    exit 1
fi

KELINCI=$1

mkdir bin
cp target/test.class bin/test.class

echo "instrument project"
/usr/bin/java -cp ${KELINCI} edu.cmu.sv.kelinci.instrumentator.Instrumentor \
-i target/commons-math3-3.6.1.jar -o target/commons-math3-3.6.1-instr.jar

/usr/bin/java -cp ${KELINCI}:target/commons-math3-3.6.1-instr.jar edu.cmu.sv.kelinci.instrumentator.Instrumentor -i bin -o bin-instr

