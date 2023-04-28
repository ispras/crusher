# Prebuild AFL++ compilers (v4.04c)

В директории `AFLplusplus-4.04c_prebuild` находятся собранные на ОС `Centos 6.10` компиляторы AFL++.

## Установка зависимостей

```
sudo apt update
sudo apt install -y build-essential llvm-12 lld
```

Для корректной работы компиляторов `afl-gcc-fast` и `afl-g++-fast` в системе должен быть установлен `gcc` версии 11.2.
Ниже приведены команды для установки данной версии `gcc` из исходного кода:

```
cd /tmp && curl -L -O https://ftp.gnu.org/gnu/gcc/gcc-11.2.0/gcc-11.2.0.tar.xz && \
	tar xf gcc-11.2.0.tar.xz && rm gcc-11.2.0.tar.xz && \
	cd gcc-11.2.0 && \
	contrib/download_prerequisites && \
	mkdir ../gcc-build && cd ../gcc-build && \
	../gcc-11.2.0/configure --prefix=/usr --enable-languages=c,c++ --enable-multilib && \
	make -j$(nproc) && make install && \
	cd .. && rm -rf gcc-11.2.0 gcc-build
```

Следующие команды предназначены для установки `llvm-12` из исходного кода (для тех случаев, когда в используемой вами ОС не поддерживается установка `llvm-12` из репозиториев):

```
sudo apt install -y cmake

cd /tmp && curl -L -O https://github.com/llvm/llvm-project/archive/refs/tags/llvmorg-12.0.0.tar.gz \
	&& tar xf llvmorg-12.0.0.tar.gz \
	&& cd llvm-project-llvmorg-12.0.0 && mkdir build && cd build \
	&& cmake ../llvm -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release -DLLVM_ENABLE_PROJECTS="clang;clang-tools-extra;compiler-rt;lld;libc++;libc++abi;libunwind" -DCLANG_INCLUDE_DOCS="OFF" -DLLVM_BINUTILS_INCDIR=/usr/include/ -DLLVM_BUILD_LLVM_DYLIB="ON" -DLLVM_ENABLE_BINDINGS="OFF" -DLLVM_ENABLE_WARNINGS="OFF" -DLLVM_INCLUDE_BENCHMARKS="OFF" -DLLVM_INCLUDE_DOCS="OFF" -DLLVM_INCLUDE_EXAMPLES="OFF" -DLLVM_INCLUDE_TESTS="OFF" -DLLVM_LINK_LLVM_DYLIB="ON" -DLLVM_TARGETS_TO_BUILD="host" -G "Unix Makefiles" \
	&& cmake --build . -j$(nproc) && cmake --install . \
	&& cd / \
	&& rm -rf /tmp/llvmorg-12.0.0.tar.gz /tmp/llvm-project-llvmorg-12.0.0
```

### Подготовка компиляторов к работе

```
export PATH="$PATH:/path/to/crusher/third_party/AFLplusplus-4.04c_prebuild"
```

Следующие команды укажут требующиеся для компиляции при помощи `AFL++` пакеты в качестве пакетов, вызываемых по умолчанию (подробнее: https://github.com/ispras/crusher/blob/master/FAQ/FAQ_1_afl%2B%2Bclang.md )

```
sudo su
update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-11 100 && \
	update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-11 100 && \
	update-alternatives --install /usr/bin/clang clang /usr/bin/clang-12 100 && \
	update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-12 100 && \
	update-alternatives --install /usr/bin/llvm-config llvm-config /usr/bin/llvm-config-12 100 && \
	update-alternatives --install /usr/bin/llvm-ar llvm-ar /usr/bin/llvm-ar-12 100 && \
	update-alternatives --install /usr/bin/llvm-nm llvm-nm /usr/bin/llvm-nm-12 100 && \
	update-alternatives --install /usr/bin/llvm-ranlib llvm-ranlib /usr/bin/llvm-ranlib-12 100 && \
	update-alternatives --install /usr/bin/llvm-link llvm-link /usr/bin/llvm-link-12 100 && \
	update-alternatives --install /usr/bin/llvm-objdump llvm-objdump /usr/bin/llvm-objdump-12 100 
exit
```
