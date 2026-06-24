#!/bin/bash

script_file=$(realpath $0)
work_dir=$(dirname $script_file)
if [ "$#" -ne 2 ]; then
    echo "Usage: $script_file <crusher_dir> <hasp_ip>" >&2
    exit 1
fi
crusher_dir=$(realpath $1)
circea_dir=$crusher_dir/circea
hasp_ip=$2

DOCKER_BUILDKIT=1 docker buildx build \
                         --network host \
                         --build-context circea=$circea_dir \
                         -f $work_dir/Dockerfile \
                         $work_dir \
                         -t nginx-fuzz \
                         --build-arg HASP_IP=$hasp_ip
