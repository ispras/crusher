@echo off
setlocal enabledelayedexpansion

set SOURCE_DIR=%~dp0

set argC=0
for %%x in (%*) do (
  set /A argC+=1
)

if %argC% LSS 2 (
  echo Usage: build.bat \\path\\to\\dotnet.exe \\path\\to\\fuzz_manager \\path\\to\\dotnet
  goto finish
)

set FUZZ_MAN=%1
set DOTNET=%2

%FUZZ_MAN% --start 4 -F -i in -o out -I csharp --dotnet $DOTNET -- .\\target\\AngleSharp.Fuzz.File\\bin\\Debug\\net6.0\\AngleSharp.Fuzz.File.dll __DATA__

:finish