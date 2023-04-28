#!/bin/bash

wget -O license/aksusbd_8.52-1_amd64.deb https://repo.ispras.ru/apt/tools/sentinel/aksusbd_8.52-1_amd64.deb
docker build --network host -f Dockerfile . -t nginx-demo
