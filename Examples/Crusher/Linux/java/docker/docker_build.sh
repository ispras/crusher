#!/bin/bash

work_dir=$(dirname $0)

docker build -t keycloak-fuzz -f $work_dir/Dockerfile $work_dir

