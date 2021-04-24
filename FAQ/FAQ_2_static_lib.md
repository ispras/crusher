
Создаем каталог для исследования:

```root@d5a9215b758b:/home/crusher/AFLplusplus# cd .. && mkdir test && cd test```

Копируем в каталог наш модельный пример - библиотека pugixml, являющаяся легковесным парсером xml:

```root@d5a9215b758b:/home/crusher/test# git clone https://github.com/zeux/pugixml && cd pugixml && mkdir build && cd build```

Библиотека состоит из одного файла исходныйх текстов (С++) и двух заголовочных файлов, и не имеет зависимостей (не требует линковки) с другими библиотеками. Компилируем библиотеку одной командой, где -g - влкючение отладочной информации (символов) в объектный файл, -c - порождение объектного файла (а не готового исполняемого файла), -fsanitize=address,undefined - инструкция компиялятору добавить санитайзеры ASAN и UBSAN, -o - имя выходного файла, в данном случае объектного: 

```
root@d5a9215b758b:/home/crusher/test/pugixml/build# ../../../AFLplusplus/afl-clang-fast++ -g -fsanitize=address,undefined -c ../src/pugixml.cpp -o pugixml.o
afl-cc ++3.13a by Michal Zalewski, Laszlo Szekeres, Marc Heuse - mode: LLVM-PCGUARD
SanitizerCoveragePCGUARD++3.13a
Info: Found constructor function _GLOBAL__sub_I_pugixml.cpp with prio 65535, we will not instrument this, putting it into a block list.
[+] Instrumented 3679 locations with no collisions (non-hardened mode).
```

Пакуем наш объектный файл в статическую библиотеку. В данном случае это не принципиально - у нас всего один объектник. Но если бы их было много, то для уменьшения команды компиляции и упрощения работы компоновщика (см. отличную статью https://habr.com/ru/post/150327/), это было бы весьма полезно:

```
root@d5a9215b758b:/home/crusher/test/pugixml/build# ar rv libfuzz.a *.o
ar: creating libfuzz.a
a - pugixml.o
```

Можно проверить, что в объектный файл добавились вызовы функций адресного санитайзера:

```
 nm libfuzz.a | grep asan
```
 
Если скомпилировать без ASAN (-fsanitize=address), то asan-функций не будет.

Теперь создаём собственно фаззинг-обертку - файл исходных текстов wrapper.cpp, содержащий функцию main, в которой собственно и вызывается одна из функций нашей библиотеки, а именно парсер текстового файл в XML-представление:

```
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
```
 
Пробуем её скомпилировать "в лоб", указав только параметр -l (имя нашей статической библиотеки, см. интересную статью (https://www.rapidtables.com/code/linux/gcc/gcc-l.html), почему нужно писать -lfuzz, а не libfuzz.a) и получаем ошибку:

```
root@d5a9215b758b:/home/crusher/test/pugixml/build# ../../../AFLplusplus/afl-clang-fast++ -fsanitize=address,undefined wrapper.cpp  -lfuzz -o fuzzer -v

wrapper.cpp:1:10: fatal error: 'pugixml.hpp' file not found
#include "pugixml.hpp" #include <iostream> int main(int argc, char * argv[]) {     pugi::xml_document doc;     pugi::xml_parse_result result = doc.load_file(argv[1]);    if (!result)         return -1; }
         ^~~~~~~~~~~~~
1 warning and 1 error generated.
```

Очевидно мы забыли подсказать компилятору где искать заголовочные файла (напоминаю, в каталого src их две штуки). Добавляем ключ -I - путь к хидерам. И всё равно получаем ошибку, но уже другую:

```
root@d5a9215b758b:/home/crusher/test/pugixml/build# ../../../AFLplusplus/afl-clang-fast++ -fsanitize=address,undefined wrapper.cpp -I../src -lfuzz -o fuzzer -v

...
x86_64-linux-gnu/crtn.o
/usr/bin/ld: cannot find -lfuzz
clang: error: linker command failed with exit code 1 (use -v to see invocation)
```

Компилятор не может понять, где ему искать наш libfuzz.a. Поможем ему, указав каталог статических библиотек через ключ -L (опять таки см. https://www.rapidtables.com/code/linux/gcc/gcc-l.html) - а именно указав на **текущий** каталог:

```
root@d5a9215b758b:/home/crusher/test/pugixml/build# ../../../AFLplusplus/afl-clang-fast++ -fsanitize=address,undefined wrapper.cpp -I../src -L. -lfuzz -o fuzzer -v
```

**Бинго! Собралось!**

Ради теста запускаем фаззинг, всё работает:

```
mkdir in && echo 111 > in/sample
../../../AFLplusplus/afl-fuzz -i in -o out -- ./fuzzer @@
```

Важный момент - даже для такой простой библиотеки сборка lto-версией компилятора более выгодна (хотя и более затратна по времени). В частности, после сборки обычным fast-компилятором, мы имеем 6369 инструментированных позиции (без коллизий, но это потому, что у нас мало модулей трансляции, то есть нам повезло с конкретно данной библиотекой) и пости 5-ти Мегабайтный исполняемый файл:

```
root@d5a9215b758b:/home/crusher/test/pugixml/build# nm fuzzer | wc -l
6369

root@d5a9215b758b:/home/crusher/test/pugixml/build# stat fuzzer
  File: fuzzer
  Size: 4701176
```

При сборке же с помощью afl-clang-lto++ у нас существенно меньше инструментированных позиций, а также почти в 2,5 раза меньший исполняемый файл на выходе:

```
root@d5a9215b758b:/home/crusher/test/pugixml/build# nm fuzzer | wc -l
5551

root@d5a9215b758b:/home/crusher/test/pugixml/build# stat fuzzer
  File: fuzzer
  Size: 1945288
```
