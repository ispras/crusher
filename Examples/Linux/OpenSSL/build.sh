# Build OpenSSL
cd Linux/OpenSSL
##wget https://github.com/openssl/openssl/archive/OpenSSL_1_1_0a.tar.gz
tar xvf OpenSSL_1_1_0a.tar.gz
mkdir openssl
cd openssl-OpenSSL_1_1_0a
CC=../../../../bin_x86-64/isp-gcc ./config --prefix=$PWD/../openssl/
make -j 4
make install
cd -

# Create certificates
mkdir keys
./openssl/bin/openssl req -newkey rsa:2048 -new -nodes -x509 -days 3650 -keyout keys/key.pem -out keys/cert.pem -batch

# Compile custom library
cd custom_lib/
make
cd -