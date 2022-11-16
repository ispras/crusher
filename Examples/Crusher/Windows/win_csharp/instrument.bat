@echo off
setlocal enabledelayedexpansion

set SOURCE_DIR=%~dp0

set argC=0
for %%x in (%*) do (
  set /A argC+=1
)

if %argC% LSS 1 (
  echo Usage: build.bat \\path\\to\\dotnet.exe
  goto finish
)

set DOTNET=%1

echo Installing SharpFuzz.CommandLine .NET tool...
%DOTNET% tool install SharpFuzz.CommandLine --version 2.0.0 --tool-path %SOURCE_DIR%

set x=0

echo Instrumenting libraries...
%SOURCE_DIR%\sharpfuzz.exe .\\target\\AngleSharp.Fuzz.File\\AngleSharp.dll


echo Building project...
cd .\\target\\AngleSharp.Fuzz.File
%DOTNET% build
cd ..\..

:finish