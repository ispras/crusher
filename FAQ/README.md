### Практические истории и примеры как делать надо и не надо

#### Общий порядок действий

Кейсы рекомендуется помещать в типовые контенеры, за основу оформления взят контейнер [Статическое инструментирование и фаззинг Postgres](../Containers/Crusher/Linux/Readme.md).

Сборка контейнера осуществляется командой наподобие (параметры ```--build-arg``` позволяют пробросить uid/gid в контенер для облегчения файовой синхронизации при небходимости и не влияют на приведенные описания с точки зрения их логики):

```docker build --build-arg cuid=$(id -u) --build-arg cgid=$(id -g) --build-arg cuidname=$(id -un) --build-arg cgidname=$(id -gn) -t ИМЯ_ОБРАЗА -f ИМЯ_ДОКЕРФАЙЛА .```

Запуск контейнера для выполнения экспериментов осуществляется командой наподобие:

```docker run -it --name=ИМЯ_КОНТЕЙНЕРА ИМЯ_ОБРАЗА /bin/bash```

где:

- ИМЯ_ДОКЕРФАЙЛА это выбранный пример докерфайла 
- ИМЯ_ОБРАЗА - произвольное, назначаемое экспериментирующим, имя образа 
- ИМЯ_КОНТЕЙНЕРА - произвольное, назначаемое экспериментирующим имя контейнера.

Полную очистку результатов работы можно осуществить выполнив команду:

```docker kill ИМЯ_КОНТЕЙНЕРА ; docker rm ИМЯ_КОНТЕЙНЕРА ; docker rmi ИМЯ_ОБРАЗА```

#### 1. Особенности использования clang-компиляторов из комплекта AFL++ при статическом инструментировании
[Описание кейса](FAQ_1_afl++clang.md)

[Контейнер для экспериментов](Dockerfile_FAQ_1_afl++clang.txt)

#### 2. Формирование статической библиотеки, содержащей фаззинг-цель
[Описание кейса](FAQ_2_static_lib.md)

[Контейнер для экспериментов](Dockerfile_FAQ_2_static_lib.txt)

#### 3. [Фаззинг и сбор покрытия для проекта на языке Rust](https://github.com/ispras/crusher/blob/master/FAQ/rust-fuzz-example/README.md)
