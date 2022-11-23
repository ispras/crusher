#!/bin/bash

if [[ "$#" -ne 2 ]]; then
    echo "Usage: ./fuzz-file.sh </path/to/fuzz_manager> </path/to/dotnet>"
    exit 1
fi

FUZZ_MAN=$1
DOTNET=$2

$FUZZ_MAN --start 4 --dse-cores 0 --eat-cores 1 -F -i in -o out -I csharp --dotnet $DOTNET -- ./target/AngleSharp.Fuzz.File/bin/Debug/net6.0/AngleSharp.Fuzz.File.dll __DATA__