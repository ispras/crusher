# Basic image
FROM ubuntu:20.04

# Install deps
RUN apt update \
    && apt install -y libglib2.0-0 \
    && apt install patch \
    && apt-get install -y wget \
    && apt upgrade -y \
    && apt install -y wget build-essential checkinstall zlib1g-dev zip \
    gcc g++ gcc-multilib g++-multilib make sudo git wget libreadline-dev \
    zlib1g-dev bison flex libfl-dev acl python3 gnupg2 aha llvm-12 clang-12 libssl-dev lcov \
    &&  update-alternatives --install /usr/bin/clang clang /usr/bin/clang-12 0 \
    && update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-12 0 \
    && update-alternatives --install /usr/bin/llvm-profdata llvm-profdata /usr/bin/llvm-profdata-12 0 \
    && update-alternatives --install /usr/bin/llvm-cov llvm-cov /usr/bin/llvm-cov-12 0 \
    && update-alternatives --install /usr/bin/llvm-config llvm-config /usr/bin/llvm-config-12 0 \
    && apt install -y net-tools netcat zlib1g zlib1g-dev libpcre3 libpcre3-dev \
    && apt install -y systemd sudo nano iputils-ping

# Install hasplmd (for network license support)
WORKDIR /root
COPY license /root/license
RUN mkdir -p /etc/hasplm
RUN cp /root/license/hasplm.ini /etc/hasplm/hasplm.ini
# Check hasplmd
RUN /root/license/hasplmd.sh && /root/license/test-protected

# Build targets
COPY ./target /root/target
WORKDIR /root/target

## Get src
RUN wget https://nginx.org/download/nginx-1.21.4.tar.gz
RUN tar xvf nginx-1.21.4.tar.gz
WORKDIR /root/target/nginx-1.21.4/

## Patch src
RUN ../patch_src.sh

## Build clean binary
# configure
WORKDIR /root/target/nginx-1.21.4/
RUN CC="gcc" ./configure --prefix=$PWD/../nginx-clean --with-select_module

# make
RUN make install -j
RUN make clean 

# patch conf
WORKDIR /root/target/nginx-clean
RUN ../patch_conf.sh
RUN sed -i "s/FUZZ_PORT/8080/" conf/nginx.conf

## Build fuzz binary
# configure
WORKDIR /root/target/nginx-1.21.4/
RUN CC="../afl_compilers/afl-gcc" ./configure --prefix=$PWD/../nginx-fuzz --with-select_module

# make
RUN make install -j
RUN make clean #&& make distclean

# patch conf
WORKDIR /root/target/nginx-fuzz
RUN ../patch_conf.sh
RUN sed -i "s/FUZZ_PORT/8080/" conf/nginx.conf

