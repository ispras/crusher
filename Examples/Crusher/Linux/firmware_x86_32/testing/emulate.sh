if [[ "$#" -ne 1 ]]; then
    echo "Usage: ./emulate.sh <path/to/qemu>"
    exit 1
fi

QEMU=$1

# these files are required for qemu run
HW="$(dirname $QEMU)/hw"
cp -r $HW .

${QEMU} -M luax86 -nographic -lua test.lua --fuzzer-config config.json -m 4G -S -s -print-exception
