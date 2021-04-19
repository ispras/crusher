#### Описание

crusher@crusherU20VM:/var/work/exp_instr/inst$ docker build --build-arg cuid=$(id -u) --build-arg cgid=$(id -g) --build-arg cuidname=$(id -un) --build-arg cgidname=$(id -gn) -t gcc_bad -f Dockerfile_gcc_bad.txt .

crusher@crusherU20VM:/var/work/exp_instr/inst$ docker run -it --name=gcc_bad gcc_bad /bin/bash

root@f08907929ba9:/home/crusher/AFLplusplus# make clean

[+] Main compiler 'afl-cc' successfully built!
[-] LLVM mode for 'afl-cc'  failed to build, likely you either don't have llvm installed, or you need to set LLVM_CONFIG, to point to e.g. llvm-config-11. See instrumentation/README.llvm.md how to do this. Highly recommended!
[-] LLVM LTO mode for 'afl-cc'  failed to build, this would need LLVM 11+, see instrumentation/README.lto.md how to build it

root@f08907929ba9:/home/crusher# git clone https://github.com/donpsabance/simple-cpp-projects

root@f08907929ba9:/home/crusher/simple-cpp-projects# ../AFLplusplus/afl-clang-fast  bulls_cows.cpp -o binary
afl-cc ++3.12c by Michal Zalewski, Laszlo Szekeres, Marc Heuse - mode: GCC-GCC
...
/usr/include/c++/9/iostream:74: undefined reference to `std::ios_base::Init::~Init()'
/usr/bin/ld: /tmp/ccsaofHR.o:(.data.rel.local.DW.ref.__gxx_personality_v0[DW.ref.__gxx_personality_v0]+0x0): undefined reference to `__gxx_personality_v0'
collect2: error: ld returned 1 exit status


root@f08907929ba9:/home/crusher/simple-cpp-projects# ../AFLplusplus/afl-clang-fast++  bulls_cows.cpp -o binary
afl-cc ++3.12c by Michal Zalewski, Laszlo Szekeres, Marc Heuse - mode: GCC-GCC
[!] WARNING: You are using outdated instrumentation, install LLVM and/or gcc-plugin and use afl-clang-fast/afl-clang-lto/afl-gcc-fast instead!
afl-as++3.12c by Michal Zalewski
[+] Instrumented 345 locations (64-bit, non-hardened mode, ratio 100%).

root@f08907929ba9:/home/crusher/simple-cpp-projects# ../AFLplusplus/afl-clang-lto++  bulls_cows.cpp -o binary
bash: ../AFLplusplus/afl-clang-lto++: No such file or directory


https://apt.llvm.org/

root@f08907929ba9:/home/crusher/simple-cpp-projects# bash -c "$(wget -O - https://apt.llvm.org/llvm.sh)"

root@f08907929ba9:/home/crusher/simple-cpp-projects# sudo apt install lsb-release wget software-properties-common




root@f08907929ba9:/home/crusher/AFLplusplus# cd ../AFLplusplus/ && make clean

root@f08907929ba9:/home/crusher/AFLplusplus# clang --version
bash: clang: command not found
root@f08907929ba9:/home/crusher/AFLplusplus# /usr/bin/cl
clang++-12     clang-12       clang-cpp-12   clangd-12      clear          clear_console


[+] All right, the instrumentation of afl-cc seems to be working!
[+] Main compiler 'afl-cc' successfully built!
[-] LLVM mode for 'afl-cc'  failed to build, likely you either don't have llvm installed, or you need to set LLVM_CONFIG, to point to e.g. llvm-config-11. See instrumentation/README.llvm.md how to do this. Highly recommended!
[-] LLVM LTO mode for 'afl-cc'  failed to build, this would need LLVM 11+, see instrumentation/README.lto.md how to build it
[-] gcc_plugin for 'afl-cc'  failed to build, unless you really need it that is fine - or read instrumentation/README.gcc_plugin.md how to build it



update-alternatives --install /usr/bin/clang clang /usr/bin/clang-12 100 && \
update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-12 100 && \
update-alternatives --install /usr/bin/c++ c++ /usr/bin/clang++-12 100 && \
update-alternatives --install /usr/bin/cc cc /usr/bin/clang-12 100 && \
update-alternatives --install /usr/bin/llvm-config llvm-config /usr/bin/llvm-config-12 100 && \
update-alternatives --install /usr/bin/llvm-ar llvm-ar /usr/bin/llvm-ar-12 100 && \
update-alternatives --install /usr/bin/llvm-nm llvm-nm /usr/bin/llvm-nm-12 100 && \
update-alternatives --install /usr/bin/llvm-ranlib llvm-ranlib /usr/bin/llvm-ranlib-12 100 && \
update-alternatives --install /usr/bin/llvm-link llvm-link /usr/bin/llvm-link-12 100 && \
update-alternatives --install /usr/bin/llvm-objdump llvm-objdump /usr/bin/llvm-objdump-12 100

root@f08907929ba9:/home/crusher/AFLplusplus# update-alternatives --install /usr/bin/clang clang /usr/bin/clang-12 100 && \
> update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-12 100 && \
> update-alternatives --install /usr/bin/c++ c++ /usr/bin/clang++-12 100 && \
> update-alternatives --install /usr/bin/cc cc /usr/bin/clang-12 100 && \
> update-alternatives --install /usr/bin/llvm-config llvm-config /usr/bin/llvm-config-12 100 && \
> update-alternatives --install /usr/bin/llvm-ar llvm-ar /usr/bin/llvm-ar-12 100 && \
> update-alternatives --install /usr/bin/llvm-nm llvm-nm /usr/bin/llvm-nm-12 100 && \
> update-alternatives --install /usr/bin/llvm-ranlib llvm-ranlib /usr/bin/llvm-ranlib-12 100 && \
> update-alternatives --install /usr/bin/llvm-link llvm-link /usr/bin/llvm-link-12 100 && \
> update-alternatives --install /usr/bin/llvm-objdump llvm-objdump /usr/bin/llvm-objdump-12 100
update-alternatives: using /usr/bin/clang-12 to provide /usr/bin/clang (clang) in auto mode
update-alternatives: using /usr/bin/clang++-12 to provide /usr/bin/clang++ (clang++) in auto mode
update-alternatives: using /usr/bin/clang++-12 to provide /usr/bin/c++ (c++) in auto mode
update-alternatives: using /usr/bin/clang-12 to provide /usr/bin/cc (cc) in auto mode
update-alternatives: using /usr/bin/llvm-config-12 to provide /usr/bin/llvm-config (llvm-config) in auto mode
update-alternatives: using /usr/bin/llvm-ar-12 to provide /usr/bin/llvm-ar (llvm-ar) in auto mode
update-alternatives: using /usr/bin/llvm-nm-12 to provide /usr/bin/llvm-nm (llvm-nm) in auto mode
update-alternatives: using /usr/bin/llvm-ranlib-12 to provide /usr/bin/llvm-ranlib (llvm-ranlib) in auto mode
update-alternatives: using /usr/bin/llvm-link-12 to provide /usr/bin/llvm-link (llvm-link) in auto mode
update-alternatives: using /usr/bin/llvm-objdump-12 to provide /usr/bin/llvm-objdump (llvm-objdump) in auto mode


root@f08907929ba9:/home/crusher/AFLplusplus# make clean && make -j4

...
[+] All right, the instrumentation of afl-cc seems to be working!
[+] Main compiler 'afl-cc' successfully built!
[+] LLVM mode for 'afl-cc' successfully built!
[+] LLVM LTO mode for 'afl-cc' successfully built!
...


root@f08907929ba9:/home/crusher/simple-cpp-projects# clang --version
Ubuntu clang version 12.0.0-++20210418111008+fa0971b87fb2-1~exp1~20210418211725.74
Target: x86_64-pc-linux-gnu
Thread model: posix
InstalledDir: /usr/bin
root@f08907929ba9:/home/crusher/simple-cpp-projects# llvm-config --version
12.0.0


root@f08907929ba9:/home/crusher/simple-cpp-projects# ../AFLplusplus/afl-clang-fast++ bulls_cows.cpp -o binary
afl-cc ++3.12c by Michal Zalewski, Laszlo Szekeres, Marc Heuse - mode: LLVM-PCGUARD
SanitizerCoveragePCGUARD++3.12c
Info: Found constructor function _GLOBAL__sub_I_bulls_cows.cpp with prio 65535, we will not instrument this, putting it into a block list.
[+] Instrumented 33 locations with no collisions (non-hardened mode).



root@f08907929ba9:/home/crusher/simple-cpp-projects# c++ --version
Ubuntu clang version 12.0.0-++20210418111008+fa0971b87fb2-1~exp1~20210418211725.74
Target: x86_64-pc-linux-gnu
Thread model: posix
InstalledDir: /usr/bin




root@f08907929ba9:/home/crusher/simple-cpp-projects# update-alternatives --install /usr/bin/c++ c++ /usr/bin/g++ 110
update-alternatives: using /usr/bin/g++ to provide /usr/bin/c++ (c++) in auto mode

root@f08907929ba9:/home/crusher/simple-cpp-projects# c++ --version
c++ (Ubuntu 9.3.0-17ubuntu1~20.04) 9.3.0
Copyright (C) 2019 Free Software Foundation, Inc.
This is free software; see the source for copying conditions.  There is NO
warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.


root@f08907929ba9:/home/crusher/simple-cpp-projects# update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/g++-9 110
update-alternatives: using /usr/bin/g++-9 to provide /usr/bin/clang++ (clang++) in auto mode
root@f08907929ba9:/home/crusher/simple-cpp-projects# clang++ --version
clang++ (Ubuntu 9.3.0-17ubuntu1~20.04) 9.3.0
Copyright (C) 2019 Free Software Foundation, Inc.
This is free software; see the source for copying conditions.  There is NO
warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.



root@f08907929ba9:/home/crusher/simple-cpp-projects# AFL_DEBUG=1 ../AFLplusplus/afl-cc bulls_cows.cpp -o binary
[D] DEBUG: Trying ../AFLplusplus/as
[D] DEBUG: Trying ../AFLplusplus/SanitizerCoverageLTO.so
[D] DEBUG: Trying ../AFLplusplus/cmplog-routines-pass.so
[D] DEBUG: Trying ../AFLplusplus/afl-gcc-pass.so
[D] DEBUG: Trying ../AFLplusplus/../lib/afl/afl-gcc-pass.so
[D] DEBUG: Trying /usr/local/lib/afl/afl-gcc-pass.so
[D] DEBUG: Trying ./afl-gcc-pass.so
[D] DEBUG: Trying ... giving up
afl-cc ++3.12c by Michal Zalewski, Laszlo Szekeres, Marc Heuse - mode: LLVM-PCGUARD
[D] DEBUG: cd '/home/crusher/simple-cpp-projects'; '../AFLplusplus/afl-cc' 'bulls_cows.cpp' '-o' 'binary'
[D] DEBUG: Trying ../AFLplusplus/afl-compiler-rt.o
[D] DEBUG: rt=../AFLplusplus/afl-compiler-rt.o obj_path=../AFLplusplus
[D] DEBUG: cd '/home/crusher/simple-cpp-projects'; '/usr/lib/llvm-12/bin/clang' '-Wno-unused-command-line-argument' '-Xclang' '-load' '-Xclang' '../AFLplusplus/SanitizerCoveragePCGUARD.so' 'bulls_cows.cpp' '-o' 'binary' '-g' '-O3' '-funroll-loops' '-D__AFL_HAVE_MANUAL_CONTROL=1' '-D__AFL_COMPILER=1' '-DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION=1' '-D__AFL_FUZZ_INIT()=int __afl_sharedmem_fuzzing = 1;extern unsigned int *__afl_fuzz_len;extern unsigned char *__afl_fuzz_ptr;unsigned char __afl_fuzz_alt[1048576];unsigned char *__afl_fuzz_al
