# Общее описание

Этот пример показывает фаззинг dll библиотек, написанных на C#.

# Создание проекта - обертки

В системе должен быть установлен пакет SDK и среда выполнения ASP.NET Core. 
Для фаззинга dll библиотеки необходимо создать проект-обертку.

1. В корень проекта положите библиотеку, которую хотите пофазззить.

2. Ее необходимо проинструментировать. Для
Если фаззинг происходит через stdin, то файл Program.cs выглядит так:

```shell
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
			Fuzzer.OutOfProcess.Run(stream =>
			{
				try
				{
					new HtmlParser().Parse(stream);	
				}
				catch (InvalidOperationException) { }
			});
		}
	}
}

```

А если через файл, то так:

```shell
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
			Fuzzer.OutOfProcess.Run(stream =>
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



В системе должна быть установлена JAVA 8 версии. Если Ваш проект не принимает на вход файл, то необходимо написать driver, 
на вход которому передается файл с данными, а он в свою очередь запускает JAVA приложение, которое Вы хотите фаззить.

В данном примере 2 проекта-обертки (фаззинг через файл и через stdin) находятся в директории `target`.
# Фаззинг

Находясь в данной директории, запустите скрипт `./fuzz.sh`;
он принимает два аргумента - путь до `fuzz_manager` и до `dotnet`, установленного в Вашей системе.

Запустите в другом терминале `UI` фаззера (укажите актуальные пути):
```shell
/path/to/crusher/bin_x86-64/ui --outdir /path/to/out
```

Как только будут найдены аварийные завершения, значение поля `unique_crashes` (в окне `UI` - наверху справа) станет ненулевым.

Прервать фаззинг (в первом терминале, `Ctrl + С`)
