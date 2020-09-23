#!/bin/bash

if [[ "$#" -ne 4 ]]; then
    echo "Error: not enough arguments"
    echo "Usage: ./fuzz.sh -f <path/to/crusher/bin_x86-64/fuzz_manager> -c <cores count>"
    exit 1
fi

FUZZMANAGER=$2
CORES=$4

clean_result () {
    rm -f -r out
}

# Test python

echo ""
echo "OpenSSL analysis"
echo ""
clean_result

COMMAND="$FUZZMANAGER --start $CORES -T IspPreloadNetworkToFile -I StaticForkSrv --port __free_port -t 2000 -o out --peach-pit $PWD/ClientHello.xml -F -i in -- $PWD/openssl/bin/openssl s_server -cert $PWD/keys/cert.pem -key $PWD/keys/key.pem -accept __free_port -www -naccept 1 @@"
echo $COMMAND
$COMMAND
