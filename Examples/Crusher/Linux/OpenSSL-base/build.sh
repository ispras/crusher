# Download & build afl-gcc
wget https://github.com/AFLplusplus/AFLplusplus/archive/3.0c.tar.gz
tar xvf 3.0c.tar.gz
cd AFLplusplus-3.0c/
make -j4
cd ..

# Build OpenSSL
wget https://github.com/openssl/openssl/archive/OpenSSL_1_1_0a.tar.gz
tar xvf OpenSSL_1_1_0a.tar.gz
mkdir openssl
cd openssl-OpenSSL_1_1_0a
CC=../AFLplusplus-3.0c/afl-gcc ./config --prefix=$PWD/../openssl/ no-shared
make -j4
make install
cd ..

# Create SSL certificate & key
mkdir keys
./openssl/bin/openssl req -newkey rsa:2048 -new -nodes -x509 -days 3650 -keyout keys/key.pem -out keys/cert.pem -batch

# Compile custom library (for ISP_PRELOAD)
cd custom_lib/
make
cd -