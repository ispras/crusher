#Dockerfile-файлы созданы так, чтобы пробрасывать в контейнер id и name пользователя и группы, выполняющих сборку. Аналогичные пользователи создаются внутри контейнера для упрощения взаимодействия с хостом. По умолчанию в контейнере создается пользователь crusher:crusher (1000:1000) - стандартный пользователь на фаззинг-ферме.

#Команда подготовки образа для фаззинга в режиме динамического инструментирования (легче, медленнее). Включены санитайзеры libdislocator.
docker build --build-arg cuid=$(id -u) --build-arg cgid=$(id -g) --build-arg cuidname=$(id -un) --build-arg cgidname=$(id -gn) -t crusher_DRIO -f Dockerfile.drio.txt .

#Команда подготовки образа для фаззинга в режиме статического инструментирования (сложнее, быстрее). Сборка с санитайзерами UBSAN, с компиляторными оптимизациями LAF.
docker build --build-arg cuid=$(id -u) --build-arg cgid=$(id -g) --build-arg cuidname=$(id -un) --build-arg cgidname=$(id -gn) -t crusher_STATIC -f Dockerfile.static.txt .

#Команда подготовки образа для запуска EAT (Extra Analysis Tool) в режиме статического инструментирования (сложнее, быстрее). Сборка с санитайзерами UBSAN, с компиляторными оптимизациями LAF.
docker build --build-arg cuid=$(id -u) --build-arg cgid=$(id -g) --build-arg cuidname=$(id -un) --build-arg cgidname=$(id -gn) -t crusher_EAT -f Dockerfile.eat.txt .

#Удаление результатов предыдущих запусков
rm -rf /var/work/experiments/cluster/out

Это необходимый пункт, т.к. иначе каждый процесс fuzz_manager, видя уже имеющуюся директорию с результатами,
будет требовать от пользователя подтвердить её удаление, что мешает автоматизированному запуску.

#Запуск контейнера в режим контроля STDOUT для контроля в консоли того, что происходит в контейнере
docker run --name=fuzz -v /var/work/experiments/cluster/out:/home/$(id -un)/out -e "FUZZ_INSTANCE=fuzz" --privileged crusher_DRIO
docker run --name=fuzz -v /var/work/experiments/cluster/out:/home/$(id -un)/out -e "FUZZ_INSTANCE=fuzz" --privileged crusher_STATIC

#Два варианта запуска в цикле N (N=5) контейнеров
for i in $(seq 1 5); do docker run --network host --name=fuzz$i -v /var/work/experiments/cluster/out:/home/$(id -un)/out -e "FUZZ_INSTANCE=fuzz$i" -d --privileged crusher_DRIO; done
for i in $(seq 1 5); do docker run --network host --name=fuzz$i -v /var/work/experiments/cluster/out:/home/$(id -un)/out -e "FUZZ_INSTANCE=fuzz$i" -d --privileged crusher_STATIC; done

#Запуск EAT (Extra Analysis Tool) в отдельном контейнере
screen -dmS EAT docker run --rm --name=eat -v /var/work/experiments/cluster/out:/home/$(id -un)/out --privileged crusher_EAT

#Уничтожение в цикле N (N=5) контейнеров (заодно чистится выходной каталог - в реальной работе так делать не нужно)
for i in $(seq 1 5); do docker kill fuzz$i ; docker rm fuzz$i ; done ; rm -rf out

#Уничтожение контейнера с EAT
docker kill eat
docker rm eat

###ДИНАМИЧЕСКОЕ ОЗНАКОМЛЕНИЕ С РЕЗУЛЬТАТАМИ ФАЗЗИНГА (like afl-cov)
###В специальном контейнере выполняется сборка цели с инструментацией под сбор покрытия, прогоняются сэмплы из каталога в котором сохраняется queue выбранного фаззера, формируется html-отчет, формируется текстовый отчет (текущий, при наличии предыдущего он сохраняется для выполнения сравнения через diff)

# Команда подготовки образа для сбора покрытия в режиме статического инструментирования
docker build --build-arg cuid=$(id -u) --build-arg cgid=$(id -g) --build-arg cuidname=$(id -un) --build-arg cgidname=$(id -gn) -t crusher_STATIC_COV -f Dockerfile.static_cov.txt .

# Команда запуска конвейера прогона сэмплов через сборку, адаптированную под подсчет покрытия (в данном случае берем queue первого FuzzManager)
docker run --name=cov -v /var/work/experiments/cluster/out/fuzz1-MASTER_0/queue:/home/$(id -un)/in_stat -v /var/work/experiments/cluster/out_stat:/home/$(id -un)/out_stat -d --privileged crusher_STATIC_COV && docker wait cov && docker rm cov

# Команда легковесного сравнения предыдущего и текущего текстовых отчетов
diff --suppress-common-lines -y out_stat/coverage.txt out_stat/coverage_prev.txt
