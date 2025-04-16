FROM ubuntu:22.04

RUN apt update \
    && apt upgrade -y \
    && apt install -y wget libffi-dev liblz4-dev libcurl4-openssl-dev gnupg2 git python3 python3-pip python3-dev \
       gcc gcc-multilib g++ g++-multilib clang nano

RUN cd /tmp && wget http://archive.ubuntu.com/ubuntu/pool/main/libf/libffi/libffi6_3.2.1-8_amd64.deb && dpkg -i libffi6_3.2.1-8_amd64.deb && rm -rf libffi6_3.2.1-8_amd64.deb

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
