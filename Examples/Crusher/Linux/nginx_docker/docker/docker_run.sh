#!/bin/bash

script_file=$(realpath $0)
work_dir=$(dirname $(dirname $script_file))
if [ "$#" -ne 1 ]; then
    echo "Usage: $script_file <crusher_dir>" >&2
    exit 1
fi
crusher_dir=$1

cmd="docker run --name nginx --rm --privileged --network default -e LANG=C.UTF-8 -e LC_ALL=C.UTF-8 -v $work_dir:$work_dir -v $crusher_dir:/opt/crusher -w $work_dir -ti nginx-fuzz /bin/bash"
echo $cmd
$cmd

