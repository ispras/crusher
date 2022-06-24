#!/bin/bash

if [[ "$#" -ne 1 ]]; then
    echo "Usage: ./instrument.sh </path/to/dotnet>"
    exit 1
fi

DOTNET=$1

echo "install SharpFuzz.CommandLine global .NET tool"

$DOTNET tool install --global SharpFuzz.CommandLine

echo "instrument dll"

sharpfuzz ./target/AngleSharp.Fuzz/AngleSharp.dll
sharpfuzz ./target/AngleSharp.Fuzz.File/AngleSharp.dll

echo "add SharpFuzz package"

cd ./target/AngleSharp.Fuzz
$DOTNET add package SharpFuzz --version 1.6.2
$DOTNET build
cd ../..


cd ./target/AngleSharp.Fuzz.File
$DOTNET add package SharpFuzz --version 1.6.2
$DOTNET build
cd ../..

