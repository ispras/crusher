
Фаззинг OpenSSL методом модифицированного клиента:

- сервер OpenSSL v1.1.1j;
- дифференциальный фаззинг протокола с состояниями; 
- воспроизведение известной ошибки CVE-2021-3449.

Данная ошибка проявляется в следующем сценарии:

1) Установка TLS-соединения;
2) Отправка невалидного зашифрованного сообщения `ClientHello` в рамках пересогласования параметров TLS-соединения.

План:

0. Подготовка инструментов;
1. Подготовка OpenSSL-сервера (объект фаззинга);
2. Подготовка мод. OpenSSL-клиента;
3. Подготовка (валидного) сценария взаимодействия клиента с сервером;
4. Генерация нач. вх. данных;
5. Создание вспомогательных скриптов для фаззинга;
6. Запуск фаззинга;
7. Анализ результатов.

См. также разделы "Фаззинг протоколов с использованием модифицированного клиента" и "Дифференциальный фаззинг" в документации.

## 0. Подготовка инструментов

1. Фаззер.

Распаковать в `tools/crusher`.

2. AFL++:

Собрать в `tools/AFLplusplus`:
```shell
git clone --branch v4.08c --depth 1 https://github.com/AFLplusplus/AFLplusplus
cd AFLplusplus/
make -j
```

## 1. Подготовка OpenSSL-сервера

Скачаем проект OpenSSL и перейдём на нужный тег:
```shell
$ cd server
$ git clone https://github.com/openssl/openssl
$ cd openssl
$ git checkout OpenSSL_1_1_1j
```

### 1.1. Патчи

Необходимо обеспечить следующее (за счёт патчей в исходном коде):

1. Удалание ci

Удалить `.travis*` и `.github/`.

2. Дерандомизация.

Для детерминированной работы сервера необходимо вызывать ф-цию `FuzzerSetRand` (см. https://github.com/profuzzbench/profuzzbench/blob/master/subjects/TLS/OpenSSL/rand.patch)
в начале каждого дочернего процесса fork-сервера.

3. Установка точки вызова fork-сервера.

Точку fork-а необходимо поставить как можно позже в программе, но до того момента,
как начинают обрабатываться вх. данные.
В серверах можно отслеживать вызовы `select` и `accept`.
В данном примере перед вызовом `do_server` (`s_server.c`) необходимо вставить следующий код:
```c
    #ifdef __AFL_HAVE_MANUAL_CONTROL
        __AFL_INIT();
    #endif
```

4. Завершение сервера по таймауту.

В процессе взаимодействия как сервер, так и клиент могут зависнуть.
Чтобы избежать этого (= ускорить фаззинг), необходимо ограничиить время выполнения процесса.

Для этого устанавливается обработчик на сигнал SIGALRM в `s_server.c`:
```c
#include <signal.h>

void sig_handler(int signum){
  printf("SIGALARM handler - exit\n");
  exit(0);
}

int s_server_main(int argc, char *argv[])
{
    signal(SIGALRM, sig_handler);
    ...
}
```

и выставляется таймер перед вызовом `do_server`:
```c
    ualarm(100000, 25000);

    do_server(&accept_socket, host, port, socket_family, socket_type, protocol,
    server_cb, context, naccept, bio_s_out);
```

Все патчи - см. `server/server.patch`. Применим их:
```shell
$ git apply ../server.patch
```

### 1.2. Сборка
Для выполнения дифф. фаззинга необходимо создать набор сборок с применением разных санитайзеров: 

0. Дебаг-сборка.
Закомментируем временно следующую строку из патча - чтобы сервер не завершался раньше времени, когда будет генерировать нач. вх. данные:
```c
ualarm(100000, 25000);
```

и выполним сборку:
```shell
$ make clean && make distclean
$ CFLAGS="-ggdb3 -O0" ./config no-shared no-tests
$ make -j
$ cp apps/openssl ../openssl-debug
```

Раскомментируем обратно.

1. Сборка без санитайзеров:
```shell
$ make clean && make distclean
$ CC=/path/to/tools/AFLplusplus/afl-clang-fast ./config no-shared no-tests
$ make -j
$ cp apps/openssl ../openssl-afl
```

2. Сборка с ASan:
```shell
$ make clean && make distclean
$ CC=/path/to/tools/AFLplusplus/afl-clang-fast ./config no-shared no-tests enable-asan
$ make -j
$ cp apps/openssl ../openssl-afl-asan
```

3. Сборка с MSan:
```shell
$ make clean && make distclean
$ CC=/path/to/tools/AFLplusplus/afl-clang-fast ./config no-shared no-tests enable-msan
$ make -j
$ cp apps/openssl ../openssl-afl-msan
```

## 2. Подготовка мод. OpenSSL-клиента

Скачаем проект OpenSSL и перейдём на нужный коммит (более новый, чем у сервера):
```shell
$ cd client
$ git clone https://github.com/openssl/openssl
$ cd openssl
$ git checkout 5c3c8369f3b42ce4b816606bb9bbad00c664a416
```

### 2.1. Патчи

Необходимо обеспечить следующее (за счёт патчей в исходном коде):

1. Дерандомизация (аналогично серверу).

Вызов ф-ции `FuzzerSetRand` выполняется после точки fork-а (см. далее).

2. Установка точки вызова fork-сервера.

Рекомендуется поставить её как можно ближе к моменту установки соединения.
В случае tcp-сервера это вызов `connect`.
Точка fork-а (`custom_fork_server`) и `FuzzerSetRandom` выполняются до вызова `init_client` (`s_client.c`).
Т.е. получается такая последовательность вызовов:
```c
    custom_fork_server(); // fork-server
    FuzzerSetRand();      // derandomization

    if (init_client(&sock, host, port, bindhost, bindport, socket_family,
                    socket_type, protocol, tfo, !isquic, &peer_addr) == 0) {
        BIO_printf(bio_err, "connect:errno=%d\n", get_last_socket_error());
        BIO_closesocket(sock);
        goto end;
    }
```

3. Добавление мутаций.

Мутации в ф-ции `put_value`.
В ф-ции `put_value` (`packet.c`) выполняется запись целочисленного значения `value` в буфер.
Работа с данными в этой ф-ции выполняется ещё до шифрования.
В начале этой ф-ции сделаем мутирующую вставку:
```c
    value = mutate_int(value, len);
```

Также необходимо скопировать `mod-client-api/` в `openssl/`
и добавить соответствующий include в файлы с мутациями.

Все патчи - см. `client/client.patch`. Применим их:
```shell
$ git apply ../client.patch
```

### 2.2. Сборка

1. Чистая сборка:
```shell
$ make clean && make distclean
$ ./config no-shared no-tests
# В Makefile в правило для сборки цели apps/openssl в конце добавить mod-client-api/libmodclient.a
$ make -j
$ cp apps/openssl ../openssl-clean
```

## 3. Подготовка (валидного) сценария взаимодействия клиента с сервером
1. Протокол взаимодействия.

TLS 1.2 (указывается в опциях сервера и клиента)

2. Сервер использует сгенерированные заранее rsa-ключ и x509-сертификат.

Указываются в опциях сервера.

3. Сервер завершается после завершения 1-го tcp-соединения.

Указываются в опциях сервера.

4. Нач. сценарий взаимодействия.

TLS-рукопожатие (handshake) + переустановка параметров TLS-сессии (renegotiation) + завершение TLS-соединения.

По умолчанию при запуске openssl-сервера (`openssl s_server`) и клиента происходит установление TLS-соединения,
после чего можно в stdin писать сообщения.

Также можно передавать команды на пересогласование параметров соединения (`R`) и его завершение (`Q`).

В код клиента были добавлены доп. патчи (`s_client.c`), чтобы команды `R` и `Q` выполнялись сразу после TLS-рукопожатия:
```c
// патч - вспомогательные переменные
uint8_t hs_done = 0;
uint8_t reneg_start = 0;
uint8_t reneg_done = 0;
...

print_stuff(bio_c_out, con, full_log);
hs_done = 1; // патч - рукопожатие выполнено
...

static int user_data_process(struct user_data_st *user_data, size_t *len,
size_t *off)
{

    // патч - автоматическое выполнение renegotiation- и quit-команд
    if (hs_done && !reneg_done) {
        reneg_done = 1;
        return user_data_execute(user_data, USER_COMMAND_RENEGOTIATE, NULL);
    } if (reneg_done) {
        return user_data_execute(user_data, USER_COMMAND_QUIT, NULL);
    }
    
    ...
}
```

В итоге сервер будем запускать такой командой (пути и порт могут меняться):

// ./server.sh
```shell
    $ ./server/openssl-debug s_server \
      -cert ./keys/cert.pem -key ./keys/key.pem \
      -accept 4444 -naccept 1 -legacy_renegotiation
```

а клиент такой:

// ./client.sh
```shell
    $ ./client/openssl-debug s_client \
      -tls1_2 -connect 127.0.0.1:4444 -legacy_renegotiation
```

## 4. Генерация нач. вх. данных
1) Создать папку `in`:
```shell
    $ mkdir in
```

2) Запустить сервер:
```shell
    $ ./server.sh
```

3) Запустить мод. клиент:
```shell
    $ GEN_FILE=$PWD/in/session ./client.sh
```

В переменной окружения `GEN_FILE` указывается файл, куда будет записан образец нач. входных данных.

Обратите внимание, что при добавлении/удалении вызовов `mutate_*` в клиенте необходимо пересоздать начальный образец вх. данных.

## 5. Создание вспомогательных скриптов для фаззинга

### 5.1. Скрипт запуска мод. клиента
См. `plugins/client.py`:
```python
    from subprocess import Popen, PIPE
    from pathlib import Path
    import os
    
    # Эти переменные окружения выставляет фаззер.
    # Номер порта используется
    # при формировании аргументов запуска клиента.
    work_dir = Path(os.getenv("WORK_DIR"))
    port = int(os.getenv("PORT"))
    
    target_dir = os.path.join(os.path.dirname(__file__), os.pardir)
    
    if __name__ == '__main__':
        # Запуск процесса клиента выполняется 1 раз
        # (в рамках работы одного fuzz или eat процесса).
        # В этом процессе будет работать fork-сервер
        client_parent_file = work_dir / "client_parent"
        if not client_parent_file.exists() or True:
            # Здесь необходимо указать команду запуска клиента.
            # Используется значение ранее полученного порта.
            command = [f"{target_dir}/client/openssl-clean",
                       "s_client", "-tls1_2",
                       "-connect", f"127.0.0.1:{str(port)}",
                       "-legacy_renegotiation"]
            # Запуск процесса клиента 
            # (в некоторых случаях может потребоваться указать stdin=None).
            client = Popen(command, stdin=PIPE)
            # Создание этого файла необходимо,
            # чтобы сообщить фаззеру pid процесса клиента.
            f = open(str(client_parent_file), "w")
            f.write(str(client.pid))
            f.close()
```

В большинстве случаев в этом скрипте необходимо менять только команду запуска клиента
и в некоторых случаях - значание параметра `stdin` при создании процесса клиента с помощью вызова `Popen`.

### 5.2. Скрипт модификации опций
См. `plugins/conf.py`.

В методе `transform_options` бинарь openssl-сервера заменяется на asan- и msan-сборки в отдельных fuzz-процессах - для обеспечения дифференциального фаззинга.

См. также раздел "Пользовательские скрипты модификации опций" в документации.

## 6. Запуск фаззинга
К этому моменту готовы:
- сервер (объект фаззинга) и мод. клиент;
- нач. сценарий их взаимодействия;
- нач. образец вх. данных (привязан к нач. сценарию);
- вспомогательные пользовательские плагины.

1. Запуск фаззера.

Предварительная подготовка окружения:
```shell
sudo su
echo core >/proc/sys/kernel/core_pattern
exit
```

Фаззинг запускается командой:
```shell
    $ crusher/bin_x86-64/fuzz_manager --start 50 --eat-cores 0 \
      -i in/ --port __free_port --config-file config.json -o out \
      -- $PWD/server/openssl-afl s_server \
      -cert $PWD/keys/cert.pem -key $PWD/keys/key.pem \
      -accept __free_port -naccept 1 -legacy_renegotiation
```

Опции фаззера (+ `config.json`):

* `--start <num>` - число fuzz-процессов (экземпляры фаззинга);
* `--eat-cores <num>` - число eat-процессов (процессы доп. анализа);
* `--dse-cores <num>` - число dse-процессов (динамическое символьное выполнение), в данном режиме не поддерживается;
* `--wait-next-instance <milliseconds>` - задержка (в миллисекундах) между запусками fuzz/eat-процессов (для избежения конфликтов);
* `--configurator-script <path>` - скрипт модификации опций (для избежения конфликтов);
* `--eat-sync` - включить синхронизацию через инструмент расширенного анализа;
* `-T <type>` - тип транспорта (`ModClient/ModClientUdp` - в случае фаззинга сервера мод. клиентом, `ModServer/ModServerUdp` - в обратном случае);
* `--mod-client <path>` - Python3-скрипт запуска мод. клиента;
* `--port <num/__free_port>` - порт, на который отправляются мутированные данные (если указан спецификатор `__free_port`, то фаззер подставит вместо него свободный порт);
* `--delay <milliseconds>` - активное ожидание, пока tcp-порт будет занят, перед отправкой мутированных данных (в миллисекундах);
* `-I <type>` - тип инструментации;
* `--redirect-stdin-off` - не перенаправлять stdin в /dev/null (по умолчанию перенаправляется);
* `-i <path>` - путь до директории с начальными образцами входных данных;
* `-o <path>` - путь к выходной директории с результатами фаззинга;
* `-t <milliseconds>` - таймаут на запуск приложения (в миллисекундах).

2. Мониторинг фаззинга.

Запуск ui (в другом терминале):
```shell
    $ crusher/bin_x86-64/ui -o out
```

Необходимо дождаться, пока появятся креши - см. поле `unique_crashes` в правом верхнем окне.

## 7. Анализ результатов
Образцы входных данных, приводящие к крешам - сохраняются в директориях `out/*/crashes`.

### 7.1. Фильтрация крешей

```shell
crusher/bin_x86-64/ftk --crashfilter crashes --crashfilter-metric 0.5 \
                       --port 4444 --config-file config.json -o out \
                       -- $PWD/server/openssl-afl s_server \ 
                       -cert $PWD/keys/cert.pem -key $PWD/keys/key.pem \
                       -accept 4444 -naccept 1 -legacy_renegotiation
```

Опции (ранее не рассмотренные):

* `--crashfilter <path>` - директория для результатов;
* `--crashfilter-metric <num>` - порог различия битовых карт покрытия (0..1).

Набор отфильтрованных крешей - в папке `crashes/crashes`.

См. также раздел "Crashfilter" в документации.

### 7.2. Воспроизведение креша

Пример воспроизведения креша:

1) Запустить сервер:
```shell
    $ ./server/openssl-debug s_server \
      -cert ./server/keys/cert.pem -key ./server/keys/key.pem \
      -tls1_2 -accept 4444 -naccept 1 -legacy_renegotiation
```

2) Запустить клиент (с указанием образца вх. данных):
```shell
    $ REPLAY_FILE=./crashes/crashes/id_crash_000000 \
      ./client/openssl-clean s_client \
      -tls1_2 -connect 127.0.0.1:4444 -legacy_renegotiation
```

Сервер завершится с сигналом `SigSegv`.
