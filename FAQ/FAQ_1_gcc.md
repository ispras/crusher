*Актуально 20.04.2021*

#### Особенности использования clang-компиляторов из комплекта AFL++ при статическом инструментировании

В режиме статического инструментирования Crusher 2.3.0+ поддерживает инструментацию стандартных компиляторов из состава AFL++. В релизах AFL++ основным компилятором является afl-cc - он вызываевается вне зависимости от того, какой именно конкретный компилятор выбирает аналитик (afl-gcc, afl-clang-fast++. afl-clang-lto - всё это теперь просто ссылки, обеспечивающие вызов afl-cc в определённом режиме). 

Для того, чтобы воспользоваться всеми наиболее актуальными возможностями afl-cc, следует иметь в системе установленные clang/llvm 11+ (рекомендуется текущая версия - 12). В ходе установки требуемой версии clang, сборки компиляторов AFL++ и настройки системы в целом могут возникать различные проблемы, советы по диагностике которых приведены ниже.

Запустим ```bash``` в прилагаемом контейнере, в котором по умолчанию установлен только ```gcc 9```:

```root@f08907929ba9:/home/crusher/AFLplusplus# make clean && make -j 4```

В выводе сборочного процесса AFL++ получим сообщение о том, что не удалось собрать LLVM-режим (-fast и -lto компиляторы - то есть самые актуальные и интересные):

```...
[+] Main compiler 'afl-cc' successfully built!
[-] LLVM mode for 'afl-cc'  failed to build, likely you either don't have llvm installed, or you need to set LLVM_CONFIG, to point to e.g. llvm-config-11. See instrumentation/README.llvm.md how to do this. Highly recommended!
[-] LLVM LTO mode for 'afl-cc'  failed to build, this would need LLVM 11+, see instrumentation/README.lto.md how to build it
...
```

Скачаем простой проект с github:

```root@f08907929ba9:/home/crusher# git clone https://github.com/donpsabance/simple-cpp-projects```

и попробуем собрать его clang-fast-компилятором (неплюсовым)


```root@f08907929ba9:/home/crusher/simple-cpp-projects# ../AFLplusplus/afl-clang-fast  bulls_cows.cpp -o binary```

и получим ошибку линковки, а также сообщение о том, что мы работаем в режиме GCC (не самый интересный режим)

```
afl-cc ++3.12c by Michal Zalewski, Laszlo Szekeres, Marc Heuse - mode: GCC-GCC
...
/usr/include/c++/9/iostream:74: undefined reference to `std::ios_base::Init::~Init()'
/usr/bin/ld: /tmp/ccsaofHR.o:(.data.rel.local.DW.ref.__gxx_personality_v0[DW.ref.__gxx_personality_v0]+0x0): undefined reference to `__gxx_personality_v0'
collect2: error: ld returned 1 exit status
```

Попробуем собрать его clang-fast++-компилятором (плюсовым) - сборка пройдёт успешно, но несмотря на clang-псевдоним, afl-cc на самом деле всё равно вызовет GCC-режим, поскольку clang-компилятор не установлен в системе.

```root@f08907929ba9:/home/crusher/simple-cpp-projects# ../AFLplusplus/afl-clang-fast++  bulls_cows.cpp -o binary
afl-cc ++3.12c by Michal Zalewski, Laszlo Szekeres, Marc Heuse - mode: GCC-GCC
[!] WARNING: You are using outdated instrumentation, install LLVM and/or gcc-plugin and use afl-clang-fast/afl-clang-lto/afl-gcc-fast instead!
afl-as++3.12c by Michal Zalewski
[+] Instrumented 345 locations (64-bit, non-hardened mode, ratio 100%).
```

Попробуем собрать его clang-lto++-компилятором (плюсовым) - **самым эффективным и правильным для фаззинга компилятором** - получим ошибку, такого компилятора вообще нет, он не собрался в ходе сборки AFL++. Для его сборки **необходимо наличие установленной LLVM-подсистемы**.

```
root@f08907929ba9:/home/crusher/simple-cpp-projects# ../AFLplusplus/afl-clang-lto++  bulls_cows.cpp -o binary
bash: ../AFLplusplus/afl-clang-lto++: No such file or directory
```

Поставим последние LLVM и clang автоматизированным скриптом, информация доступна в https://apt.llvm.org/

```root@f08907929ba9:/home/crusher/simple-cpp-projects# bash -c "$(wget -O - https://apt.llvm.org/llvm.sh)"```

Не получится, потребуется доставить рекомендованные пакеты. Потом повторяем установку.

```root@f08907929ba9:/home/crusher/simple-cpp-projects# sudo apt install lsb-release wget software-properties-common```

Всё отработает корректно, однако при попытке выполнить проверку наличия clang в системе по стандартному alias мы ничего не обнаружим:

```
root@f08907929ba9:/home/crusher/AFLplusplus# clang --version
bash: clang: command not found
root@f08907929ba9:/home/crusher/AFLplusplus# /usr/bin/cl
clang++-12     clang-12       clang-cpp-12   clangd-12      clear          clear_console
```

И сборка AFL++ снова не получится полноценной:

```
root@f08907929ba9:/home/crusher/AFLplusplus# cd ../AFLplusplus/ && make clean && make -j4
[+] All right, the instrumentation of afl-cc seems to be working!
[+] Main compiler 'afl-cc' successfully built!
[-] LLVM mode for 'afl-cc'  failed to build, likely you either don't have llvm installed, or you need to set LLVM_CONFIG, to point to e.g. llvm-config-11. See instrumentation/README.llvm.md how to do this. Highly recommended!
[-] LLVM LTO mode for 'afl-cc'  failed to build, this would need LLVM 11+, see instrumentation/README.lto.md how to build it
[-] gcc_plugin for 'afl-cc'  failed to build, unless you really need it that is fine - or read instrumentation/README.gcc_plugin.md how to build it
```

Решение проблемы - нужно прописать clang, clang++ и **важно** llvm-config в качестве пакетов, вызываемых по умолчанию, при вызове определенных префиксов. В ubuntu это делается с помощью ```update-alternatives```

```
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
```

Устанавливать все альтернативы при работе по небольшому простому проекту вам скорее всего не потребуется - **обычно бывает достаточно clang (и сс), clang++ (и с++) и llvm-config**!

Собираем AFL++ ещё раз - бинго! Всё самое вкусное собралось.

```
root@f08907929ba9:/home/crusher/AFLplusplus# make clean && make -j4

...
[+] All right, the instrumentation of afl-cc seems to be working!
[+] Main compiler 'afl-cc' successfully built!
[+] LLVM mode for 'afl-cc' successfully built!
[+] LLVM LTO mode for 'afl-cc' successfully built!
...
```
Не ленимся проверить и убедиться лично, что в качестве дефолтных используются именно те версии, которые мы и хотим видеть:

```
root@f08907929ba9:/home/crusher/simple-cpp-projects# clang --version
Ubuntu clang version 12.0.0-++20210418111008+fa0971b87fb2-1~exp1~20210418211725.74
Target: x86_64-pc-linux-gnu
Thread model: posix
InstalledDir: /usr/bin
root@f08907929ba9:/home/crusher/simple-cpp-projects# llvm-config --version
12.0.0
```

Пробуем и успешно собираем простой проект уже в LLVM-режиме (обратите внимание на **LLVM-PCGUARD**):

```
root@f08907929ba9:/home/crusher/simple-cpp-projects# ../AFLplusplus/afl-clang-fast++ bulls_cows.cpp -o binary
afl-cc ++3.12c by Michal Zalewski, Laszlo Szekeres, Marc Heuse - mode: LLVM-PCGUARD
SanitizerCoveragePCGUARD++3.12c
Info: Found constructor function _GLOBAL__sub_I_bulls_cows.cpp with prio 65535, we will not instrument this, putting it into a block list.
[+] Instrumented 33 locations with no collisions (non-hardened mode).
```

Однако иногда вследствие комплекса различных действий с компиляторами в системе может что-то слететь. Как пример - кто-то поставил g++-компилятор для вызова при вызове clang++ (скорее всего это чья-то ошибка, а не злой умысел...). Проблему можно увидеть посмотрев на вывод команды --version - вроде бы clang, но версия gcc'шная указана. 

```root@f08907929ba9:/home/crusher/simple-cpp-projects# update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/g++-9 110
update-alternatives: using /usr/bin/g++-9 to provide /usr/bin/clang++ (clang++) in auto mode
root@f08907929ba9:/home/crusher/simple-cpp-projects# clang++ --version
clang++ (Ubuntu 9.3.0-17ubuntu1~20.04) 9.3.0
Copyright (C) 2019 Free Software Foundation, Inc.
This is free software; see the source for copying conditions.  There is NO
warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
```

При таких странных конфигурациях afl-cc компилятор, который вызывает нативный компилятор, дополняя его действия комплексом собственных пассов / инструментаций / вставок, может сойти с ума.

Поэтому при возникновении проблем со сборкой рекомендуется использовать режим AFL_DEBUG=1 и убедиться, что вызывается именно тот реальный компилятор, который мы бы и хотели видеть, а не что-то неожиданное:

```root@f08907929ba9:/home/crusher/simple-cpp-projects#``` **AFL_DEBUG=1 ../AFLplusplus/afl-cc bulls_cows.cpp -o binary**

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
[D] DEBUG: cd '/home/crusher/simple-cpp-projects'; 
**'/usr/lib/llvm-12/bin/clang'** 
'-Wno-unused-command-line-argument' '-Xclang' '-load' '-Xclang' '../AFLplusplus/SanitizerCoveragePCGUARD.so' 'bulls_cows.cpp' '-o' 'binary' '-g' '-O3' '-funroll-loops' '-D__AFL_HAVE_MANUAL_CONTROL=1' '-D__AFL_COMPILER=1' '-DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION=1' '-D__AFL_FUZZ_INIT()=int 

