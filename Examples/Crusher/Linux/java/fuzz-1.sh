#!/bin/bash

crusher_dir=$1

$crusher_dir/bin_x86-64/fuzz -i in -o out -t 20000 --auto-stop-target-server -T NetworkTCP --port 8080 --ip 127.0.0.1 --delay 200000 -I javajacoco --jvm-options ./config.json -- ./docker/keycloak-26.0.7/lib/quarkus-run.jar io.quarkus.bootstrap.runner.QuarkusEntryPoint --profile=dev start-dev
