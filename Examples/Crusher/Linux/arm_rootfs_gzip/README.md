Фаззинг gzip из Ubuntu20 (ARM).

## 1. Подготовка таргета
1. Скачать rootfs с Ubuntu20 (ARM):
```shell
wget https://cdimage.ubuntu.com/ubuntu-base/releases/focal/release/ubuntu-base-20.04.5-base-armhf.tar.gz
mkdir rootfs
tar xvf ubuntu-base-20.04.5-base-armhf.tar.gz -C rootfs/
```

2. Подготовить rootfs (необходимо указать актуальные пути):
```shell
cp -r crusher/bin_x86-64/qemu-user-mode-arm-64bit rootfs/qemu
./mount.sh ./rootfs/
```

См. также раздел "Запуск в chroot-режиме" в документации фаззера.

3. Сформировать нач. корпус вх. данных (сделано):
```shell
mkdir in
echo 0 > seed
zip -r in/seed.zip seed
```

4. Проверить gzip:
```shell
sudo -E chroot rootfs/ /qemu/qemu-static /usr/bin/gzip -d -c < in/seed.zip
```

Необходимо убедиться, что распакованные данные соответствуют ранее запакованным.

## 2. Фаззинг.
Перед запуском необходимо удалить `rootfs/dev/*` и `rootfs/proc`.

1. Запуск фаззинга:
```shell
sudo -E crusher/bin_x86-64/fuzz_manager --start 8 --eat-cores 2 --config-file config.json \
-i in/ -o out -- /usr/sbin/chroot ./rootfs/ /qemu/qemu-static /usr/bin/gzip -d -c
```

2. Мониторинг:
```shell
sudo -E crusher/bin_x86-64/ui -o out
```
