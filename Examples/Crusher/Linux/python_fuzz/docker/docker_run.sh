#!/bin/bash

script_file=$(readlink -e $0)
test_dir=$(dirname $(dirname $script_file))

if [ "$#" -lt 1 ]; then
    echo "Usage: $script_file <crusher_dir> [hasp_ip]" >&2
    exit 1
fi

crusher_dir=$(readlink -e $1)
echo "crusher - $crusher_dir"

hasp_ip=""
if [ ! -z "$2" ]; then
    hasp_ip_env="-e HASP_IP=$2"
fi

cmd="docker run --rm --privileged --network host -e LANG=C.UTF-8 -e LC_ALL=C.UTF-8 -v $crusher_dir:/opt/crusher -v $test_dir:$test_dir $hasp_ip_env -ti pdfquery-fuzz:latest /bin/bash"
echo "$cmd"
$cmd
