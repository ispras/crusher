# Basic image
FROM ubuntu:22.04

# Setup env
ENV WORK_DIR=/root/fuzz
WORKDIR $WORK_DIR

# Install deps
RUN apt update -y

RUN apt install -y git gcc make libpcre3-dev zlib1g-dev libssl-dev gnupg2 wget --fix-missing libglib2.0-dev

RUN apt install -y clang-14 llvm-14 aha lcov
RUN update-alternatives --install /usr/bin/clang clang /usr/bin/clang-14 0 \
        && update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-14 0 \
        && update-alternatives --install /usr/bin/llvm-profdata llvm-profdata /usr/bin/llvm-profdata-14 0 \
        && update-alternatives --install /usr/bin/llvm-cov llvm-cov /usr/bin/llvm-cov-14 0 \
        && update-alternatives --install /usr/bin/llvm-config llvm-config /usr/bin/llvm-config-14 0

# Install afl-compilers
RUN git clone --depth 1 --branch v4.40c https://github.com/AFLplusplus/AFLplusplus
RUN cd AFLplusplus \
    && make install -j

# Clone & patch sources
COPY nginx.patch $WORK_DIR/nginx.patch
RUN git clone --depth 1 --branch release-1.28.0 https://github.com/nginx/nginx
WORKDIR $WORK_DIR/nginx
RUN git apply $WORK_DIR/nginx.patch

# Build clean binary
RUN ./auto/configure --prefix=$PWD/../nginx-clean --with-select_module
RUN make install -j
RUN make clean

# Build fuzz binary
RUN CC=afl-clang-fast ./auto/configure --prefix=$PWD/../nginx-fuzz --with-select_module
RUN make install -j
RUN make clean

# Build cov binary
RUN --mount=type=bind,from=circea,source=./,target=/opt/circea,ro \
    CC=/opt/circea/bin/clang ./auto/configure --prefix=$PWD/../nginx-cov --with-select_module --with-cc-opt="-fprofile-instr-generate -fcoverage-mapping" --with-ld-opt="-fprofile-instr-generate -fcoverage-mapping" \
    && make install -j \
    && make clean

# Setup license
ARG HASP_IP
ENV HASP_IP=$HASP_IP
RUN echo "HASP_IP = $HASP_IP"

RUN echo 'deb https://repo.ispras.ru/apt /' | tee /etc/apt/sources.list.d/ispras.list \
    && wget -q -O - https://repo.ispras.ru/apt/key.asc | apt-key add - \
    && apt update -y \
    && apt install -y aksusbd
COPY license/setup_license.sh /opt/setup_license.sh
RUN echo "/opt/setup_license.sh 101213 36343" >> ~/.bashrc
# check
COPY license/test-protected /tmp/test-protected
RUN /opt/setup_license.sh 101213 36343 && /tmp/test-protected


