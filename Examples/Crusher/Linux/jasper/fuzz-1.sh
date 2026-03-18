#!/bin/bash

echo core >/proc/sys/kernel/core_pattern

/opt/crusher/bin_x86-64/fuzz -I StaticForkSrv --bitmap-size 65536 -i in -o out-1 -F -- /root/fuzz/jasper-fuzz/bin/jasper -f @@ -t mif -F Out_tmp -T mif
