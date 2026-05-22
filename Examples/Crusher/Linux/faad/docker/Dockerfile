# Basic image
FROM ubuntu:22.04

# Setup env
ENV DEBIAN_FRONTEND=noninteractive
ENV WORK_DIR=/root/fuzz
WORKDIR $WORK_DIR

# Install deps
RUN apt update -y
RUN apt install -y gcc gcc-multilib g++ g++-multilib make git wget unzip libcurl4 gnupg2 \ 
    libglib2.0-0 ca-certificates gdb nano file

RUN apt install -y clang-14 llvm-14 aha lcov

RUN update-alternatives --install /usr/bin/clang clang /usr/bin/clang-14 0 \
    && update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-14 0 \
    && update-alternatives --install /usr/bin/llvm-profdata llvm-profdata /usr/bin/llvm-profdata-14 0 \
    && update-alternatives --install /usr/bin/llvm-cov llvm-cov /usr/bin/llvm-cov-14 0 \
    && update-alternatives --install /usr/bin/llvm-config llvm-config /usr/bin/llvm-config-14 0
    
RUN wget -O- https://download.oracle.com/java/21/latest/jdk-21_linux-x64_bin.deb -O /tmp/jdk21.deb \
    && apt-get install -y /tmp/jdk21.deb \
    && rm -f /tmp/jdk21.deb \
    && rm -rf /var/lib/apt/lists/*

# Install Ghidra
RUN wget https://github.com/NationalSecurityAgency/ghidra/releases/download/Ghidra_11.4.2_build/ghidra_11.4.2_PUBLIC_20250826.zip \
    && unzip ghidra_11.4.2_PUBLIC_20250826.zip
ENV GHIDRA_INSTALL_DIR=$WORK_DIR/ghidra_11.4.2_PUBLIC

# Compile AFL++ hook for argv fuzzing
RUN git clone --depth 1 --branch v4.40c https://github.com/AFLplusplus/AFLplusplus
RUN cd AFLplusplus/ \
    && make -j \
    && cd utils/argv_fuzzing \
    && make all

# Install target deps
RUN apt update -y \
    && apt install -y libfaad2

# Setup license
RUN echo 'deb https://repo.ispras.ru/apt /' | tee /etc/apt/sources.list.d/ispras.list \
    && wget -q -O - https://repo.ispras.ru/apt/key.asc | apt-key add - \
    && apt update -y \
    && apt install -y aksusbd
COPY setup_license.sh /opt/setup_license.sh
RUN echo "/opt/setup_license.sh 101213 36343" >> ~/.bashrc
