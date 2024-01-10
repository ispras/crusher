FROM ubuntu:20.04

RUN apt update \
    && apt upgrade -y \
    && apt install -y wget build-essential checkinstall zlib1g-dev zip \
    gcc g++ gcc-multilib g++-multilib make sudo git wget libreadline-dev \
    zlib1g-dev bison flex libfl-dev acl python3 gnupg2 aha llvm-12 clang-12 libssl-dev lcov

RUN update-alternatives --install /usr/bin/clang clang /usr/bin/clang-12 0 \
    && update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-12 0 \
    && update-alternatives --install /usr/bin/llvm-profdata llvm-profdata /usr/bin/llvm-profdata-12 0 \
    && update-alternatives --install /usr/bin/llvm-cov llvm-cov /usr/bin/llvm-cov-12 0 \
    && update-alternatives --install /usr/bin/llvm-config llvm-config /usr/bin/llvm-config-12 0

RUN apt update && apt install -y libbfd-dev libunwind-dev libffi-dev
RUN cd /tmp && wget http://archive.ubuntu.com/ubuntu/pool/main/libf/libffi/libffi6_3.2.1-8_amd64.deb && dpkg -i libffi6_3.2.1-8_amd64.deb && rm -rf libffi6_3.2.1-8_amd64.deb

WORKDIR /deps

# LZ4-devel
RUN apt-get install -y liblz4-dev

# Set Timezone or get hang during the docker build...
ENV TZ=Europe/Moscow
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Packages for neural networks
RUN apt install -y python3-pip
RUN pip3 install tensorflow && \
    pip3 install numpy && \
    pip3 install imageio
	 
ENV BASH_ENV=/venv3.8/bin/activate

WORKDIR /

RUN apt update \
    && apt install -y libglib2.0-0

# Libcurl
RUN apt-get update \
    && apt-get install -y libcurl4-openssl-dev

#install setuptools
RUN pip3 install setuptools

# Extra deps
RUN apt install -y nano

# Fuzz-target
RUN mkdir /root/fuzz
WORKDIR /root/fuzz
COPY torch_load_fuzz.py torch_load_fuzz.py
COPY in/ in/
