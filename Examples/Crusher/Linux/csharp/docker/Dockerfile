FROM ubuntu:22.04

RUN apt update \
    && apt upgrade -y \
    && apt install -y wget libffi-dev liblz4-dev libcurl4-openssl-dev gnupg2 git \
       gcc gcc-multilib g++ g++-multilib clang nano

RUN cd /tmp && wget http://archive.ubuntu.com/ubuntu/pool/main/libf/libffi/libffi6_3.2.1-8_amd64.deb && dpkg -i libffi6_3.2.1-8_amd64.deb && rm -rf libffi6_3.2.1-8_amd64.deb

# .NET 6 installing
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        dotnet-sdk-6.0 \
        aspnetcore-runtime-6.0

# Set Timezone or get hang during the docker build...
ENV TZ=Europe/Moscow
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Setup license
RUN echo 'deb https://repo.ispras.ru/apt /' | tee /etc/apt/sources.list.d/ispras.list \
    && wget -q -O - https://repo.ispras.ru/apt/key.asc | apt-key add - \
    && apt update -y \
    && apt install -y aksusbd
COPY setup_license.sh /opt/setup_license.sh
RUN echo "/opt/setup_license.sh 101213 36343" >> ~/.bashrc