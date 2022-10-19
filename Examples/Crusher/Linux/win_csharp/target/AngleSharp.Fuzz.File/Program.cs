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
					// new HtmlParser().Parse(stream);
					var html = File.ReadAllText(args[0]);
					new HtmlParser().Parse(html);
				}
				catch (InvalidOperationException) { }
			});
		}
	}
}
