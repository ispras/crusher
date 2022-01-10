**Сбор покрытия C# (.NET 5 Linux, Ubuntu 20)**

1. Устанавливаем .NET5  https://docs.microsoft.com/en-us/dotnet/core/install/linux-ubuntu#2004-

2. Устанавливаем сборщик покрытия https://github.com/lucaslorentz/minicover (я ставил как глобальный инструмент `dotnet tool install --global minicover` ) 

3. Делаем тестовый проект `dotnet new console`  (в качестве текста Project.cs я взял простейший калькулятор https://docs.microsoft.com/en-us/visualstudio/get-started/csharp/tutorial-console?view=vs-2019#add-code-to-create-a-calculator)

4. Собираем проект `dotnet build`

5. Инструментируем проект (опции подробно расписаны в описании инструментатора, путь к исходникам по умолчанию ведет в ./src, так что указываем принудительно) `minicover instrument --sources **/*.cs` или `minicover instrument --sources Program.cs`

6. **Самое главное - запускаем программу с no-build**, иначе сборка перезатрется run\`om - `dotnet run no-build`

7. Покрытие собрано, `minicover report` даст простой отчет, `minicover htmlreport` даст красивый отчет, есть и другие варианты отчетов - см. документацию minicover

8. Если запустить тестовый калькулятор с разными командами (ну или подать наши сэмплы от фаззера в программу в цикле), мы в итоге получим кумулятивный отчет (до тех пор пока не выполним `minicover reset`)
