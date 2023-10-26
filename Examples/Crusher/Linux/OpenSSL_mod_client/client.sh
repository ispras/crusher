#!/bin/bash

./client/openssl-clean s_client -tls1_2 -connect 127.0.0.1:4444 -legacy_renegotiation
