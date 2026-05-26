#!/bin/bash

prev_dir=$PWD
server_dir=$(dirname $(realpath $0))
cd $server_dir

# 1. Собрать AFL++ компилятор с помощью ISP-Circea

CIRCEA_CC="/opt/crusher/circea/bin/clang"
CIRCEA_CXX="/opt/crusher/circea/bin/clang++"
CIRCEA_LLVM_CONFIG="/opt/crusher/circea/bin/llvm-config"

CIRCEA_FLAGS="-circea-recursion \
              -circea-state-var \
              -circea-send \
              -circea-array-indexing" 

# 2. Скачать исходники OpenSSL

git clone https://github.com/openssl/openssl
cd openssl
git checkout OpenSSL_1_1_1j

# 3. Применить патчи

git apply $server_dir/server.patch

# 4. Выполнить сборки

## 4.1. Основная сборка (с битовой картой покрытия)

make clean && make distclean || echo "skip errors"
CC=$CIRCEA_CC CFLAGS="$CIRCEA_FLAGS" ./config no-shared no-tests
make -j8
cp apps/openssl ../openssl-fuzz || exit 1

## 4.2. ASan-сборка

make clean && make distclean || echo "skip errors"
CC=$CIRCEA_CC CFLAGS="$CIRCEA_FLAGS" ./config no-shared no-tests enable-asan
make -j8
cp apps/openssl ../openssl-fuzz-asan

## 4.3. MSan-сборка

make clean && make distclean || echo "skip errors"
CC=$CIRCEA_CC CFLAGS="$CIRCEA_FLAGS" ./config no-shared no-tests enable-msan
make -j8
cp apps/openssl ../openssl-fuzz-msan

## 4.4. LCOV-сборка - для отчёта о покрытии по исходному коду

COV_FLAGS="-fprofile-instr-generate \
           -fcoverage-mapping \
           -fcoverage-mcdc \
           -circea-no-afl-pass \
           -circea-no-forkserver-rt"

make clean && make distclean || echo "skip errors"
CC=$CIRCEA_CC CFLAGS=$COV_FLAGS LDFLAGS=$COV_FLAGS ./config no-shared no-tests
make -j8
cp apps/openssl ../openssl-cov

## 4.5. Чистая сборка (без инструментации) - для отчёта о покрытии бинарного кода

make clean && make distclean || echo "skip errors"
CFLAGS="-ggdb3 -O0" ./config no-shared no-tests
make -j8
cp apps/openssl ../openssl-clean

cd $prev_dir

# 5. Создание SSL-сертификата и ключа
# Use prepared files to reproduce crash (crashes/id_crash_000000)
# mkdir -p server/keys
# ./server/openssl-fuzz req -newkey rsa:2048 -new -nodes -x509 -days 3650 -keyout server/keys/key.pem -out server/keys/cert.pem -batch -config server/openssl/apps/openssl.cnf
