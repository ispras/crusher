#!/bin/bash

./server/openssl-debug s_server -cert ./keys/cert.pem -key ./keys/key.pem -tls1_2 -accept 4444 -naccept 1 -legacy_renegotiation
