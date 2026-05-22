#!/bin/bash

work_dir=$(dirname $(dirname $(readlink -e $0)))
docker build -f $work_dir/docker/Dockerfile -t openssl-fuzz:latest $work_dir/ $@
