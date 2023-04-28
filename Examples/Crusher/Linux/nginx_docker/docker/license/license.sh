#!/bin/bash

/usr/sbin/hasplmd -s

echo core >/proc/sys/kernel/core_pattern
