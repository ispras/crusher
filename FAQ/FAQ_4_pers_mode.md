*Актуально 20.09.2021 на версиях ПО, зафиксированных в Dockerfile*

Этот кейс описан по опыту решения на экзамене на курсах по фаззингу задачи, посвященной организации фаззинга С/С++-кода в режиме persistence_mode. Решить задачу для встраивания врезки в библиотеку pugixml навскидку не удалось, что ещё хуже - я осознал  нехватку собственных знаний для понимания процессов, приводяших к ошибке, и отсутствие доступной мне методологии отладки, на которую можно было бы опереться. Описание кейса вряд ли будет интересно честным "сишникам-синьорам" и прочим "компиляторщикам уровня Бог", но может пригодиться среднему инженеру с managed-бэкграундом, которого руководство решило быстро переквалифицировать в фаззингиста. Постарался зафиксировать всё происходившее, в том собственные ошибочные действия.

Выражаю благодарность в адрес коллег из Ideco и Марка Коренберга (@socketpair) лично, за помощь в разборе причин и решении данного кейса!

### Перед чтением настоятельно рекомендую ознакомиться со следующимим информационными ресурсами:

1. Руководство новичка по эксплуатации компоновщика (https://habr.com/ru/post/150327/) - читается легко и увлекательно.
2. Утилита перечисления символов ELF-файла nm  (https://linux.die.net/man/1/nm)
3. Режимы PERSISTENCE_MODE (далее для краткости - PM) и DEFERRED_MODE в фаззерах семейства AFL (https://github.com/AFLplusplus/AFLplusplus/blob/stable/instrumentation/README.persistent_mode.md)

### Поехали!

Запускаем контейнер, открываем единственный файл исходных текстов pigixml.cpp, выбираем произвольную функцию и встраиваем в неё PM-цикл. Для данного эксперимента нам не не важна конкретная бизнес-логика - и будет ли вообще функция обрабатывать наши данные - главное организовать подачу в неё смутированных фаззером данных в PM-парадигме.

```
//Запускаем vim-редактор сразу с номерами строк, для удобства
root@fuzzing:/home/user/pugixml/src# vim -c 'set nu' pugixml.cpp
```

Пробуем встроить PM-цикл например в функцию на строке 1972 - ```PUGI__FN xml_encoding guess_buffer_encoding(const uint8_t* data, size_t size)```. Значение параметра size заменяем на каждой итерации на значение, равное длине байт, смутированной фаззером. Собственно смутированные данные помещаем по указателю fuzzed_data, поскольку указатель на приходящие в функцию данные изначально объявлен как const, а менять прототип функции в наши цели не входит. Код будет выглядеть например вот так ():

```
 1972         PUGI__FN xml_encoding guess_buffer_encoding(const uint8_t* data, size_t size)
 1973         {
 1974                 __AFL_INIT();
 1975                 unsigned char *fuzzed_data = __AFL_FUZZ_TESTCASE_BUF;
 1976
 1977                 while (__AFL_LOOP(10000)) {
 1978                 	int len = __AFL_FUZZ_TESTCASE_LEN;
 1979                 	size = len;
 1980
 1981
 1982                 	// skip encoding autodetection if input buffer is too small
 1983                 	if (size < 4) return encoding_utf8;
 1984
 1985                 	uint8_t d0 = fuzzed_data[0], d1 = fuzzed_data[1], d2 = fuzzed_data[2], d3 = fuzzed_data[3];
 1986
 ................
 2007
 2008                 	if (d0 == 0x3c && d1 == 0x3f && d2 == 0x78 && d3 == 0x6d && parse_declaration_encoding(fuzzed_data, size, enc, enc_length))
 2009                 	{
 ................
 2024
 2025                 		return encoding_utf8;
 2026                 	}
 2027                 } 
 2028         }
```

Важный момент - макрос ```__AFL_INIT()```, отвечающий за переноску точки форка с последней инструкции перед функцией ```main()``` в начало данной функции, не обязателен. Я добавил его просто для демонстрации полного комплекта "возможностей".

Пробуем скомпилировать pugi в объектный файл, содержащий цели (одну функцию), которые мы впоследствии будем фаззить.

```
root@fuzzing:/home/user/pugixml/src# ../../AFLplusplus/afl-clang-lto++ -g3 -O0 -c pugixml.cpp -o pugixml.o
```

Вывод компилятора говорит о том, что символы, составляющие на самом деле наши макросы, не найдены (компоновщик не может их найти в доступных ему объектных файлах/библиотеках). 

```
afl-cc ++3.14c by Michal Zalewski, Laszlo Szekeres, Marc Heuse - mode: LLVM-LTO-PCGUARD
pugixml.cpp:1975:32: error: use of undeclared identifier '__afl_fuzz_ptr'
                unsigned char *fuzzed_data = __AFL_FUZZ_TESTCASE_BUF;
                                             ^
<command line>:11:34: note: expanded from here
#define __AFL_FUZZ_TESTCASE_BUF (__afl_fuzz_ptr ? __afl_fuzz_ptr : __afl_fuzz_alt_ptr)
                                 ^
pugixml.cpp:1975:32: error: use of undeclared identifier '__afl_fuzz_ptr'
<command line>:11:51: note: expanded from here
#define __AFL_FUZZ_TESTCASE_BUF (__afl_fuzz_ptr ? __afl_fuzz_ptr : __afl_fuzz_alt_ptr)
                                                  ^
pugixml.cpp:1975:32: error: use of undeclared identifier '__afl_fuzz_alt_ptr'
<command line>:11:68: note: expanded from here
#define __AFL_FUZZ_TESTCASE_BUF (__afl_fuzz_ptr ? __afl_fuzz_ptr : __afl_fuzz_alt_ptr)
                                                                   ^
pugixml.cpp:1978:13: error: use of undeclared identifier '__afl_fuzz_ptr'
                int len = __AFL_FUZZ_TESTCASE_LEN;
```

Кстати, а откуда у нас взялись эти макросы? Мы вроде бы их не объявляли... Запустим сборку с ключом -v (вывод полной информации о процессе компиляции/линковки).

```
root@fuzzing:/home/user/pugixml/src# ../../AFLplusplus/afl-clang-lto++ -g3 -O0 -c pugixml.cpp -o pugixml.o -v
```

Обратите внимание на ключ -D - этим ключем в препроцессор компилятора можно подать макросы непосредственно в командной строке компилятора (объявить макросы в модуле трансляции, поданном в компилятор), что собственно здесь и происходит.   

```
afl-cc ++3.14c by Michal Zalewski, Laszlo Szekeres, Marc Heuse - mode: LLVM-LTO-PCGUARD
Ubuntu clang version 12.0.1-++20210918042559+fed41342a82f-1~exp1~20210918143325.135
Target: x86_64-pc-linux-gnu
Thread model: posix
InstalledDir: /usr/lib/llvm-12/bin
Found candidate GCC installation: /usr/lib/gcc/x86_64-linux-gnu/9
Selected GCC installation: /usr/lib/gcc/x86_64-linux-gnu/9
Candidate multilib: .;@m64
Selected multilib: .;@m64
 (in-process)
 "/usr/lib/llvm-12/bin/clang" -cc1 -triple x86_64-pc-linux-gnu -emit-llvm-bc -flto=full -flto-unit -disable-free -disable-llvm-verifier -discard-value-names -main-file-name pugixml.cpp -mrelocation-model pic -pic-level 2 -fhalf-no-semantic-interposition -mframe-pointer=all -fmath-errno -fno-rounding-math -mconstructor-aliases -munwind-tables -target-cpu x86-64 -tune-cpu generic -fno-split-dwarf-inlining -debug-info-kind=limited -dwarf-version=4 -debugger-tuning=gdb -v -resource-dir /usr/lib/llvm-12/lib/clang/12.0.1 -D __AFL_HAVE_MANUAL_CONTROL=1 -D __AFL_COMPILER=1 -D FUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION=1 -D "__AFL_FUZZ_INIT()=int __afl_sharedmem_fuzzing = 1;extern unsigned int *__afl_fuzz_len;extern unsigned char *__afl_fuzz_ptr;unsigned char __afl_fuzz_alt[1048576];unsigned char *__afl_fuzz_alt_ptr = __afl_fuzz_alt;" -D "__AFL_COVERAGE()=int __afl_selective_coverage = 1;extern \"C\" void __afl_coverage_discard();extern \"C\" void __afl_coverage_skip();extern \"C\" void __afl_coverage_on();extern \"C\" void __afl_coverage_off();" -D "__AFL_COVERAGE_START_OFF()=int __afl_selective_coverage_start_off = 1;" -D __AFL_COVERAGE_ON()=__afl_coverage_on() -D __AFL_COVERAGE_OFF()=__afl_coverage_off() -D __AFL_COVERAGE_DISCARD()=__afl_coverage_discard() -D __AFL_COVERAGE_SKIP()=__afl_coverage_skip() -D "__AFL_FUZZ_TESTCASE_BUF=(__afl_fuzz_ptr ? __afl_fuzz_ptr : __afl_fuzz_alt_ptr)" -D "__AFL_FUZZ_TESTCASE_LEN=(__afl_fuzz_ptr ? *__afl_fuzz_len : (*__afl_fuzz_len = read(0, __afl_fuzz_alt_ptr, 1048576)) == 0xffffffff ? 0 : *__afl_fuzz_len)" -D "__AFL_LOOP(_A)=({ static volatile char *_B __attribute__((used));  _B = (char*)\"##SIG_AFL_PERSISTENT##\"; __attribute__((visibility(\"default\"))) int _L(unsigned int) __asm__(\"__afl_persistent_loop\"); _L(_A); })" -D "__AFL_INIT()=do { static volatile char *_A __attribute__((used));  _A = (char*)\"##SIG_AFL_DEFER_FORKSRV##\"; __attribute__((visibility(\"default\"))) void _I(void) __asm__(\"__afl_manual_init\"); _I(); } while (0)" -internal-isystem /usr/lib/gcc/x86_64-linux-gnu/9/../../../../include/c++/9 -internal-isystem /usr/lib/gcc/x86_64-linux-gnu/9/../../../../include/x86_64-linux-gnu/c++/9 -internal-isystem /usr/lib/gcc/x86_64-linux-gnu/9/../../../../include/x86_64-linux-gnu/c++/9 -internal-isystem /usr/lib/gcc/x86_64-linux-gnu/9/../../../../include/c++/9/backward -internal-isystem /usr/local/include -internal-isystem /usr/lib/llvm-12/lib/clang/12.0.1/include -internal-externc-isystem /usr/include/x86_64-linux-gnu -internal-externc-isystem /include -internal-externc-isystem /usr/include -O0 -Wno-unused-command-line-argument -Wno-unused-command-line-argument -fdeprecated-macro -fdebug-compilation-dir /home/user/pugixml/src -ferror-limit 19 -funroll-loops -fno-builtin-strcmp -fno-builtin-strncmp -fno-builtin-strcasecmp -fno-builtin-strncasecmp -fno-builtin-memcmp -fno-builtin-bcmp -fno-builtin-strstr -fno-builtin-strcasestr -fgnuc-version=4.2.1 -fcxx-exceptions -fexceptions -fcolor-diagnostics -faddrsig -o pugixml.o -x c++ pugixml.cpp
clang -cc1 version 12.0.1 based upon LLVM 12.0.1 default target x86_64-pc-linux-gnu
ignoring nonexistent directory "/include"
ignoring duplicate directory "/usr/lib/gcc/x86_64-linux-gnu/9/../../../../include/x86_64-linux-gnu/c++/9"
#include "..." search starts here:
#include <...> search starts here:
 /usr/lib/gcc/x86_64-linux-gnu/9/../../../../include/c++/9
...
```

Однако откуда взялись данные ключи в строке запуска компилятора, если мы их не указывали? Все просто - они "зашиты" в основной компилятор AFL afl-cc (различные afl-clang-fast и afl-clang-lto++ это всего лишь ссылки на вызов данного компилятора, который ведёт себя по разному в зависимости от того, какая именно ссылка его вызвала - то есть реальны функционал определяется просто по нулевому параметру argv :)). Увидеть их можно в файле
https://github.com/AFLplusplus/AFLplusplus/blob/3.14c/src/afl-cc.c в районе строки 972:

```
  cc_params[cc_par_cnt++] =
      "-D__AFL_FUZZ_TESTCASE_BUF=(__afl_fuzz_ptr ? __afl_fuzz_ptr : "
      "__afl_fuzz_alt_ptr)";
  cc_params[cc_par_cnt++] =
      "-D__AFL_FUZZ_TESTCASE_LEN=(__afl_fuzz_ptr ? *__afl_fuzz_len : "
      "(*__afl_fuzz_len = read(0, __afl_fuzz_alt_ptr, 1048576)) == 0xffffffff "
      "? 0 : *__afl_fuzz_len)";

  cc_params[cc_par_cnt++] =
      "-D__AFL_LOOP(_A)="
      "({ static volatile char *_B __attribute__((used)); "
      " _B = (char*)\"" PERSIST_SIG
      "\"; "
```

Кстати, если вам зачем-то требуется определить все эти макросы "руками" непосредственно в вашем модуле трансляции и собрать цель обычным clang (а не -fast/-lto), пример как это сделать доступен по ссылке: https://github.com/AFLplusplus/AFLplusplus/blob/3.14c/utils/persistent_mode/persistent_demo_new.c

Но ладно. Определение макроса мы нашли, понять бы теперь, почему у нас нет линковки с указанными в макросах символами... Ведь вообще оно обычно работает "из коробки". Возможно нужно подложить файл с символами руками? Поищем файлы с нужными символами в каталоге собранного AFL:

```
root@fuzzing:/home/user/pugixml/src# find ../../AFLplusplus/ | xargs -I % nm --print-file-name -C % 2>/dev/null | grep __afl_fuzz_ptr
../../AFLplusplus/utils/aflpp_driver/aflpp_driver.o:                 U __afl_fuzz_ptr
../../AFLplusplus/utils/aflpp_driver/libAFLDriver.a:aflpp_driver.o:                 U __afl_fuzz_ptr
../../AFLplusplus/afl-compiler-rt.o:0000000000200060 B __afl_fuzz_ptr
../../AFLplusplus/libAFLDriver.a:aflpp_driver.o:                 U __afl_fuzz_ptr
../../AFLplusplus/afl-llvm-rt-64.o:0000000000200060 B __afl_fuzz_ptr
../../AFLplusplus/afl-compiler-rt-64.o:0000000000200060 B __afl_fuzz_ptr
```

О, возможно если принудительно подложим компилятору объектный файл afl-compiler-rt-64.o, то всё скомпонуется?

```
root@fuzzing:/home/user/pugixml/src# ../../AFLplusplus/afl-clang-lto++ -g3 -O0 -c pugixml.cpp ../../AFLplusplus/afl-compiler-rt-64.o -o pugixml.o -v
```

Нет, надежда умерла не родившись (ошибка будет выглядеть аналогично).

Во-первых, потому что последняя команды - бред (который дошёл до меня не с первого раза - вот он минус отсутствия профильного образования) - если я хочу вызывать линкер, я не должен вызывать компилятор с ключом -с. Этот ключ отвечает за превращение 1-N модулей трансляции в объектный файл, но не за компоновку N объектных файлов в исполняемый.

Во-вторых - добавим простейшую функцию main в pugixml.cpp 

```
 187 int main (int i, char ** c)
 188 {
 189         return 0;
 190 }
``` 

И попробуем собрать pugixml как исполняемый elf, скомпоновав его с afl-compiler-rt-64.o:

```
../../AFLplusplus/afl-clang-fast++ -g3 -O0 pugixml.cpp ../../AFLplusplus/afl-compiler-rt-64.o -o pugixml -v
```

Опять неудача, причём с уже знакомой ошибкой. Как всегда, в случае когда у нас что-то не собирается, нужно проверить ещё раз. И ещё раз. И ещё раз. Скорее всего мы найдём ошибку в собственных действиях. Так получилось и в этот раз - я забыл про макрос ```__AFL_FUZZ_INIT```. Он определен через -D, но вот собственно вызвать его в коде я и забыл. Добавим в начале модуля трансляции (как это рекомендуется разработчиком AFL - прямо перед определением main()).

```
 186 __AFL_FUZZ_INIT();
 187 int main (int i, char ** c)
 188 {
 189         return 0;
 190 }
```

Пробуем скомпилировать:

```
../../AFLplusplus/afl-clang-lto++ -g3 -O0 pugixml.cpp -o pugixml -v
```

Ошибок стало меньше! Уже неплохо. Потеряно определение функции read - нужно подключить заголовочный файл unistd.h. Сделаем это непосредственно в строке запуска компилятора, чтобы лишний раз не изменять файл pugixml.cpp (чем меньше изменений в исходниках анализируемой библиотеки, тем в конечном итоге лучше - можем случайно сломать какую-то тонкую задумку разработчиков).

```
../../AFLplusplus/afl-clang-lto++ -g3 -O0 pugixml.cpp --include=unistd.h -o pugixml -v
```

Оппа! Вот оно и собралось (пусть и с какими-то страшными предупреждениями):

```
#define __AFL_INIT() do { static volatile char *_A __attribute__((used));  _A = (char*)"##SIG_AFL_DEFER_FORKSRV##"; __attribute__((visibility("default"))) void _I(void) __asm__("__afl_manual_init"); _I(); } while (0)
                                                                                                                                                                ^
pugixml.cpp:1979:19: note: used here
<command line>:14:200: note: expanded from here
#define __AFL_INIT() do { static volatile char *_A __attribute__((used));  _A = (char*)"##SIG_AFL_DEFER_FORKSRV##"; __attribute__((visibility("default"))) void _I(void) __asm__("__afl_manual_init"); _I(); } while (0)
                                                                                                                                                                                                       ^
pugixml.cpp:1982:26: warning: function 'pugi::impl::(anonymous namespace)::_L' has internal linkage but is not defined [-Wundefined-internal]
                         while (__AFL_LOOP(10000)) {
                                ^
<command line>:13:157: note: expanded from here
#define __AFL_LOOP(_A) ({ static volatile char *_B __attribute__((used));  _B = (char*)"##SIG_AFL_PERSISTENT##"; __attribute__((visibility("default"))) int _L(unsigned int) __asm__("__afl_persistent_loop"); _L(_A); })
                                                                                                                                                            ^
pugixml.cpp:1982:26: note: used here
<command line>:13:208: note: expanded from here
#define __AFL_LOOP(_A) ({ static volatile char *_B __attribute__((used));  _B = (char*)"##SIG_AFL_PERSISTENT##"; __attribute__((visibility("default"))) int _L(unsigned int) __asm__("__afl_persistent_loop"); _L(_A); })
                                                                                                                                                                                                               ^
2 warnings generated.
 "/usr/lib/llvm-12/bin/ld.lld" -z relro --hash-style=gnu --build-id --eh-frame-hdr -m 
 ...
 
 /usr/lib/gcc/x86_64-linux-gnu/9/../../../x86_64-linux-gnu/crtn.o
afl-llvm-lto++3.14c by Marc "vanHauser" Heuse <mh@mh-sec.de>
Info: Found constructor function _GLOBAL__sub_I_pugixml.cpp with prio 65535, we will not instrument this, putting it into a block list.
[+] Instrumented 10 locations with no collisions (on average 0 collisions would be in afl-gcc/vanilla AFL) (non-hardened mode).
```

И вот тут я надолго задумался - ряд дальнеших самостоятельных экспериментов понимания не прибавили, хотя после прочтения вышеприведенной статьи про компоновщик у меня на подкорке начало формироваться осознание того, что pugixml это чисто C++-проект, а вот фаззер - это всё таки C, а следовательно на стыке этих двух ЯП в одном проекте может происходить нечто, что я не понимаю, и что собственно и будет являться "корнем зла". Так оно дальше и оказалось!

Запустим компилятор с ключом ```--save-temps```, который позволит нам сохранить весь код препроцессора:

```
root@fuzzing:/home/user/pugixml/src# ../../AFLplusplus/afl-clang-lto++ -g3 -O0 -c pugixml.cpp -o pugixml.o --save-temps
```

и откроем получившийся файл: 

```
root@fuzzing:/home/user/pugixml/src# vim -c 'set nu' pugixml.ii
```

Выоборочное представление содержимого файла:

```
35743  xml_encoding guess_buffer_encoding(const uint8_t* data, size_t size)
35744  {
35745   	do {
				static volatile char *_A __attribute__((used)); 
				_A = (char*)"##SIG_AFL_DEFER_FORKSRV##"; 
				__attribute__((visibility("default"))) void _I(void) __asm__("__afl_manual_init"); 
				_I(); 
			} while (0);		

35746   	unsigned char *fuzzed_data = (__afl_fuzz_ptr ? __afl_fuzz_ptr : __afl_fuzz_alt_ptr);
35747
35748   	while (({ 
				static volatile char *_B __attribute__((used)); 
				_B = (char*)"##SIG_AFL_PERSISTENT##"; 
				__attribute__((visibility("default"))) int _L(unsigned int) __asm__("__afl_persistent_loop"); _L(10000); 
			})) {

35749   	int len = (__afl_fuzz_ptr ? *__afl_fuzz_len : (*__afl_fuzz_len = read(0, __afl_fuzz_alt_ptr, 1048576)) == 0xffffffff ? 0 : *__afl_fuzz_len);
35750   	size = len;
35751
```

Вот во что препроцессор превратил наш исходный текст. Намешано много всякого, в том числе монструозные объявления указателей на функции, которые будут использоваться непосредственно здесь же внутри цикла, во вложенном анонимном пространстве имён. Например, указатель ```int _L(unsigned int)``` на функцию ```__afl_persistent_loop```. (```__attribute```, ```___asm``` гарантируют, что ни компилятор, ни компоновщик не "соптимизируют" данную анонимную функцию - подробно данный прототип расписан в https://github.com/AFLplusplus/AFLplusplus/blob/3.14c/src/afl-cc.c:908). 

Однако на самом деле решение вопроса (напомню, задача - собрать статическую библиотеку с фаззинг-целями с PM из pugixml, из каждой цели сделать исполняемую фаззинг-цель) не требует такого глубокого исслледования (хотя понимание того, что проблема связана "анонимным пространство имен", всплыло именно на этом этапе). Корень проблемы в том, что в чистом C понятие именованных пространств имён отсутствует (есть глобальное пространство; есть статические переменные/функции, доступные в пределах модуля трансляции; ну и разумеется пространства видимости на уровне структурных элементов/функций). А вот в C++ пространства имён (namespace) это обычное дело, более того они могут быть вложенными, могут быть именованными/анонимными.

Если мы посмотрим на файл исходного текста выше нашей функции-цели, то увидим, что весь данный блок функций окружен макросом PUGI__NS_BEGIN:

```
1825 PUGI__NS_END
 1826
 1827 PUGI__NS_BEGIN
 1828         enum chartype_t
 1829         {
 1830                 ct_parse_pcdata = 1,    // \0, &, \r, <
 1831                 ct_parse_attr = 2,              // \0, &, \r, ', "
 1832                 ct_parse_attr_ws = 4,   // \0, &, \r, ', ", \n, tab
```

который в файле результатов работы препроцессора pugixml.ii превращается в:

```
35604 # 1825 "pugixml.cpp"
35605 } } }
35606
35607 namespace pugi { namespace impl { namespace {
35608  enum chartype_t
35609  {
35610   ct_parse_pcdata = 1,
35611   ct_parse_attr = 2,
35612   ct_parse_attr_ws = 4,
```

Корень проблемы найден и очень прост - копомпоновщик пытается слинковать объекты из разных пространств имён. Объявление из вложенного пространства: 

**pugi -> impl -> анонимное пространство -> \__afl_fuzz_ptr (pugixml.cpp, написан на С++)** 

c определением:

**\__afl_fuzz_ptr из объектного файла (afl-compiler-64-rt.o, написан на C).**

и разумеется скомпоновать не может - поскольку пространства имён разные и взаимно невидимы.

Если не до конца понятно - чтобы всё это переосмыслить настоятельно рекомендуется прочитать приведенную выше статью про компоновщик, а также посмотреть на конспект, который мы вели, разбираясь с этой ситуацией (стиль изложения - вольный):


1. В варианте под линукс функция, которую мы хотим фаззить, находится в анонимном нэймспейсе внутри именованного нэймспейса.
2. Макросы от AFL рассчитаны на C, а не CPP (а именно они не знают про namespace).
3. В этих макросах производится объявление функций и переменных в стиле extern char* XXX() (extern говорит о том, что символ объявлен в другой единице трансляции). Очевидно они должны быть определены в другом файле
4. Линкер AFL при линковке подсовывает ещё один .o-файл, где всё это определено (afl-compiler-rt....)
6. Та функция, которая через макросы в итоге определилась (то что внутри макросов AFL) она оказалась внутри анонимного namespace внутри именнованного namespace (то есть не в корневом namespace)
7. Поэтому при линковке с сишным rt они друг друга не увидели!
8. Как пофиксить:
9. вынести макросы, касающиеся определения переменных/функции, в глобальный ннэймспейс. Один в условии, один в теле while.
10. Прямо в этих макросах определено тело функции _L (clang --save-temps - получим препроцессор, и увидим) - это жесть (оно внутри именнованного нэймспейса внутри которого безымянный неймспейс с этой функций _L()).
11. Не можем до целовой функции достучаться из main поскольку целевая функция в анонимном нэймспейсе (это специально, прячут - не баг, а фича стиля программирования С++).
12. Мы нашли объявление макросов PUGI__NS_BEGIN и PUGI__NS_END в pugixml.cpp:155. Там есть костыль для MSVS, который видимо нормально не дружит с нэймспейсами. Есть вариант поменять макрос так, чтобы нэймспейс был просто именнованный, а безымянного вообще не было. То есть надо сделать так, чтобы именно данный макрос срабатывал всегда - как будто MSVC-компилятор. Подфиксим определение макроса в строке 155 , заменим:

```
if defined(_MSC_VER) && _MSC_VER < 1300 // MSVC6 seems to have an amusing bug with anonymous namespaces inside namespaces
```

на:

```
if 1   //То есть всегда true, всегда будет неанонимное пространство имён
```

Теперь наша целевая функция должна стать доступна, в том числе из внешнего модуля транслции (при условии вызова её из такого же неймспейса). Напоминаю, наша целевая функция это guess_buffer_encoding (раньше она была во вложенном анонимном пространстве имен, но благодаря вышеуказанному фиксу опредееления макроса она теперь в именованном).

Соберем объектный файл pugixml предварительно удалив из него main:

```
root@fuzzing:/home/user/pugixml/src# ../../AFLplusplus/afl-clang-lto++ -g3 -O0 -c pugixml.cpp --include=unistd.h -o pugixml
```

Создадим собственно исполняемую фаззинг-цель fuzztarget.cpp следующего вида:

```
  #include "pugixml.hpp"
  namespace pugi {
    namespace impl {
      xml_encoding guess_buffer_encoding(const uint8_t *, size_t);
                   }
                 }
  
  int main() {
    const uint8_t * tmp = 0;
    pugi::impl::guess_buffer_encoding(tmp, 8);
    return 0;
  }
```

И успешно скомпилируем (видим желанный вывод компоновщика):

```
root@fuzzing:/home/user/pugixml/src# ../../AFLplusplus/afl-clang-lto++ -g3 -O0 fuzztarget.cpp pugixml.o -o fuzztarget

...

 /usr/include/x86_64-linux-gnu
 /usr/include
End of search list.
 "/usr/lib/llvm-12/bin/ld.lld" -z relro --hash-style=gnu --build-id --eh-frame-hdr -m elf_x86_64 -dynamic-linker /lib64/ld-linux-x86-64.so.2 -o fuzztarget /usr/lib/gcc/x86_64-linux-gnu/9/../../../x86_64-linux-gnu/crt1.o /usr/lib/gcc/x86_64-linux-gnu/9/../../../x86_64-linux-gnu/crti.o /usr/lib/gcc/x86_64-linux-gnu/9/crtbegin.o -L/usr/lib/gcc/x86_64-linux-gnu/9 -L/usr/lib/gcc/x86_64-linux-gnu/9/../../../x86_64-linux-gnu -L/usr/lib/gcc/x86_64-linux-gnu/9/../../../../lib64 -L/lib/x86_64-linux-gnu -L/lib/../lib64 -L/usr/lib/x86_64-linux-gnu -L/usr/lib/../lib64 -L/usr/lib/x86_64-linux-gnu/../../lib64 -L/usr/lib/gcc/x86_64-linux-gnu/9/../../.. -L/usr/lib/llvm-12/bin/../lib -L/lib -L/usr/lib -plugin-opt=mcpu=x86-64 -plugin-opt=O0 --allow-multiple-definition -mllvm=-load=../../AFLplusplus/SanitizerCoverageLTO.so /tmp/fuzztarget-c965a2.o pugixml.o ../../AFLplusplus/afl-compiler-rt.o ../../AFLplusplus/afl-llvm-rt-lto.o --dynamic-list=../../AFLplusplus/dynamic_list.txt -lstdc++ -lm -lgcc_s -lgcc -lc -lgcc_s -lgcc /usr/lib/gcc/x86_64-linux-gnu/9/crtend.o /usr/lib/gcc/x86_64-linux-gnu/9/../../../x86_64-linux-gnu/crtn.o
afl-llvm-lto++3.14c by Marc "vanHauser" Heuse <mh@mh-sec.de>
Info: Found constructor function _GLOBAL__sub_I_pugixml.cpp with prio 65535, we will not instrument this, putting it into a block list.
[+] Instrumented 129 locations with no collisions (on average 0 collisions would be in afl-gcc/vanilla AFL) (non-hardened mode).
```

Осталось только завести фаззинг (не забываем запустить контейнер в привилегированном режиме, чтобы пропатчить core_pattern) :)

```
user@fuzzing:/tmp/faq4$ docker run --network host --privileged  -it --name=pers_ft pers_with_fuzztarget /bin/bash
root@fuzzing:/home/user/pugixml/src# mkdir in out && echo 123456 > in/sample1
root@fuzzing:/home/user/pugixml/src# echo core >/proc/sys/kernel/core_pattern
root@fuzzing:/home/user/pugixml/src# /opt/crusher/crusher/bin_x86-64/fuzz_manager -F -i in -o out -I StaticForkSrv --start 1 -- fuzztarget @@
--force/-F option is enabled. This will delete output directory. Are you sure?[Y/N]')
Y
[2021-09-20 23:22:13.210] [FuzzManager] [info] Read input dir DONE. 1 files from the queue will be divided into 1 parts each at least containing 1 items
[2021-09-20 23:22:13.212] [FuzzManager] [info] Not necessary to run <import inputs> fuzz instance - No <import inputs> dir /home/user/pugixml/src/out/FUZZ-IMPORT_INPUTS in previous fuzz-manager run
[2021-09-20 23:22:13.213] [FuzzManager] [info] FUZZ-MASTER_0 run string: /home/user/crusher/bin_x86-64/fuzz -o /home/user/pugixml/src/out -i /home/user/pugixml/src/out/FUZZ-data/parallel_inputs/input_0 -t 1000 --max-file-size 10M --no-ui -I StaticForkSrv --master FUZZ-MASTER_0:1/1 -- fuzztarget @@
[2021-09-20 23:22:17.219] [FuzzManager] [warning] Can't update stats now. We will try later.
[2021-09-20 23:22:17.219] [FuzzManager] [warning] 0 of 1 instances stats can't be read. Results may be incorrect
[2021-09-20 23:22:20.221] [FuzzManager] [info] inputs for FUZZ-MASTER_0: 1
[2021-09-20 23:22:20.221] [FuzzManager] [info] Percents: 100
[2021-09-20 23:22:20.221] [FuzzManager] [info] Done: 1
```

### На заметку относительно анонимных нейспейсов:
1. Все анонимные неймспейсы одного уровня в одном модуле трансляции склеиваются. Обращаться к ним можно в этом файле из родительского именованного неймспейса напрямую.
2. После компиляции функции из этого склеенного анонимного неймспейса будут не видны никому (это своего рода аналог static в С). Делает функции приватными для модуля трансляции. 
