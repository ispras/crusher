#!/bin/bash

echo core >/proc/sys/kernel/core_pattern

export AFL_PRELOAD=/root/fuzz/AFLplusplus/utils/argv_fuzzing/argvfuzz64.so
/opt/crusher/bin_x86-64/fuzz_manager --start 4 --eat-cores 2 --dse-cores 0 -I QemuUserForkSrv -T stdin -i in -o out -F -- ./faad @@
