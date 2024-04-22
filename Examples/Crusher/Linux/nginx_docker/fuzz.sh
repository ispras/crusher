#!/bin/bash
if [ -z "$1" ]
    then
        echo "Usage: fuzz.sh /path/to/crusher"
    else
        PATH_TO_CRUSHER=$(realpath -m $1)
        $PATH_TO_CRUSHER/bin_x86-64/fuzz_manager --start 4 --eat-cores 2 --dse-cores 0 --pre-run ./docker/license/license.sh --wait-next-instance 2000 --ip 127.0.0.1 --port 8080 -I StaticForkSrv --bitmap-size 65536 -T NetworkTCP  --delay 3000 -t 10000 -F -i $PWD/in/ -o $PWD/out --docker nginx-demo  --clean-binary /root/target/nginx-clean/sbin/nginx  -- /root/target/nginx-fuzz/sbin/nginx
fi
