#!/bin/bash

script_file=$(realpath $0)
work_dir=$(dirname $script_file)
if [ "$#" -ne 1 ]; then
    echo "Usage: $script_file <crusher_dir>" >&2
    exit 1
fi
crusher_dir=$1

# --pre-run $work_dir/pre-run.sh
cmd="$crusher_dir/bin_x86-64/fuzz_manager --start 4 --eat-cores 2 --dse-cores 0 --docker nginx-fuzz --config-file $work_dir/config.json --port 80 -i $work_dir/in/ -o $work_dir/out -- /root/fuzz/nginx-fuzz/sbin/nginx"
echo $cmd
$cmd
