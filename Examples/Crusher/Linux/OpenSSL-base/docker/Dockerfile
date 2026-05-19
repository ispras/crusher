FROM ubuntu:22.04

# Настройка окружения
ENV TZ=Europe/Moscow
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
ENV WORK_DIR=/root/fuzz/openssl
RUN mkdir -p $WORK_DIR
WORKDIR $WORK_DIR

# Установка зависимостей
RUN apt update \
    && apt upgrade -y \
    && apt install -y wget liblz4-dev libcurl4-openssl-dev gnupg2 git \
       gcc gcc-multilib g++ g++-multilib clang llvm nano

# Сборка компилятора для инструментации OpenSSL
RUN apt install -y make llvm

RUN git clone --depth 1 --branch v4.10c https://github.com/AFLplusplus/AFLplusplus \
    && cd AFLplusplus \
    && make -j

# Сборка OpenSSL с инструментацией
# sed -i "s/'File::Glob' => qw\/glob\/;/'File::Glob' => qw\/:glob\/;/" test/build.info
RUN wget https://github.com/openssl/openssl/releases/download/OpenSSL_1_1_0a/openssl-1.1.0a.tar.gz \
    && tar xvf openssl-1.1.0a.tar.gz \
    && cd openssl-1.1.0a \
    && sed -i "s/'File::Glob' => qw\/glob\/;/'File::Glob' => qw\/:glob\/;/" Configure \
    && sed -i "s/'File::Glob' => qw\/glob\/;/'File::Glob' => qw\/:glob\/;/" test/build.info \
    && export CC=$WORK_DIR/AFLplusplus/afl-clang-fast \
    && ./config no-shared \
    && make -j

# Создание SSL-сертификата и ключа
RUN mkdir keys \
    && $WORK_DIR/openssl-1.1.0a/apps/openssl req -newkey rsa:2048 -new -nodes -x509 -days 3650 -keyout keys/key.pem -out keys/cert.pem -batch -config openssl-1.1.0a/apps/openssl.cnf

# Компиляция разделяемой библиотеки для замены некоторых сетевых функций (для ускорения фаззинга)
COPY custom_lib $WORK_DIR/custom_lib
RUN cd custom_lib \
    && make -j

# Настройка лицензии
RUN echo 'deb https://repo.ispras.ru/apt /' | tee /etc/apt/sources.list.d/ispras.list \
    && wget -q -O - https://repo.ispras.ru/apt/key.asc | apt-key add - \
    && apt update -y \
    && apt install -y aksusbd
COPY docker/setup_license.sh /opt/setup_license.sh
RUN echo "/opt/setup_license.sh 101213 36343" >> ~/.bashrc
