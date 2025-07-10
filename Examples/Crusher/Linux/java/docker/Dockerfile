# Base image
FROM ubuntu:jammy

# Install deps
RUN apt update -y \
    && apt install -y libglib2.0-0 openjdk-17-jdk git maven nano gnupg2 wget sudo

# Setup env
ENV USER_NAME keycloak
RUN adduser --disabled-password $USER_NAME \
    && usermod -aG sudo $USER_NAME \
    && echo "$USER_NAME ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/$USER_NAME
USER $USER_NAME

ENV WORK_DIR /home/$USER_NAME
WORKDIR $WORK_DIR

# Install hasp-service (for license)
USER root
RUN echo 'deb https://repo.ispras.ru/apt /' | tee /etc/apt/sources.list.d/ispras.list \
    && wget -q -O - https://repo.ispras.ru/apt/key.asc | apt-key add - \
    && apt update -y \
    && apt install -y aksusbd

# Setup license
RUN mkdir -p /etc/hasplm
COPY license/hasplm.ini /etc/hasplm/hasplm.ini
USER $USER_NAME
COPY license $WORK_DIR/license
# check
USER root
RUN $WORK_DIR/license/license.sh && $WORK_DIR/license/test-protected

# Install Keycloak
USER $USER_NAME
RUN git clone https://github.com/keycloak/keycloak.git \
    && cd keycloak \
    && git checkout 26.0.7 \
    && mvn -pl quarkus/dist -am -DskipTests clean install \
    && cp quarkus/dist/target/keycloak-26.0.7.tar.gz .. \
    && cd .. \
    && tar xf keycloak-26.0.7.tar.gz

# Fuzz config
COPY config.json $WORK_DIR/config.json

USER root
