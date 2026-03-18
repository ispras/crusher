#!/bin/bash

echo core >/proc/sys/kernel/core_pattern

/opt/crusher/bin_x86-64/fuzz_manager --start 4 --eat-cores 2 --dse-cores 1 --wait-next-instance 500 -I StaticForkSrv --bitmap-size 65536 --clean-binary /root/fuzz/jasper-clean/bin/jasper --coverage-binary /root/fuzz/jasper-cov/bin/jasper -i in -o out -F -- /root/fuzz/jasper-fuzz/bin/jasper -f @@ -t mif -F Out_tmp -T mif
