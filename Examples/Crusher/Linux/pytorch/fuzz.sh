#!/bin/bash

/opt/crusher/bin_x86-64/fuzz_manager --start 4 --eat-cores 2 --dse-cores 0 \
                                       -i in -o out -I PyInst -t 90000 \
                                       -- /usr/bin/python3 ./torch_load_fuzz.py @@
