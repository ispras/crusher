# Общее описание

Этот пример показывает фаззинг dll библиотек, написанных на C#.

# Создание проекта - обертки
1. В корень проекта положите библиотеку, которую Вы хотите пофазззить.
   В файле `*.csproj` пропишите соответствующую зависимость. В примере это `AngleSharp.dll`

2. В файле `Program.cs`, в качестве аргумента функции `Run` передайте лямбда-функцию (см. пример ниже), в которой Вы вызываете функцию из тестируемой библиотеки (в примере - функция `Parse()` библиотеки  `AngleSharp`).

3. В директории `win_csharp/target/AngleSharp.Fuzz.File` лежат 3 dll библиотеки: SharpFuzz.dll, SharpFuzz.CommandLine.dll, SharpFuzz.Common.dll. Их необходимо добавить в Ваш проект-обертку в качестве зависимостей, для этого прописать соотвествующие cтроки в файле `*.csproj` (см. пример ниже, здесь строки дописаны в файле `AngleSharp.Fuzz.File.csproj`). Там находится функция для запуска Вашей библиотеки (проекта-обертки) и собирается проект-обертка как dll файл.

Фаззинг происходит через **файл**, работаем с первым аргументом командной строки - `args[0]`. Ниже
приведен пример файла `Program.cs`:

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

Пример файла `AngleSharp.Fuzz.File.csproj`:

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

3. Произведите инструментацию библиотеки для фаззинга. Соберите проект-обертку. Для этого запустите скрипт `instrument.bat`, который принимает один аргумент - путь до `dotnet.exe`.

В данном примере проект-обертка (фаззинг через файл) находится в директории `target`.


# Фаззинг

Находясь в данной директории, запустите скрипт `fuzz.bat` для фаззинга библиотеки через **файл**; он принимаtт два аргумента - путь до `fuzz_manager.exe` и до `dotnet.exe`, установленного в Вашей системе.

Запустите в другом терминале `UI` фаззера (укажите актуальные пути):
```shell
/path/to/crusher/bin_x86-64/ui.exe --outdir /path/to/out
```

Как только будут найдены аварийные завершения, значение поля `unique_crashes` (в окне `UI` - наверху справа) станет ненулевым.

Прервать фаззинг (в первом терминале, `Ctrl + С`)
