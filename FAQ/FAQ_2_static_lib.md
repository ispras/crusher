
Создаем каталог для исследования

```root@d5a9215b758b:/home/crusher/AFLplusplus# cd .. && mkdir test && cd test```

root@d5a9215b758b:/home/crusher/test# git clone https://github.com/zeux/pugixml && cd pugixml && mkdir build && cd build

root@d5a9215b758b:/home/crusher/test/pugixml/build# ../../../AFLplusplus/afl-clang-fast++ -g -fsanitize=address,undefined -c ../src/pugixml.cpp -o pugixml.o
afl-cc ++3.13a by Michal Zalewski, Laszlo Szekeres, Marc Heuse - mode: LLVM-PCGUARD
SanitizerCoveragePCGUARD++3.13a
Info: Found constructor function _GLOBAL__sub_I_pugixml.cpp with prio 65535, we will not instrument this, putting it into a block list.
[+] Instrumented 3679 locations with no collisions (non-hardened mode).

cat << EOT >> wrapper.cpp
#include "pugixml.hpp" 
#include <iostream> 
int main(int argc, char * argv[]) 
{ 
    pugi::xml_document doc; 
    pugi::xml_parse_result result = doc.load_file(argv[1]); 
    if (!result) 
        return -1; 
}
EOT

root@d5a9215b758b:/home/crusher/test/pugixml/build# ar rv libfuzz.a *.o
ar: creating libfuzz.a
a - pugixml.o

 nm libfuzz.a | grep asan
 
 Если нет ASAN, то нет asan...
 
root@d5a9215b758b:/home/crusher/test/pugixml/build# ../../../AFLplusplus/afl-clang-fast++ -fsanitize=address,undefined wrapper.cpp  -lfuzz -o fuzzer -v

wrapper.cpp:1:10: fatal error: 'pugixml.hpp' file not found
#include "pugixml.hpp" #include <iostream> int main(int argc, char * argv[]) {     pugi::xml_document doc;     pugi::xml_parse_result result = doc.load_file(argv[1]);    if (!result)         return -1; }
         ^~~~~~~~~~~~~
1 warning and 1 error generated.



root@d5a9215b758b:/home/crusher/test/pugixml/build# ../../../AFLplusplus/afl-clang-fast++ -fsanitize=address,undefined wrapper.cpp -I../src -lfuzz -o fuzzer -v


...
x86_64-linux-gnu/crtn.o
/usr/bin/ld: cannot find -lfuzz
clang: error: linker command failed with exit code 1 (use -v to see invocation)


root@d5a9215b758b:/home/crusher/test/pugixml/build# ../../../AFLplusplus/afl-clang-fast++ -fsanitize=address,undefined wrapper.cpp -I../src -L. -lfuzz -o fuzzer -v

Собралось!

mkdir in && echo 111 > in/sample

../../../AFLplusplus/afl-fuzz -i in -o out -- ./fuzzer @@

|run time : 0 days, 0 hrs, 0 min, 15 sec                 
...
│ total execs : 33.0k                
│  exec speed : 2171/sec              

../../../AFLplusplus/afl-clang-lto++ -g -fsanitize=undefined -c ../src/pugixml.cpp -o pugixml.o && ar rv libfuzz.a *.o

root@d5a9215b758b:/home/crusher/test/pugixml/build# ../../../AFLplusplus/afl-clang-lto++ -fsanitize=address,undefined wrapper.cpp -I../src -L. -lfuzz -o fuzzer -v




root@d5a9215b758b:/home/crusher/test/pugixml/build# nm fuzzer | wc -l
6369

root@d5a9215b758b:/home/crusher/test/pugixml/build# stat fuzzer
  File: fuzzer
  Size: 4701176


root@d5a9215b758b:/home/crusher/test/pugixml/build# nm fuzzer | wc -l
5551

root@d5a9215b758b:/home/crusher/test/pugixml/build# stat fuzzer
  File: fuzzer
  Size: 1945288

