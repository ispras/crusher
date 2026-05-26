#!/bin/bash

work_dir=$(dirname $(realpath $0))

cmd="$work_dir/server/openssl-fuzz s_server -cert $work_dir/server/keys/cert.pem -key $work_dir/server/keys/key.pem -tls1_2 -accept 2000 -naccept 1 -legacy_renegotiation"
echo $cmd
$cmd
