#!/bin/bash

if [[ "$#" -ne 1 ]]; then
    echo "Usage: ./instrument.sh </path/to/dotnet>"
    exit 1
fi

DOTNET=$1

echo "installing SharpFuzz.CommandLine .NET tool..."

if [ -f "sharpfuzz" ]; then
    $DOTNET tool uninstall SharpFuzz.CommandLine --tool-path .
fi

$DOTNET tool install SharpFuzz.CommandLine --version 2.0.0 --tool-path .

echo "instrumenting dlls..."

./sharpfuzz ./target/AngleSharp.Fuzz/AngleSharp.dll
./sharpfuzz ./target/AngleSharp.Fuzz.File/AngleSharp.dll

echo "adding SharpFuzz package..."

cd ./target/AngleSharp.Fuzz
$DOTNET add package SharpFuzz --version 1.6.2
$DOTNET build
cd ../..


cd ./target/AngleSharp.Fuzz.File
$DOTNET add package SharpFuzz --version 1.6.2
$DOTNET build
cd ../..

