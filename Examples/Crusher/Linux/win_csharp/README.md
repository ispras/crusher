# Общее описание

Этот пример показывает фаззинг dll библиотек, написанных на C#.

# Создание проекта - обертки
1. В корень проекта ExampleWrapperProject положите библиотеку, которую Вы хотите пофазззить.
   В файле ExampleWrapperProject.csproj пропишите соответствующую зависимость. В примере это `AngleSharp.dll`

2. В файле `Program.cs`, в качестве аргумента функции `Run` передайте лямбда-функцию (см. пример ниже),
   в которой Вы вызываете функцию из тестируемой библиотеки (в примере - функция `Parse()` библиотеки  `AngleSharp`).

3. В директории `win_csharp/target/AngleSharp.Fuzz.File` лежат 3 dll библиотеки: SharpFuzz.dll, SharpFuzz.CommandLine.dll,
   SharpFuzz.Common.dll. Они были добавлены в Ваш проект-обертку в качестве зависимостей, были прописаны соотвествующие
   строки в файле `ExampleWrapperProject.csproj` (см. пример ниже). Здесь находится функция для запуска Вашей библиотеки (проекта-обертки) 
   и собирается проект-обертка как dll файл.

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

Пример файла `ExampleWrapperProject.csproj`:

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

3. Произведите инструментацию библиотеки для фаззинга. Соберите проект-обертку. Для этого 
запустите скрипт `instrument.bat`, который принимает один аргумент - путь до `dotnet`.

В данном примере проект-обертка (фаззинг через файл) находится в директории `target`.
# Фаззинг

Находясь в данной директории, запустите скрипт `./fuzz-stdin.sh` для фаззинга библиотеки через **stdin** и `./fuzz-file.sh` для фаззинга через **файл**;
они принимают два аргумента - путь до `fuzz_manager` и до `dotnet`, установленного в Вашей системе.

Запустите в другом терминале `UI` фаззера (укажите актуальные пути):
```shell
/path/to/crusher/bin_x86-64/ui --outdir /path/to/out
```

Как только будут найдены аварийные завершения, значение поля `unique_crashes` (в окне `UI` - наверху справа) станет ненулевым.

Прервать фаззинг (в первом терминале, `Ctrl + С`)