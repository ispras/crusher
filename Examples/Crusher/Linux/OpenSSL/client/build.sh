#!/bin/bash

prev_dir=$PWD
client_dir=$(dirname $(realpath $0))
cd $client_dir

# 1. Скачать исходники OpenSSL

git clone https://github.com/openssl/openssl
cd openssl
git checkout 5c3c8369f3b42ce4b816606bb9bbad00c664a416

# 2. Применить патчи

git apply $client_dir/client.patch

# 3. Выполнить сборку

CIRCEA_CC="/opt/crusher/circea/bin/clang"
CIRCEA_CXX="/opt/crusher/circea/bin/clang++"
CIRCEA_LLVM_CONFIG="/opt/crusher/circea/bin/llvm-config"

CIRCEA_MOD_CLIENT_FLAGS="-circea-forkserver-into-client \
                         -circea-state-var-mutate" 

make clean && make distclean || echo "skip errors"
CC=$CIRCEA_CC CXX=$CIRCEA_CXX LLVM_CONFIG=$CIRCEA_LLVM_CONFIG LD=$CIRCEA_CC CFLAGS="$CIRCEA_MOD_CLIENT_FLAGS" LDFLAGS="$CIRCEA_MOD_CLIENT_FLAGS" ./config no-shared no-tests
make -j8
cp apps/openssl ../openssl-clean

cd $prev_dir
