#!/bin/bash

work_dir=$(dirname $(readlink -e $0))
docker build -f $work_dir/Dockerfile -t ubuntu22_jasper:latest $work_dir/
