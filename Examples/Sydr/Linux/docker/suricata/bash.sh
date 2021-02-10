#!/bin/bash

docker run  -it -v `pwd`:/suricata-sydr \
  suricata-sydr /bin/bash
