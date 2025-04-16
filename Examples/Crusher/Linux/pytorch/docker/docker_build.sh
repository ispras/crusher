#!/bin/bash

work_dir=$(dirname $(readlink -e $0))
docker build -f $work_dir/Dockerfile -t pytorch-fuzz:latest $work_dir/
