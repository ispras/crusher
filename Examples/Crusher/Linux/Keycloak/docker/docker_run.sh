#!/bin/bash

work_dir=$(realpath $(dirname $(dirname $0)))

docker run --rm -v "$work_dir":"$work_dir" -w "$work_dir" -ti keycloak-fuzz /bin/bash
