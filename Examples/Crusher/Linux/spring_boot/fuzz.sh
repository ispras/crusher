#!/bin/bash

# Validate input arguments
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <crusher_dir>"
    exit 1
fi
crusher_dir=$1

$crusher_dir/bin_x86-64/fuzz_manager --start 2 --eat-cores 1 --dse-cores 0 --pre-run $PWD/docker/license/license.sh --wait-next-instance 20000 --auto-stop-target-server --tcp-recv-response --docker ubuntu-springboot-fuzz -i $PWD/in -t 80000 --java-jacoco-trace --no-affinity --max-file-size 10M --port 8080 -o $PWD/out -I javajacoco --ip 127.0.0.1 --delay 60000 -T NetworkTCP -- /home/user/spring-petclinic/target/spring-petclinic-3.5.0-SNAPSHOT.jar org.springframework.boot.loader.launch.JarLauncher
