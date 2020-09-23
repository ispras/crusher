if [[ "$#" -ne 1 ]]; then
    echo "Usage: ./startFuzz.sh <path/to/crusher/bin_x86-64/fuzz_manager>"
    exit 1
fi

FUZZER=$1

rm -rf out
${FUZZER} --start 1 -i ../in -o out -I QemuArm -T QemuIntegration --lua emulateSTM.lua --save-crash-report -- -m 4G -kernel ./main.bin
