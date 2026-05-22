#!/bin/bash

./client/openssl/apps/openssl s_client -tls1_2 -connect 127.0.0.1:2000 -legacy_renegotiation
