# Общее описание

Этот пример показывает фаззинг dll библиотек, написанных на C#.

# Создание проекта - обертки
1. В корне проекта-обертки `target/AngleSharp.Fuzz.File` лежит библиотека `AngleSharp.dll`, которую хотим пофаззить. В файле `*.csproj` прописана соответствующая зависимость для ее видимости.

2. В файле `Program.cs` в качестве аргумента функции `Run` передается лямбда-функция (см. пример ниже), в которой вызывается функция `Parse()` из тестируемой библиотеки `AngleSharp`.

3. В директории `target/AngleSharp.Fuzz.File` лежат 3 dll библиотеки: SharpFuzz.dll, SharpFuzz.CommandLine.dll, SharpFuzz.Common.dll. Они также добавлены в проект `AngleSharp.Fuzz.File` в качестве зависимостей (необходимые строки прописаны в `AngleSharp.Fuzz.File.csproj`. В них находится функция для запуска нашего проекта-обертки `AngleSharp.Fuzz.File` и он собирается как dll файл.

Фаззинг происходит через **файл**, работаем с первым аргументом командной строки - `args[0]`. Ниже
показан файл `Program.cs`:

```c++
using System;
using AngleSharp.Parser.Html;
using AngleSharp;
using SharpFuzz;

namespace AngleSharp.Fuzz
{
	public class Program
	{
		public static void Main(string[] args)
		{
			Fuzzer.LibFuzzer.Run(stream =>
			{
				try
				{
					var html = File.ReadAllText(args[0]);
					new HtmlParser().Parse(html);
				}
				catch (InvalidOperationException) { }
			});
		}
	}
}

```

Файл `AngleSharp.Fuzz.File.csproj`:

```xml
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <OutputType>Exe</OutputType>
    <TargetFramework>net6.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
  </PropertyGroup>

  <ItemGroup>
    <Reference Include="AngleSharp">
      <HintPath>AngleSharp.dll</HintPath>
    </Reference>
  </ItemGroup>

  <ItemGroup>
    <Reference Include="SharpFuzz">
      <HintPath>SharpFuzz.dll</HintPath>
    </Reference>
  </ItemGroup>

    <ItemGroup>
    <Reference Include="SharpFuzz.CommandLine">
      <HintPath>SharpFuzz.CommandLine.dll</HintPath>
    </Reference>
  </ItemGroup>


    <ItemGroup>
    <Reference Include="SharpFuzz.Common">
      <HintPath>SharpFuzz.Common.dll</HintPath>
    </Reference>
  </ItemGroup>

</Project>
```

# Фаззинг

1. Произведите инструментацию библиотеки `AngleSharp.dll` для фаззинга. Соберите проект-обертку `target/AngleSharp.Fuzz.File`. Для этого запустите скрипт `instrument.bat`, который принимает один аргумент - путь до `dotnet.exe`.

2. Находясь в данной директории, запустите скрипт `fuzz.bat` для фаззинга библиотеки через **файл**; он принимает два аргумента - путь до `fuzz_manager.exe` и до `dotnet.exe`, установленного в Вашей системе.

3. Запустите в другом терминале `UI` фаззера (укажите актуальные пути):
```shell
/path/to/crusher/bin_x86-64/ui.exe --outdir /path/to/out
```

Как только будут найдены аварийные завершения, значение поля `unique_crashes` (в окне `UI` - наверху справа) станет ненулевым.

Прервать фаззинг (в первом терминале, `Ctrl + С`)
