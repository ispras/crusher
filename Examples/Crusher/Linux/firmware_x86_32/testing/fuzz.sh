if [[ "$#" -ne 1 ]]; then
    echo "Usage: ./fuzz.sh <path/to/fuzz_manager>"
    exit 1
fi

FUZZ_MAN=$1

$FUZZ_MAN --start 4 -i ../in -o out -F -I QemuX86 -T QemuIntegration --lua test.lua --lighthouse test.bin -- -m 4G

