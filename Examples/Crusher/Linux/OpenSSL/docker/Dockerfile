FROM ubuntu:22.04

# 1. Настройка окружения
ENV TZ=Europe/Moscow
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
ENV WORK_DIR=/root/fuzz/
RUN mkdir -p $WORK_DIR
WORKDIR $WORK_DIR

# 2. Установка зависимостей
RUN apt update -y \
    && apt upgrade -y \
    && apt install -y wget liblz4-dev libcurl4-openssl-dev gnupg2 git \
       gcc gcc-multilib g++ g++-multilib make nano libglib2.0-dev
RUN apt install -y clang-14 llvm-14 aha lcov
RUN update-alternatives --install /usr/bin/clang clang /usr/bin/clang-14 0 \
        && update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-14 0 \
        && update-alternatives --install /usr/bin/llvm-profdata llvm-profdata /usr/bin/llvm-profdata-14 0 \
        && update-alternatives --install /usr/bin/llvm-cov llvm-cov /usr/bin/llvm-cov-14 0 \
        && update-alternatives --install /usr/bin/llvm-config llvm-config /usr/bin/llvm-config-14 0

# Создание SSL-сертификата и ключа
# RUN mkdir keys \
#    && $WORK_DIR/openssl-1.1.0a/apps/openssl req -newkey rsa:2048 -new -nodes -x509 -days 3650 -keyout keys/key.pem -out keys/cert.pem -batch -config openssl-1.1.0a/apps/openssl.cnf

# 4. Настройка лицензии
RUN echo 'deb https://repo.ispras.ru/apt /' | tee /etc/apt/sources.list.d/ispras.list \
    && wget -q -O - https://repo.ispras.ru/apt/key.asc | apt-key add - \
    && apt update -y \
    && apt install -y aksusbd
COPY docker/setup_license.sh /opt/setup_license.sh
RUN echo "/opt/setup_license.sh 101213 36343" >> ~/.bashrc
