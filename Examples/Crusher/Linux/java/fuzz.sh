#!/bin/bash

crusher_dir=$1

$crusher_dir/bin_x86-64/fuzz_manager --start 1 --eat-cores 0 --dse-cores 0 --pre-run $PWD/docker/license/license.sh --wait-next-instance 5000 --auto-stop-target-server --tcp-recv-response --docker keycloak-fuzz -i $PWD/in -t 80000 --java-jacoco-trace --no-affinity --max-file-size 10M --port 8080 -o $PWD/out -I javajacoco --ip 127.0.0.1 --delay 200000 -T NetworkTCP --jvm-options /home/keycloak/config.json -- /home/keycloak/keycloak-26.0.7/lib/quarkus-run.jar io.quarkus.bootstrap.runner.QuarkusEntryPoint --profile=dev start-dev
