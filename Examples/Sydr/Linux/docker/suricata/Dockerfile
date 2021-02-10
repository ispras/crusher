FROM ubuntu:20.04

MAINTAINER Andrey Fedotov

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get -y install  zip  sqlite3 hexdiff libtool git libpcre3 libpcre3-dbg libpcre3-dev build-essential libpcap-dev libyaml-0-2 libyaml-dev pkg-config zlib1g zlib1g-dev  make libmagic-dev  libjansson-dev rustc cargo libtiff-dev cmake

RUN cargo install --force cbindgen

ENV PATH="/root/.cargo/bin:${PATH}"

RUN mkdir -p labs/suricata

RUN cd /labs/suricata && \
    git clone https://github.com/OISF/suricata.git && \
    git clone https://github.com/OISF/suricata-verify && \
    cd ./suricata && \
    git clone  https://github.com/OISF/libhtp.git libhtp
RUN cd /labs/suricata/suricata && \
    git checkout 62e665c8482c90b30f6edfa7b0f0eabf8a4fcc79 && \
    cd /labs/suricata/suricata/libhtp && \
    git checkout 49ca281eda41d72cd57f79a4d908183c8f11944e && \
    cd /labs/suricata/suricata-verify && \
    git checkout affd7d58c2c6d36088a088f02753b18153af04dd
RUN cd /labs/suricata/suricata && \
    ./autogen.sh && \
    ./configure --enable-fuzztargets  --disable-shared && \
    make -j4

ENV PATH="/suricata-sydr/crusher/bin_x86-64/sydr:${PATH}"
