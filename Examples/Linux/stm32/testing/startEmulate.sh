if [[ "$#" -ne 1 ]]; then
    echo "Usage: ./startEmulate.sh <path/to/qemu-system-arm>"
    exit 1
fi

QEMU=$1

${QEMU} -M luaarm -nographic -lua emulateSTM.lua --fuzzer-config config.json -m 4G -S -s -print-exception
