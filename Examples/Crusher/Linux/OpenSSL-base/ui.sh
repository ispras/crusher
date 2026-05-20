#!/bin/bash

work_dir=$(dirname $(readlink -e $0))
docker exec -ti openssl-base /bin/bash -c "/opt/crusher/bin_x86-64/ui -o $work_dir/out"
