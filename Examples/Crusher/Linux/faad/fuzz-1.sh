#!/bin/bash

echo core >/proc/sys/kernel/core_pattern

export AFL_PRELOAD=/root/fuzz/AFLplusplus/utils/argv_fuzzing/argvfuzz64.so
/opt/crusher/bin_x86-64/fuzz -I QemuUserForkSrv -T stdin -i in -o out-1 -F -- ./faad @@
