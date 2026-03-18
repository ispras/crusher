#!/bin/bash

if [ -z "$HASP_IP" ]; then
    echo "hasp ip - not set"
    hasplmd -s
    exit 0
fi

echo "hasp ip - $HASP_IP"

mkdir -p /root/.hasplm
for vendor_id in "$@"; do
    hasp_ini_file=/root/.hasplm/hasp_${vendor_id}.ini

    if [ ! -f "$hasp_ini_file" ] || ! grep -q '^serveraddr = ' "$hasp_ini_file"; then
        echo "[REMOTE]" >> $hasp_ini_file
        echo "serveraddr = $HASP_IP" >> $hasp_ini_file
        echo "set hasp addr: serveraddr = $HASP_IP"
    else
        echo "already set hasp addr: serveraddr = $HASP_IP"
    fi
done

hasplmd -s
