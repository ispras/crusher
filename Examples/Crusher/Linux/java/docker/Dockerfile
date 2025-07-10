# Base image
FROM ubuntu:jammy

# Setup env
ENV WORK_DIR /root/fuzz
RUN mkdir $WORK_DIR
WORKDIR $WORK_DIR

# Install deps
RUN apt update -y \
    && apt install -y libglib2.0-0 openjdk-17-jdk git maven nano gnupg2 wget

# Install Keycloak
RUN git clone https://github.com/keycloak/keycloak.git \
    && cd keycloak \
    && git checkout 26.0.7 \
    && mvn -pl quarkus/dist -am -DskipTests clean install \
    && cp quarkus/dist/target/keycloak-26.0.7.tar.gz .. \
    && cd .. \
    && tar xf keycloak-26.0.7.tar.gz

# Install hasp-service (for license)
RUN echo 'deb https://repo.ispras.ru/apt /' | tee /etc/apt/sources.list.d/ispras.list \
    && wget -q -O - https://repo.ispras.ru/apt/key.asc | apt-key add - \
    && apt update -y \
    && apt install -y aksusbd

# Setup license
COPY license $WORK_DIR/license
RUN mkdir -p /etc/hasplm
RUN cp $WORK_DIR/license/hasplm.ini /etc/hasplm/hasplm.ini
# check
RUN $WORK_DIR/license/license.sh && $WORK_DIR/license/test-protected

# Fuzz config
COPY config.json $WORK_DIR/config.json
