#!/bin/bash

/opt/crusher/bin_x86-64/fuzz_manager --start 4 --dse-cores 0 --eat-cores 1 \
                                     -I csharp --dotnet /usr/bin/dotnet  \
                                     -i in -o out -F \
                                     -- ./target/AngleSharp.Fuzz.File/bin/Debug/net6.0/AngleSharp.Fuzz.File.dll __DATA__
