### Подготовка Dual-Emu к запуску

Следует использовать докер-контейнер с Ubuntu 18:

```
$ docker pull ubuntu:18.04
$ docker run -it --privileged --network host --name emu ubuntu:18.04 /bin/bash
```

Рекомендуется поставить пакеты внутри контейнера:

```
$ chmod 0777 /tmp
$ apt update
$ apt install -y vim build-essential git python libcurl4
```

Используя `docker cp`, нужно скопировать внутрь контейнера
папку с примером (например, `DualEmu`) и релиз фаззера Crusher.

В папке `crusher` нужно запустить скрипт установки Python-библиотек:
```
$ ./tools/install_external_packages.sh
```

Нужно использовать Python из Crusher, например:
```
$ ./crusher/bin_x86-64/python-3.9_x86_64/bin/python3 ./script.py --qiling -i ./input
```

