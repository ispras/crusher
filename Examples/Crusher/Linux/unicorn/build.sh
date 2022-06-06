#!/bin/bash

if [[ "$#" -ne 2 ]]; then
    echo "Error: not enough arguments"
    echo "Usage: ./build.sh -f <path/to/crusher/bin_x86-64>"
    exit 1
fi

echo "Building Unicorn examples"
echo "Note: assuming qiling/unicorn module is installed"

export UNICORNAFL_DIR="$(readlink -e "$2/unicornafl")"

cd c
make clean
make

cd ..

