## Фаззинг и сбор покрытия для rust проекта

Основной подход следующий:

* Собираем цель под фаззинг, запускаем, сохраняем результирующий корпус.
* Делаем цель с инструментацией для сбора покрытия и собираем покрытие.
* Визуализация покрытия.

Данный подход будет рассмотрен на примере фаззинга библиотеки
[goblin](https://github.com/m4b/goblin).

### Cборка цели под фаззинг

Для фаззинга своего кода на rust можно использовать следующие проекты:

* cargo-fuzz
* honngfuzz-rs

#### Фаззим goblin через cargo-fuzz

Устанавливаем `cargo-fuzz`:

    $ cargo install cargo-fuzz

Скачиваем репозиторий:

    $ git clone https://github.com/m4b/goblin

В проекте уже написаны цели под фаззинг, попробуем запустить одну из них.
Для этого переходим в папку `fuzz`.

    $ cd fuzz

Выбираем цель `parse`, которая разбирает входной файл произвольно формата:

```rust
#![no_main]
use libfuzzer_sys::fuzz_target;

fuzz_target!(|data: &[u8]| {
    let _ = goblin::Object::parse(data);
});
```
В данном случае, фаззер это libfuzzer, а обёртка выглядит, как на C/C++, только
язык rust. Под фаззинг написан отдельный конфигурационный файл сборки `Cargo.toml`.

Запускаем фаззинг следующей командной:

    $ cargo +nightly fuzz run parse

Видно, что происходит сборка проекта вместе с libfuzzer, затем запускается
фаззинг и быстро находится первый крэш.

Результирующий corpus лежит в директории `corpus/parse`, а крэш находится в
директории `artifacts/parse`.

#### Фаззинг goblin через honggfuzz-rs

Устанавливаем `honggfuzz-rs`.

    $ cargo install honggfuzz

Создаем проект с целью под фаззинг и добавляем в зависимости honggfuzz.

```toml
[dependencies]
honggfuzz = "0.5"
```

Пишем цель под фаззинг, аналогичную `parse` из предыдущего примера.

```rust
use goblin::Object;
use honggfuzz::fuzz;

fn main () {
    loop {
        fuzz!(|data: &[u8]| {
            let _ =Object::parse(data);
        });
    }
}
```
Здесь все как в AFL persistent mode. Затем запускаем цель на фаззинг командной:

    $ cargo +nightly hfuzz run honggfuzz-goblin

После сборки запускается honggfuzz и также находит крэш, который находится в
директории `hfuzz_workspace/honggfuzz-goblin`, а результирующий корпус в
директории `hfuzz_workspace/honggfuzz-goblin/inputs`.

### Делаем цель с инструментацией для сбора покрытия и собираем покрытие.

При использовании cargo-fuzz покрытие можно собрать автоматически командной
coverage.

    $ cargo +nightly fuzz coverage parse

Также собирается цель уже с инструментацией для сбора покрытия, прогоняется на
всех файлах из корпуса и создаются файлы \*.profraw. Файлы находятся в
директории `coverage/parse/raw`.

#### Создание цели для сбора покрытия в ручную.

Honggfuzz-rs не предоставляет автоматической возможности по получению файлов с
покрытием. Для этого собираем свою цель, которая принимаем на вход файл, читает
его и использует как входные данные для цели фаззинга. Для удобства можно
использовать условную компиляцию и сделать код в одном файле:

```rust
use goblin::Object;

#[cfg(feature="coverage")]
use goblin::error;


#[cfg(not(feature="coverage"))]
fn main () {
    use honggfuzz::fuzz;

    loop {
        fuzz!(|data: &[u8]| {
            let _ =Object::parse(data);
        });
    }
}

#[cfg(feature="coverage")]
fn main () -> error::Result<()> {
    use std::path::Path;
    use std::env;
    use std::fs;

    for (i, arg) in env::args().enumerate() {
        if i == 1 {
            let path = Path::new(arg.as_str());
            let data = fs::read(path)?;
            let _ =Object::parse(&data);
        }
    }
    Ok(())
}
```
Перед сборкой устанавливаем деманглер для rust:

    $ cargo install rustfilt

Собрать цель под покрытие можно командой:

    $ RUSTFLAGS="-Zinstrument-coverage" cargo +nightly  build --features
coverage

Затем, можно написать скрипт, который запускает  программу на входном корпусе и
получает \*.profdata файлы. Пример запуска программы:

    $ LLVM_PROFILE_FILE="goblin.profraw" ./target/debug/honggfuzz-goblin ./hfuzz_workspace/honggfuzz-goblin/input/58a30312adf78815977f07974d8aff14.00000080.honggfuzz.cov

В результате получается файл с покрытием.

### Визуализация покрытия

Устанавливаем средства объединения и визуализации покрытия. Это может быть llvm
от 11 версии, или же можно установить соответствующие rust обертки, которые
поставят llvm нужной версии.

    $ rustup component add llvm-tools-preview
    $ cargo install cargo-binutils
    $ cargo profdata -- --help


Объединяем покрытие:

    $ cargo profdata -- merge --sparse ./coverage -o goblin.profdata

Через llvm:

    $ /opt/llvm-main/bin/llvm-profdata merge -sparse ./coverage -o goblin.profdata

Смотрим на результат с помощью команды:

    $ /opt/llvm-main/bin/llvm-cov show -Xdemangler=rustfilt target/x86_64-unknown-linux-gnu/coverage/x86_64-unknown-linux-gnu/release/parse \
    -instr-profile=goblin.profdata \
    -show-line-counts-or-regions \
    -show-instantiations 

О более удобном формате отображения можно почитать подробнее в гайдах по работе
с утилитой llvm-cov
