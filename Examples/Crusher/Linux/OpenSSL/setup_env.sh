#!/bin/bash

sudo su
echo core >/proc/sys/kernel/core_pattern
exit
