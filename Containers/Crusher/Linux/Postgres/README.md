*Протестировано с crusher 2.4.0*

Докерфайлы созданы так, чтобы пробрасывать в контейнер id и name пользователя и группы, выполняющих сборку кода, подлежащего в дальнейшем фаззинг-тестированию. Аналогичные пользователи создаются внутри контейнера для упрощения взаимодействия с хостом - в частности устанавливаются одинаковые права на каталог, пробрасываемый внутрь контейнера. По умолчанию в контейнере создается пользователь `crusher:crusher (1000:1000)` - стандартный пользователь на моей фаззинг-ферме.

*Докерфайлы расчитаны на работу с использованием доступного по сети центра лицензирования Crusher (красный хасп)*

### ПРЕДНАЗНАЧЕНИЕ ДОКЕРФАЙЛОВ

`Dockerfile.DRIO.txt` - сборка и фаззинг в режиме динамического инструментирования

`Dockerfile.STATIC.txt` - сборка и фаззинг в режиме статического инструментирования

`Dockerfile.STATIC_COV.txt` - сбор покрытия для сборки, полученной в режиме статического инструментирования

`Dockerfile.EAT.txt` - контейнер для запуска процесса-анализатора EAT (Extra Analysis Tool) Crusher

### КОМАНДЫ СБОРКИ ОБРАЗОВ КОНТЕЙНЕРОВ

#### Подговительные действия перед сборкой образа
1. Сохранить дистрибутив Crusher в текущую директорию с именем crusher.tar.gz
2. Создать каталог in в текущей директории и скопировать в него входные данные

#### Команда сборки образа для фаззинга в режиме динамического инструментирования.
sudo docker build --build-arg cuid=$(id -u) --build-arg cgid=$(id -g) --build-arg cuidname=$(id -un) --build-arg cgidname=$(id -gn) -t crusher_drio -f Dockerfile.DRIO.txt .
*Точка в конце команды означает текущий каталог

#### Команда сборки образа для фаззинга в режиме статического инструментирования. Сборка с санитайзерами UBSAN и компиляторными оптимизациями LAF.
sudo docker build --build-arg cuid=$(id -u) --build-arg cgid=$(id -g) --build-arg cuidname=$(id -un) --build-arg cgidname=$(id -gn) -t crusher_static -f Dockerfile.STATIC.txt .

#### Команда сборки образа для сбора покрытия в режиме статического инструментирования
sudo docker build --build-arg cuid=$(id -u) --build-arg cgid=$(id -g) --build-arg cuidname=$(id -un) --build-arg cgidname=$(id -gn) -t crusher_static_cov -f Dockerfile.STATIC_COV.txt .

#### Команда сборки образа для запуска EAT.
sudo docker build --build-arg cuid=$(id -u) --build-arg cgid=$(id -g) --build-arg cuidname=$(id -un) --build-arg cgidname=$(id -gn) -t crusher_eat -f Dockerfile.EAT.txt .

### Команды управления контейнерами

#### Удаление результатов предыдущих запусков
rm -rf /var/work/experiments/cluster/out

*Это необходимый пункт, т.к. иначе каждый процесс fuzz_manager, видя уже имеющуюся директорию с результатами,
будет требовать от пользователя подтвердить её удаление, что мешает автоматизированному запуску.*

#### Команда запуска фаззинг-контейнера в режим контроля STDOUT для контроля в консоли того, что происходит в контейнере
sudo docker run --network host --name=fuzz -v /var/work/experiments/cluster/out:/home/$(id -un)/out -e "FUZZ_INSTANCE=fuzz" --privileged crusher_drio

sudo docker run --network host --name=fuzz -v /var/work/experiments/cluster/out:/home/$(id -un)/out -e "FUZZ_INSTANCE=fuzz" --privileged crusher_static

#### Два варианта запуска в цикле N (N=5) контейнеров
for i in $(seq 1 5); do docker run --network host --name=fuzz$i -v /var/work/experiments/cluster/out:/home/$(id -un)/out -e "FUZZ_INSTANCE=fuzz$i" -d --privileged crusher_drio; done

for i in $(seq 1 5); do docker run --network host --name=fuzz$i -v /var/work/experiments/cluster/out:/home/$(id -un)/out -e "FUZZ_INSTANCE=fuzz$i" -d --privileged crusher_static; done

#### Запуск EAT (Extra Analysis Tool) в отдельном контейнере в отдельном терминале screen
screen -dmS EAT docker run --network host --rm --name=eat -v /var/work/experiments/cluster/out:/home/$(id -un)/out --privileged crusher_eat

#### Уничтожение в цикле N (N=5) контейнеров (заодно чистится выходной каталог - !в реальной работе так делать не нужно!)
for i in $(seq 1 5); do docker kill fuzz$i ; docker rm fuzz$i ; done ; rm -rf out

#### Уничтожение контейнера с EAT
sudo docker kill eat && docker rm eat

### ДИНАМИЧЕСКОЕ ОЗНАКОМЛЕНИЕ С РЕЗУЛЬТАТАМИ ФАЗЗИНГА (like afl-cov)
В специальном контейнере выполняется сборка цели с инструментацией под сбор покрытия, прогоняются сэмплы из каталога в котором сохраняется queue выбранного фаззера, формируется html-отчет, формируется текстовый отчет (текущий, при наличии предыдущего он сохраняется для выполнения сравнения через diff)

#### Команда запуска конвейера прогона сэмплов через сборку, адаптированную под подсчет покрытия
sudo docker run --name=cov -v /var/work/experiments/cluster/out/fuzz1-MASTER_0/queue:/home/$(id -un)/in_stat -v /var/work/experiments/cluster/out_stat:/home/$(id -un)/out_stat -d --privileged crusher_static_cov && docker wait cov && docker rm cov

#### Команда легковесного сравнения предыдущего и текущего текстовых отчетов
diff --suppress-common-lines -y out_stat/coverage.txt out_stat/coverage_prev.txt

*В результате выполнения команды можно быстро посмотреть в каких модулях достигнут прирост покрытия с момента прошлого подсчета покрытия*
