#!/bin/bash

work_dir=$(realpath $(dirname $0))

docker build -t keycloak-fuzz -f $work_dir/Dockerfile-fuzz $work_dir --build-arg USER_ID=$UID --build-arg USER_NAME=user --build-arg GROUP_ID=$(id -g)

